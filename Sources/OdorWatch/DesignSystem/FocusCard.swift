import SwiftUI

struct FocusCard: View {
    let room: Room
    let status: StatusIndicator.State
    let unresolvedCount: Int
    let emergencyCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.block) {
                Text(room.name)
                    .font(DesignTokens.Typography.hero)
                    .foregroundStyle(DesignTokens.Colors.text)

                StatusIndicator(
                    state: status,
                    label: statusText,
                    detail: statusDetail
                )

                if emergencyCount > 0 {
                    Text("\(emergencyCount) 紧急")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.alert)
                } else if unresolvedCount > 0 {
                    Text("\(unresolvedCount) 待处理")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.padding)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.standard)
                    .fill(DesignTokens.Colors.surface.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.standard)
                    .stroke(DesignTokens.Colors.separator, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var statusText: String {
        switch status {
        case .good: return "正常"
        case .attention: return "留意"
        case .emergency: return "紧急"
        }
    }

    private var statusDetail: String? {
        switch status {
        case .good: return nil
        case .attention: return "有未处理记录"
        case .emergency: return "请立即排查"
        }
    }
}
