import SwiftUI

struct DashboardView: View {
    @ObservedObject var vm: OdorViewModel
    @State private var showLogSheet = false

    var body: some View {
        ZStack {
            Color.groupedBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    statusCard
                    quickLogSection
                    roomStatusSection
                    recentSection
                }
                .padding(16)
            }
        }
        .navigationTitle("嗅你行")
        .toolbar {
            ToolbarItem(placement: PlatformToolbar.trailing) {
                if vm.emergencyCount > 0 {
                    Label("\(vm.emergencyCount)", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .sheet(isPresented: $showLogSheet) {
            LogOdorView(vm: vm)
        }
    }

    private var statusCard: some View {
        let unresolved = vm.unresolvedCount
        let emergency = vm.emergencyCount

        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(emergency > 0 ? "⚠️ 需要关注" : unresolved > 0 ? "🔍 有待处理" : "✅ 一切正常")
                        .font(.title2).fontWeight(.bold)
                    Text(emergency > 0
                         ? "\(emergency) 个紧急气味事件未处理"
                         : "室内空气状态良好，无异味告警")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(emergency > 0 ? Color.red.opacity(0.15) : Color.teal.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: emergency > 0 ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                        .font(.title).foregroundStyle(emergency > 0 ? .red : .teal)
                }
            }

            if unresolved > 0 {
                Button { showLogSheet = true } label: {
                    Label("记录新气味", systemImage: "plus.circle.fill")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(.teal).clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(20)
        .background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速标记").font(.headline)
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 10) {
                ForEach(OdorType.allCases.filter { $0.dangerLevel >= 3 }, id: \.self) { type in
                    Button { showLogSheet = true } label: {
                        VStack(spacing: 6) {
                            Text(type.icon).font(.title2)
                            Text(type.rawValue).font(.caption2).foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(type.color.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var roomStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("各房间状态").font(.headline)
            ForEach(vm.allRooms()) { room in
                let roomEvents = vm.eventsForRoom(room.id).filter { $0.resolvedAt == nil }
                HStack {
                    Image(systemName: room.icon).foregroundStyle(.teal).frame(width: 24)
                    Text(room.name).font(.subheadline)
                    Spacer()
                    if roomEvents.isEmpty {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                    } else {
                        let hasEmergency = roomEvents.contains { $0.isEmergency }
                        Text("\(roomEvents.count) 事件")
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(hasEmergency ? Color.red.opacity(0.15) : Color.orange.opacity(0.15))
                            .foregroundStyle(hasEmergency ? .red : .orange)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("最近记录").font(.headline)
            let recent = vm.recentEvents(limit: 8)
            if recent.isEmpty {
                Text("还没有记录，点击上方按钮开始").font(.caption).foregroundStyle(.secondary).padding()
            } else {
                ForEach(recent) { event in
                    EventRow(event: event, roomName: vm.roomName(for: event.roomId))
                }
            }
        }
        .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
