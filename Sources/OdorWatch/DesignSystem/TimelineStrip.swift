import SwiftUI

/// Minimal timeline strip — shows the 3 most recent events as dots on a line.
/// Horizontal, compact, information on demand.
struct TimelineStrip: View {
    let events: [OdorEvent]
    let roomNameFor: (UUID) -> String
    let onTapEvent: (OdorEvent) -> Void
    let onTapViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
            HStack {
                Text("最近记录")
                    .font(DesignTokens.Typography.h2)
                Spacer()
                if events.count > 3 || !events.isEmpty {
                    Button("全部") { onTapViewAll() }
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
            }

            if events.isEmpty {
                Text("暂无记录")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(events.prefix(3)) { event in
                        TimelineRow(
                            event: event,
                            roomName: roomNameFor(event.roomId),
                            onTap: { onTapEvent(event) }
                        )
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.padding)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.standard)
                .fill(DesignTokens.Colors.background)
        )
    }
}

// MARK: - Timeline Row

struct TimelineRow: View {
    let event: OdorEvent
    let roomName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Dot on the line
                Circle()
                    .fill(event.isEmergency ? DesignTokens.Colors.alert : DesignTokens.Colors.accent.opacity(0.4))
                    .frame(width: 8, height: 8)

                // Event info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(event.type.rawValue)
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.text)
                        if event.isEmergency {
                            Text("紧急")
                                .font(DesignTokens.Typography.micro)
                                .foregroundStyle(DesignTokens.Colors.alert)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignTokens.Colors.alert.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(roomName) · \(formatRelativeTime(event.detectedAt))")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                Spacer()

                // Resolution status
                if event.resolvedAt != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: DesignTokens.IconSize.status))
                        .foregroundStyle(.green)
                } else {
                    // Intensity dots
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Circle()
                                .fill(i <= event.intensity ? DesignTokens.Colors.accent : DesignTokens.Colors.separator)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            MinimalSeparator()
        }
    }
}

private func formatRelativeTime(_ date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    switch interval {
    case ..<60:     return "刚刚"
    case ..<3600:   return "\(Int(interval/60))分钟前"
    case ..<86400:  return "\(Int(interval/3600))小时前"
    default:
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_CN")
        fmt.dateFormat = interval < 7*86400 ? "EEEE" : "M/d"
        return fmt.string(from: date)
    }
}
