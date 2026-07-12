import SwiftUI

/// Minimal settings panel — rooms and alert rules only.
/// No all-in-one list, no colored icons, no clutter.
struct MinimalSettingsView: View {
    @ObservedObject var vm: OdorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newRoomName = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text("设置")
                    .font(DesignTokens.Typography.h2)
                Spacer()
                Button {
                    vm.savePreferences()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.textSecondary.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.marginH)
            .padding(.vertical, DesignTokens.Spacing.padding)

            MinimalSeparator()

            ScrollView {
                VStack(spacing: DesignTokens.Spacing.section) {
                    // Rooms
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
                        Text("房间")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .padding(.horizontal, DesignTokens.Spacing.marginH)

                        VStack(spacing: 0) {
                            ForEach($vm.preferences.rooms) { $room in
                                HStack {
                                    Image(systemName: room.icon)
                                        .font(.system(size: DesignTokens.IconSize.status))
                                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                                    TextField("", text: $room.name)
                                        .font(DesignTokens.Typography.body)
                                    Spacer()
                                }
                                .padding(.horizontal, DesignTokens.Spacing.marginH)
                                .padding(.vertical, 12)

                                if room.id != vm.preferences.rooms.last?.id {
                                    MinimalSeparator()
                                        .padding(.leading, DesignTokens.Spacing.marginH + 24)
                                }
                            }
                            .onDelete { vm.preferences.rooms.remove(atOffsets: $0) }

                            // Add room
                            HStack {
                                Image(systemName: "plus")
                                    .font(.system(size: DesignTokens.IconSize.status))
                                    .foregroundStyle(DesignTokens.Colors.accent)
                                TextField("添加房间", text: $newRoomName)
                                    .font(DesignTokens.Typography.body)
                                    .onSubmit {
                                        guard !newRoomName.isEmpty else { return }
                                        vm.preferences.rooms.append(
                                            Room(name: newRoomName, icon: "house.fill", floor: 0)
                                        )
                                        newRoomName = ""
                                    }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.marginH)
                            .padding(.vertical, 12)
                        }
                    }

                    MinimalSeparator()
                        .padding(.horizontal, DesignTokens.Spacing.marginH)

                    // Alert rules
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
                        Text("告警规则")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .padding(.horizontal, DesignTokens.Spacing.marginH)

                        VStack(spacing: 0) {
                            ForEach($vm.preferences.alertRules) { $rule in
                                VStack(alignment: .leading, spacing: 4) {
                                    Toggle(isOn: $rule.isEnabled) {
                                        Text(rule.name)
                                            .font(DesignTokens.Typography.body)
                                    }
                                    .tint(DesignTokens.Colors.accent)
                                    Text("气味: \(rule.odorTypes.map(\.rawValue).joined(separator: "、")) · 最低强度 \(rule.minIntensity)/5")
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                                }
                                .padding(.horizontal, DesignTokens.Spacing.marginH)
                                .padding(.vertical, 12)

                                if rule.id != vm.preferences.alertRules.last?.id {
                                    MinimalSeparator()
                                        .padding(.leading, DesignTokens.Spacing.marginH)
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .background(DesignTokens.Colors.background)
        .onDisappear { vm.savePreferences() }
    }
}
