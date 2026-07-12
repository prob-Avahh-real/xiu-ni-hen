import SwiftUI

struct TimelineView: View {
    @ObservedObject var vm: OdorViewModel
    @State private var filterRoom: UUID?

    var body: some View {
        List {
            ForEach(filteredEvents) { event in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        EventRow(event: event, roomName: vm.roomName(for: event.roomId))
                        Spacer()
                        if event.resolvedAt == nil {
                            Button("已处理") { vm.resolveEvent(event.id) }
                                .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.teal.opacity(0.1)).clipShape(Capsule())
                        }
                    }
                    if let notes = event.notes { Text(notes).font(.caption).foregroundStyle(.secondary) }
                    if let resolved = event.resolvedAt {
                        Text("已处理: \(resolved.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2).foregroundStyle(.green)
                    }
                }
            }
            .onDelete { idx in
                for i in idx { vm.deleteEvent(filteredEvents[i].id) }
            }
        }
        .navigationTitle("气味历史")
        .toolbar {
            ToolbarItem(placement: PlatformToolbar.trailing) {
                Picker("房间", selection: $filterRoom) {
                    Text("全部").tag(nil as UUID?)
                    ForEach(vm.allRooms()) { r in Text(r.name).tag(r.id as UUID?) }
                }
            }
        }
    }

    private var filteredEvents: [OdorEvent] {
        guard let rid = filterRoom else { return vm.events }
        return vm.events.filter { $0.roomId == rid }
    }
}
