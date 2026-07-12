import SwiftUI

/// Minimal timeline — one event per card, swipe to browse history.
/// Focused, exploratory, not a scrolling list.
struct MinimalTimelineView: View {
    @ObservedObject var vm: OdorViewModel
    @Environment(\.dismiss) private var dismiss
    let highlightedEvent: OdorEvent?

    @State private var currentIndex: Int = 0
    @State private var filterRoom: UUID?
    @State private var showResolved: Bool = true

    private var filteredEvents: [OdorEvent] {
        var events = vm.events
        if !showResolved { events = events.filter { $0.resolvedAt == nil } }
        if let rid = filterRoom { events = events.filter { $0.roomId == rid } }
        return events
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.textSecondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                Spacer()
                Text("历史")
                    .font(DesignTokens.Typography.h2)
                Spacer()
                // Filter toggle
                Menu {
                    Picker("房间", selection: $filterRoom) {
                        Text("全部房间").tag(nil as UUID?)
                        ForEach(vm.allRooms()) { r in Text(r.name).tag(r.id as UUID?) }
                    }
                    Toggle("显示已处理", isOn: $showResolved)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.marginH)
            .padding(.vertical, DesignTokens.Spacing.padding)

            MinimalSeparator()

            if filteredEvents.isEmpty {
                VStack(spacing: DesignTokens.Spacing.tight) {
                    Spacer().frame(height: 80)
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(DesignTokens.Colors.textSecondary.opacity(0.4))
                    Text("没有匹配的事件")
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                // Card pager
                GeometryReader { geo in
                    HStack(spacing: 16) {
                        ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { idx, event in
                            EventDetailCard(
                                event: event,
                                roomName: vm.roomName(for: event.roomId),
                                onResolve: { vm.resolveEvent(event.id) },
                                onDelete: {
                                    vm.deleteEvent(event.id)
                                    if currentIndex >= filteredEvents.count { currentIndex = max(0, filteredEvents.count - 1) }
                                }
                            )
                            .frame(width: geo.size.width - DesignTokens.Spacing.marginH * 2)
                        }
                    }
                    .offset(x: -CGFloat(currentIndex) * (geo.size.width - DesignTokens.Spacing.marginH * 2 + 16))
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                if value.translation.width < -threshold, currentIndex < filteredEvents.count - 1 {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        currentIndex += 1
                                    }
                                } else if value.translation.width > threshold, currentIndex > 0 {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        currentIndex -= 1
                                    }
                                }
                            }
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentIndex)
                }
                .padding(.vertical, DesignTokens.Spacing.block)

                // Page indicator
                if filteredEvents.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<min(filteredEvents.count, 20), id: \.self) { i in
                            Circle()
                                .fill(i == currentIndex ? DesignTokens.Colors.accent : DesignTokens.Colors.separator)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, DesignTokens.Spacing.block)
                }
            }
        }
        .background(DesignTokens.Colors.background)
        .onAppear {
            if let event = highlightedEvent,
               let idx = filteredEvents.firstIndex(where: { $0.id == event.id }) {
                currentIndex = idx
            }
        }
    }
}

// MARK: - Event Detail Card

struct EventDetailCard: View {
    let event: OdorEvent
    let roomName: String
    let onResolve: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.block) {
            // Header: type + emergency badge
            HStack {
                Text(event.type.rawValue)
                    .font(DesignTokens.Typography.h2)
                Spacer()
                if event.isEmergency {
                    Text("紧急")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DesignTokens.Colors.alert)
                        .clipShape(Capsule())
                }
            }

            // Meta info
            VStack(alignment: .leading, spacing: 6) {
                MetaRow(label: "房间", value: roomName)
                MetaRow(label: "强度", value: "\(String(repeating: "●", count: event.intensity))\(String(repeating: "○", count: 5 - event.intensity))  \(event.intensity)/5")
                MetaRow(label: "时间", value: event.detectedAt.formatted(date: .long, time: .shortened))
                if let notes = event.notes {
                    MetaRow(label: "备注", value: notes)
                }
                if let resolved = event.resolvedAt {
                    MetaRow(label: "已处理", value: resolved.formatted(date: .abbreviated, time: .shortened))
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                if event.resolvedAt == nil {
                    Button {
                        onResolve()
                    } label: {
                        Label("标记已处理", systemImage: "checkmark")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("删除", systemImage: "trash")
                }
                .buttonStyle(OutlineButtonStyle())
            }
        }
        .padding(DesignTokens.Spacing.padding)
        .background(DesignTokens.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.standard)
                .stroke(DesignTokens.Colors.separator, lineWidth: 1)
        )
    }
}

// MARK: - Meta Row

struct MetaRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.tight) {
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .frame(width: 40, alignment: .leading)
            Text(value)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.text)
            Spacer()
        }
    }
}
