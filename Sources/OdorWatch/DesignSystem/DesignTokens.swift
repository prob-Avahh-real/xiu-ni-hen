import SwiftUI

enum DesignTokens {
    enum Colors {
        static let text = Color.primary
        static let textSecondary = Color.secondary
        static let accent = Color.primary.opacity(0.85)
        static let alert = Color.red
        static let separator = Color.primary.opacity(0.08)

        static var background: Color {
            #if os(iOS)
            Color(uiColor: .systemBackground)
            #else
            Color(nsColor: .windowBackgroundColor)
            #endif
        }

        static var surface: Color {
            #if os(iOS)
            Color(uiColor: .secondarySystemBackground)
            #else
            Color(nsColor: .controlBackgroundColor)
            #endif
        }
    }

    enum Typography {
        static let hero: Font = .system(size: 34, weight: .light)
        static let h1: Font = .system(size: 28, weight: .regular)
        static let h2: Font = .system(size: 17, weight: .medium)
        static let body: Font = .system(size: 16, weight: .regular)
        static let caption: Font = .system(size: 13, weight: .regular)
        static let micro: Font = .system(size: 11, weight: .regular)
    }

    enum Spacing {
        static let section: CGFloat = 40
        static let block: CGFloat = 28
        static let padding: CGFloat = 20
        static let marginH: CGFloat = 28
        static let marginTop: CGFloat = 20
        static let tight: CGFloat = 8
    }

    enum IconSize {
        static let action: CGFloat = 18
        static let status: CGFloat = 14
    }

    enum Radius {
        static let standard: CGFloat = 2
        static let pill: CGFloat = 999
    }
}

struct MinimalSeparator: View {
    var body: some View {
        Rectangle()
            .fill(DesignTokens.Colors.separator)
            .frame(height: 0.5)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let isAlert: Bool

    init(isAlert: Bool = false) {
        self.isAlert = isAlert
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(isAlert ? DesignTokens.Colors.alert : DesignTokens.Colors.accent)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.standard))
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(DesignTokens.Colors.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.standard)
                    .stroke(DesignTokens.Colors.separator, lineWidth: 0.5)
            )
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
