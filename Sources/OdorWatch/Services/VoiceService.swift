import Foundation
import Speech
import AVFoundation

enum VoiceIntent: Equatable {
    case logOdor(type: OdorType?, room: String?)
    case switchRoom(name: String)
    case recentIssues
    case guidance(type: OdorType?)
    case openSettings
    case emergency
    case unknown(String)

    static func == (lhs: VoiceIntent, rhs: VoiceIntent) -> Bool {
        switch (lhs, rhs) {
        case (.logOdor(let a, let b), .logOdor(let c, let d)): return a == c && b == d
        case (.switchRoom(let a), .switchRoom(let b)): return a == b
        case (.recentIssues, .recentIssues): return true
        case (.guidance(let a), .guidance(let b)): return a == b
        case (.openSettings, .openSettings): return true
        case (.emergency, .emergency): return true
        case (.unknown(let a), .unknown(let b)): return a == b
        default: return false
        }
    }

    var spokenConfirmation: String {
        switch self {
        case .emergency:
            return "紧急情况，慢慢说"
        case .logOdor(let type, let room):
            if let type, let room { return "好，\(room)的\(type.rawValue)记下了" }
            if let room { return "好，记一下\(room)" }
            if let type { return "好，记一下\(type.rawValue)" }
            return "说说闻到了什么"
        case .switchRoom(let name):
            return "切到\(name)了"
        case .recentIssues:
            return "帮你打开历史"
        case .guidance(let type):
            return type.map { "看看\($0.rawValue)怎么办" } ?? "说说哪种气味"
        case .openSettings:
            return "好，去设置"
        case .unknown:
            return "没听清，再说一次"
        }
    }
}

@MainActor
final class VoiceService: ObservableObject {
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var isSpeaking = false
    @Published var transcript = ""
    @Published var errorMessage: String?
    @Published var hintIndex = 0

    var knownRoomNames: [String] = []
    var onIntent: ((VoiceIntent) -> Void)?

    static let hints = [
        "说说你闻到了什么",
        "想查哪个房间，直接说",
        "问问最近怎么样",
        "拿不准就喊「怎么办」",
    ]

    private let recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    func startListening() {
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "语音识别不可用"
            return
        }

        stopListening()
        transcript = ""
        isListening = true
        isProcessing = false

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        #endif

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "无法启动麦克风"
            isListening = false
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.errorMessage = error.localizedDescription
                    self.stopListening()
                    return
                }
                guard let result else { return }
                self.transcript = result.bestTranscription.formattedString

                if result.isFinal {
                    self.stopListening()
                    self.dispatchIntent(from: result.bestTranscription.formattedString)
                }
            }
        }
    }

    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.48
        utterance.preUtteranceDelay = 0.05
        isSpeaking = true
        synthesizer.speak(utterance)

        Task {
            try? await Task.sleep(nanoseconds: UInt64(max(1.2, Double(text.count) * 0.08)) * 1_000_000_000)
            isSpeaking = false
        }
    }

    func rotateHint() {
        hintIndex = (hintIndex + 1) % Self.hints.count
    }

    private func dispatchIntent(from text: String) {
        isProcessing = true
        let intent = parseIntent(text)
        isProcessing = false
        speak(intent.spokenConfirmation)
        onIntent?(intent)
    }

    private func parseIntent(_ text: String) -> VoiceIntent {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let rooms = knownRoomNames + ["客厅", "厨房", "卧室", "卫生间", "阳台", "书房", "地下室"]

        if t.contains("紧急") || t.contains("着火了") || t.contains("救命") || t.contains("火灾") {
            return .emergency
        }

        if t.contains("记录") || t.contains("闻到") || t.contains("有味") || t.contains("臭") ||
            t.contains("气味") || t.contains("味道") {
            return .logOdor(type: matchOdor(in: t), room: matchRoom(in: t, candidates: rooms))
        }

        if t.contains("看看") || t.contains("切换") || t.contains("去") {
            if let room = matchRoom(in: t, candidates: rooms) {
                return .switchRoom(name: room)
            }
        }

        if t.contains("最近") || t.contains("有什么") || t.contains("怎么样") || t.contains("历史") {
            return .recentIssues
        }

        if t.contains("怎么办") || t.contains("指引") || t.contains("排查") || t.contains("怎么处理") {
            return .guidance(type: matchOdor(in: t))
        }

        if t.contains("设置") || t.contains("添加") || t.contains("配置") {
            return .openSettings
        }

        return .unknown(text)
    }

    private func matchOdor(in text: String) -> OdorType? {
        OdorType.allCases.first { text.contains($0.rawValue) }
    }

    private func matchRoom(in text: String, candidates: [String]) -> String? {
        candidates.first { text.contains($0) }
    }
}
