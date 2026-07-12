import SwiftUI

struct VoiceButton: View {
    enum Mode {
        case idle
        case listening
        case processing
        case speaking
    }

    let mode: Mode
    let action: () -> Void

    @State private var animatePulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if mode == .listening {
                    Circle()
                        .stroke(DesignTokens.Colors.text.opacity(0.12), lineWidth: 1)
                        .frame(width: 84, height: 84)
                        .scaleEffect(animatePulse ? 1.12 : 1.0)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: animatePulse)
                }

                Circle()
                    .fill(mode == .listening ? DesignTokens.Colors.text : DesignTokens.Colors.background)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(DesignTokens.Colors.separator, lineWidth: 0.5)
                    )

                Group {
                    switch mode {
                    case .idle:
                        Image(systemName: "mic")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    case .listening:
                        Image(systemName: "waveform")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(DesignTokens.Colors.background)
                    case .processing:
                        ProgressView()
                            .scaleEffect(0.9)
                    case .speaking:
                        Image(systemName: "speaker.wave.1")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear { animatePulse = true }
    }
}
