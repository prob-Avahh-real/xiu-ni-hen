import SwiftUI

/// Single-focus home — one room at a time, voice-first, features revealed on demand.
struct HomeView: View {
    @ObservedObject var vm: OdorViewModel
    @StateObject private var voice = VoiceService()

    @State private var showLogOdor = false
    @State private var showGuidance = false
    @State private var showSettings = false
    @State private var showTimeline = false
    @State private var showExplore = false
    @State private var selectedTimelineEvent: OdorEvent?
    @State private var guidanceType: OdorType?
    @State private var currentRoomIndex = 0
    @State private var preselectedOdorType: OdorType?
    @State private var preselectedRoom: String?
    @State private var logAsEmergency = false

    private var currentRoom: Room? {
        let rooms = vm.allRooms()
        guard !rooms.isEmpty else { return nil }
        return rooms[min(currentRoomIndex, rooms.count - 1)]
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()

                if let room = currentRoom {
                    roomFocus(room)
                } else {
                    emptyRoomsState
                }

                Spacer()

                voiceSection
                exploreAffordance
            }
        }
        .sheet(isPresented: $showLogOdor) {
            MinimalLogOdorView(
                vm: vm,
                preselectedType: preselectedOdorType,
                preselectedRoomName: preselectedRoom,
                isEmergency: logAsEmergency
            )
        }
        .sheet(isPresented: $showGuidance) {
            MinimalGuidanceView(highlightedType: guidanceType)
        }
        .sheet(isPresented: $showSettings) {
            MinimalSettingsView(vm: vm)
        }
        .sheet(isPresented: $showTimeline) {
            MinimalTimelineView(vm: vm, highlightedEvent: selectedTimelineEvent)
        }
        .sheet(isPresented: $showExplore) {
            ExploreSheet(
                emergencyCount: vm.emergencyCount,
                onHistory: { showTimeline = true },
                onGuidance: { showGuidance = true },
                onSettings: { showSettings = true },
                onLog: { showLogOdor = true }
            )
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            voice.knownRoomNames = vm.allRooms().map(\.name)
            voice.onIntent = handleVoiceIntent
        }
        .onChange(of: vm.preferences.rooms.count) { _, _ in
            voice.knownRoomNames = vm.allRooms().map(\.name)
        }
        .onReceive(Timer.publish(every: 6, on: .main, in: .common).autoconnect()) { _ in
            guard !voice.isListening, !voice.isSpeaking else { return }
            voice.rotateHint()
        }
    }

    // MARK: - Sections

    private var topBar: some View {
        HStack {
            Text(formatDate(Date()))
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            Spacer()
            if vm.emergencyCount > 0 {
                Text("\(vm.emergencyCount) 紧急")
                    .font(DesignTokens.Typography.micro)
                    .foregroundStyle(DesignTokens.Colors.alert)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.marginH)
        .padding(.top, DesignTokens.Spacing.marginTop)
    }

    private func roomFocus(_ room: Room) -> some View {
        let unresolved = vm.eventsForRoom(room.id).filter { $0.resolvedAt == nil }.count
        let emergency = vm.eventsForRoom(room.id).filter { $0.isEmergency && $0.resolvedAt == nil }.count
        let status: StatusIndicator.State = emergency > 0 ? .emergency : unresolved > 0 ? .attention : .good

        return VStack(spacing: DesignTokens.Spacing.block) {
            FocusCardPager(
                rooms: vm.allRooms(),
                currentIndex: $currentRoomIndex,
                onRoomTap: { tapped in
                    vm.selectedRoomId = tapped.id
                    showTimeline = true
                },
                unresolvedFor: { vm.eventsForRoom($0.id).filter { $0.resolvedAt == nil }.count },
                emergencyFor: { vm.eventsForRoom($0.id).filter { $0.isEmergency && $0.resolvedAt == nil }.count }
            )
            .frame(height: 180)

            Text(roomHint(status: status, room: room, unresolved: unresolved))
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.marginH)
                .animation(.easeInOut(duration: 0.25), value: currentRoomIndex)
        }
    }

    private var emptyRoomsState: some View {
        VStack(spacing: DesignTokens.Spacing.tight) {
            Text("还没有房间")
                .font(DesignTokens.Typography.h1)
            Text("说「去设置」，或点探索添加")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    private var voiceSection: some View {
        VStack(spacing: DesignTokens.Spacing.tight) {
            if voice.isListening || voice.isProcessing || voice.isSpeaking {
                Text(voiceStatusText)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .contentTransition(.opacity)
            } else {
                Text(VoiceService.hints[voice.hintIndex])
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary.opacity(0.7))
                    .contentTransition(.opacity)
            }

            VoiceButton(mode: voiceMode) {
                handleVoiceTap()
            }
            .padding(.top, DesignTokens.Spacing.tight)

            if let error = voice.errorMessage {
                Text(error)
                    .font(DesignTokens.Typography.micro)
                    .foregroundStyle(DesignTokens.Colors.alert)
            }
        }
        .padding(.bottom, DesignTokens.Spacing.block)
    }

    private var exploreAffordance: some View {
        Button {
            showExplore = true
        } label: {
            HStack(spacing: 6) {
                Text("探索")
                    .font(DesignTokens.Typography.micro)
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(DesignTokens.Colors.textSecondary.opacity(0.5))
            .padding(.bottom, 24)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Voice

    private var voiceMode: VoiceButton.Mode {
        if voice.isSpeaking { return .speaking }
        if voice.isProcessing { return .processing }
        if voice.isListening { return .listening }
        return .idle
    }

    private var voiceStatusText: String {
        if voice.isSpeaking { return "…" }
        if voice.isProcessing { return "理解中" }
        if voice.isListening {
            return voice.transcript.isEmpty ? "在听" : voice.transcript
        }
        return ""
    }

    private func handleVoiceTap() {
        if voice.isListening {
            voice.stopListening()
            return
        }

        Task {
            let ok = await voice.requestAuthorization()
            if ok {
                voice.startListening()
            } else {
                showLogOdor = true
            }
        }
    }

    private func handleVoiceIntent(_ intent: VoiceIntent) {
        switch intent {
        case .emergency:
            logAsEmergency = true
            preselectedOdorType = nil
            preselectedRoom = currentRoom?.name
            showLogOdor = true

        case .logOdor(let type, let room):
            logAsEmergency = false
            preselectedOdorType = type
            preselectedRoom = room ?? currentRoom?.name
            showLogOdor = true

        case .switchRoom(let name):
            if let idx = vm.allRooms().firstIndex(where: { $0.name == name }) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    currentRoomIndex = idx
                }
            }

        case .recentIssues:
            showTimeline = true

        case .guidance(let type):
            guidanceType = type
            showGuidance = true

        case .openSettings:
            showSettings = true

        case .unknown:
            showLogOdor = true
        }
    }

    private func roomHint(status: StatusIndicator.State, room: Room, unresolved: Int) -> String {
        switch status {
        case .good:
            return "\(room.name) · 安好 · 轻触看历史"
        case .attention:
            return "\(room.name) · \(unresolved) 项待留意 · 轻触细看"
        case .emergency:
            return "\(room.name) · 需要马上留意"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_CN")
        fmt.dateFormat = "M月d日 EEEE"
        return fmt.string(from: date)
    }
}

// MARK: - Explore Sheet

private struct ExploreSheet: View {
    let emergencyCount: Int
    let onHistory: () -> Void
    let onGuidance: () -> Void
    let onSettings: () -> Void
    let onLog: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(DesignTokens.Colors.separator)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                exploreRow("记录气味", detail: "手动填写") {
                    dismiss()
                    onLog()
                }
                MinimalSeparator().padding(.leading, DesignTokens.Spacing.marginH)
                exploreRow("历史", detail: emergencyCount > 0 ? "\(emergencyCount) 紧急" : nil) {
                    dismiss()
                    onHistory()
                }
                MinimalSeparator().padding(.leading, DesignTokens.Spacing.marginH)
                exploreRow("排查指引", detail: nil) {
                    dismiss()
                    onGuidance()
                }
                MinimalSeparator().padding(.leading, DesignTokens.Spacing.marginH)
                exploreRow("设置", detail: nil) {
                    dismiss()
                    onSettings()
                }
            }
            Spacer(minLength: 0)
        }
        .background(DesignTokens.Colors.background)
    }

    private func exploreRow(_ title: String, detail: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.text)
                Spacer()
                if let detail {
                    Text(detail)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.alert)
                }
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(DesignTokens.Colors.textSecondary.opacity(0.4))
            }
            .padding(.horizontal, DesignTokens.Spacing.marginH)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Focus Card Pager

