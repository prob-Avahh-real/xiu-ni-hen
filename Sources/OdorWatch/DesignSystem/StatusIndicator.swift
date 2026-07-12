import SwiftUI

struct StatusIndicator: View {
    enum State {
        case good
        case attention
        case emergency

        var color: Color {
            switch self {
            case .good: return DesignTokens.Colors.textSecondary
            case .attention: return DesignTokens.Colors.text
            case .emergency: return DesignTokens.Colors.alert
            }
        }

        var icon: String {
            switch self {
            case .good: return "circle"
            case .attention: return "circle.dotted"
            case .emergency: return "circle.fill"
            }
        }
    }

    let state: State
    let label: String
    let detail: String?

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.tight) {
            Image(systemName: state.icon)
                .font(.system(size: DesignTokens.IconSize.action, weight: .light))
                .foregroundStyle(state.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignTokens.Typography.h2)
                    .foregroundStyle(DesignTokens.Colors.text)
                if let detail {
                    Text(detail)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
        }
    }
}
