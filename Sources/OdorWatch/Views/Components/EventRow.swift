import SwiftUI

struct EventRow: View {
    let event: OdorEvent
    let roomName: String

    var body: some View {
        HStack(spacing: 12) {
            Text(event.type.icon).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.type.rawValue).font(.subheadline).fontWeight(.medium)
                    if event.isEmergency {
                        Text("紧急").font(.caption2).foregroundStyle(.white).padding(.horizontal, 5).padding(.vertical, 1)
                            .background(.red).clipShape(Capsule())
                    }
                }
                Text("\(roomName) · \(event.detectedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Circle().fill(i <= event.intensity ? event.type.color : Color.gray.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
            Image(systemName: event.resolvedAt != nil ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(event.resolvedAt != nil ? .green : .gray)
        }
        .padding(.vertical, 4)
    }
}
