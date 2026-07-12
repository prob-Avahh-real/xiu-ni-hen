import Foundation

protocol VoiceServiceProtocol: AnyObject {
    var isListening: Bool { get }
    var transcript: String { get }
    var onIntent: ((VoiceIntent) -> Void)? { get set }

    func requestAuthorization() async -> Bool
    func startListening()
    func stopListening()
}
