import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: OdorViewModel
    @State private var newRoomName = ""

    var body: some View {
        List {
            Section("我的房间") {
                ForEach($vm.preferences.rooms) { $room in
                    HStack {
                        Image(systemName: room.icon).foregroundStyle(.teal)
                        TextField("房间名", text: $room.name)
                    }
                }
                .onDelete { vm.preferences.rooms.remove(atOffsets: $0); vm.savePreferences() }
                HStack {
                    Image(systemName: "plus.circle.fill").foregroundStyle(.teal)
                    TextField("添加房间", text: $newRoomName)
                        .onSubmit {
                            guard !newRoomName.isEmpty else { return }
                            vm.preferences.rooms.append(Room(name: newRoomName, icon: "house.fill", floor: 0))
                            newRoomName = ""
                            vm.savePreferences()
                        }
                }
            }

            Section("告警规则") {
                ForEach($vm.preferences.alertRules) { $rule in
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(rule.name, isOn: $rule.isEnabled).tint(.teal)
                        Text("气味: \(rule.odorTypes.map(\.rawValue).joined(separator: "、")) · 最低强度 \(rule.minIntensity)/5")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section("紧急联系人") {
                ForEach($vm.preferences.emergencyContacts, id: \.self) { $contact in
                    TextField("联系人电话", text: $contact)
                }
                Button("添加联系人") {
                    vm.preferences.emergencyContacts.append("")
                }
            }
        }
        .navigationTitle("设置")
        .onDisappear { vm.savePreferences() }
    }
}