struct FocusCardPager: View {
    let rooms: [Room]
    @Binding var currentIndex: Int
    let onRoomTap: (Room) -> Void
    let unresolvedFor: (Room) -> Int
    let emergencyFor: (Room) -> Int

    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width - DesignTokens.Spacing.marginH * 2

            HStack(spacing: 16) {
                ForEach(Array(rooms.enumerated()), id: \.element.id) { _, room in
                    let emergency = emergencyFor(room)
                    let unresolved = unresolvedFor(room)
                    let status: StatusIndicator.State = emergency > 0 ? .emergency
                        : unresolved > 0 ? .attention : .good

                    FocusCard(
                        room: room,
                        status: status,
                        unresolvedCount: unresolved,
                        emergencyCount: emergency,
                        onTap: { onRoomTap(room) }
                    )
                    .frame(width: cardWidth)
                }
            }
            .offset(x: dragOffset - CGFloat(currentIndex) * (cardWidth + 16))
            .padding(.horizontal, DesignTokens.Spacing.marginH)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 40
                        if value.translation.width < -threshold, currentIndex < rooms.count - 1 {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                currentIndex += 1
                            }
                        } else if value.translation.width > threshold, currentIndex > 0 {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                currentIndex -= 1
                            }
                        }
                    }
            )
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: currentIndex)
        }
    }
}



