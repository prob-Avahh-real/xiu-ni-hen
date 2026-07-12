import SwiftUI

/// Minimal odor logging panel — just type, intensity, room, done.
/// Pre-fills from voice intent when available.
struct MinimalLogOdorView: View {
    @ObservedObject var vm: OdorViewModel
    @Environment(\.dismiss) private var dismiss
    let preselectedType: OdorType?
    let preselectedRoomName: String?
    var isEmergency: Bool = false

    @State private var selectedType: OdorType = .unknown
    @State private var intensity: Int = 3
    @State private var roomId: UUID?
    @State private var markEmergency: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("取消") { dismiss() }
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                Spacer()
                Text("记录气味")
                    .font(DesignTokens.Typography.h2)
                Spacer()
                Button {
                    guard let rid = roomId else { return }
                    vm.logOdor(
                        type: selectedType,
                        intensity: intensity,
                        roomId: rid,
                        notes: nil,
                        isEmergency: markEmergency || selectedType.dangerLevel >= 4
                    )
                    dismiss()
                } label: {
                    Text("保存")
                        .font(DesignTokens.Typography.body.weight(.semibold))
                        .foregroundStyle(roomId != nil ? DesignTokens.Colors.accent : DesignTokens.Colors.textSecondary.opacity(0.3))
                }
                .disabled(roomId == nil)
            }
            .padding(.horizontal, DesignTokens.Spacing.marginH)
            .padding(.vertical, DesignTokens.Spacing.padding)

            MinimalSeparator()

            // Type selector — horizontal scroll, single-select
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
                Text("气味类型")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .padding(.horizontal, DesignTokens.Spacing.marginH)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(OdorType.allCases, id: \.self) { type in
                            Button {
                                selectedType = type
                            } label: {
                                Text(type.rawValue)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundStyle(selectedType == type ? .white : DesignTokens.Colors.text)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedType == type
                                        ? DesignTokens.Colors.accent
                                        : Color.clear
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.pill)
                                            .stroke(selectedType == type ? Color.clear : DesignTokens.Colors.separator, lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.marginH)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.block)

            MinimalSeparator()

            // Intensity
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
                Text("强度")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                HStack(spacing: 20) {
                    Text("轻微")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(width: 40, alignment: .leading)

                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { i in
                            Circle()
                                .fill(i <= intensity ? DesignTokens.Colors.accent : DesignTokens.Colors.separator)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text("\(i)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(i <= intensity ? .white : DesignTokens.Colors.textSecondary)
                                )
                                .onTapGesture { intensity = i }
                        }
                    }

                    Text("严重")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.marginH)
            .padding(.vertical, DesignTokens.Spacing.block)

            MinimalSeparator()

            // Room picker
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
                Text("房间")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .padding(.horizontal, DesignTokens.Spacing.marginH)

                VStack(spacing: 0) {
                    ForEach(vm.allRooms()) { room in
                        Button {
                            roomId = room.id
                        } label: {
                            HStack {
                                Image(systemName: room.icon)
                                    .font(.system(size: DesignTokens.IconSize.status))
                                    .foregroundStyle(roomId == room.id ? DesignTokens.Colors.accent : DesignTokens.Colors.textSecondary)
                                Text(room.name)
                                    .font(DesignTokens.Typography.body)
                                    .foregroundStyle(DesignTokens.Colors.text)
                                Spacer()
                                if roomId == room.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.marginH)
                            .padding(.vertical, 12)
                            .background(roomId == room.id ? DesignTokens.Colors.accent.opacity(0.06) : Color.clear)
                        }
                        .buttonStyle(.plain)
                        if room.id != vm.allRooms().last?.id {
                            MinimalSeparator()
                                .padding(.leading, DesignTokens.Spacing.marginH + 24)
                        }
                    }
                }
            }
            .padding(.vertical, DesignTokens.Spacing.block)

            if isEmergency || selectedType.dangerLevel >= 4 {
                Toggle("标记为紧急", isOn: $markEmergency)
                    .font(DesignTokens.Typography.body)
                    .tint(DesignTokens.Colors.alert)
                    .padding(.horizontal, DesignTokens.Spacing.marginH)
                    .padding(.bottom, DesignTokens.Spacing.block)
            }

            Spacer()
        }
        .background(DesignTokens.Colors.background)
        #if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        #endif
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 520)
        #endif
        .onAppear {
            if let type = preselectedType { selectedType = type }
            markEmergency = isEmergency
            if let name = preselectedRoomName,
               let room = vm.allRooms().first(where: { $0.name == name }) {
                roomId = room.id
            } else {
                roomId = vm.allRooms().first?.id
            }
        }
    }
}
