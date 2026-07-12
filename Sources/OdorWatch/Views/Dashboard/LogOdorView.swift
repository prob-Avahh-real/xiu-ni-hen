import SwiftUI

struct LogOdorView: View {
    @ObservedObject var vm: OdorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: OdorType = .unknown
    @State private var intensity: Double = 3
    @State private var roomId: UUID?
    @State private var notes = ""
    @State private var isEmergency = false

    var body: some View {
        NavigationStack {
            Form {
                Section("气味类型") {
                    Picker("类型", selection: $selectedType) {
                        ForEach(OdorType.allCases, id: \.self) { t in
                            Text("\(t.icon) \(t.rawValue)").tag(t)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.wheel)
                    .frame(height: 140)
                    #endif

                    HStack { Text("强度"); Spacer()
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= Int(intensity) ? "circlebadge.fill" : "circlebadge")
                                    .font(.title3).foregroundStyle(selectedType.color)
                                    .onTapGesture { intensity = Double(i) }
                            }
                        }
                    }
                }

                Section("位置") {
                    Picker("房间", selection: $roomId) {
                        Text("请选择").tag(nil as UUID?)
                        ForEach(vm.allRooms()) { r in
                            Label(r.name, systemImage: r.icon).tag(r.id as UUID?)
                        }
                    }
                }

                Section {
                    Toggle("标记为紧急", isOn: $isEmergency).tint(.red)
                    TextField("备注（可选）", text: $notes)
                }
            }
            .navigationTitle("记录气味")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("记录") {
                        guard let rid = roomId else { return }
                        vm.logOdor(
                            type: selectedType,
                            intensity: Int(intensity),
                            roomId: rid,
                            notes: notes.isEmpty ? nil : notes,
                            isEmergency: isEmergency
                        )
                        dismiss()
                    }
                    .disabled(roomId == nil).fontWeight(.semibold)
                }
            }
            .onAppear { roomId = vm.allRooms().first?.id }
        }
    }
}
