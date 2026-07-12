import SwiftUI

struct GuidanceView: View {
    @State private var selectedType: OdorType?

    var body: some View {
        List {
            ForEach(OdorType.allCases, id: \.self) { type in
                Section {
                    Button { selectedType = (selectedType == type ? nil : type) } label: {
                        HStack {
                            Text("\(type.icon) \(type.rawValue)").font(.headline).foregroundStyle(.primary)
                            Spacer()
                            Text("危险等级 \(type.dangerLevel)/5").font(.caption).foregroundStyle(type.color)
                            Image(systemName: selectedType == type ? "chevron.down" : "chevron.right")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if selectedType == type {
                        ForEach(type.guidance, id: \.self) { step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("•").foregroundStyle(type.color)
                                Text(step).font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("排查指引")
        .animation(.easeInOut(duration: 0.2), value: selectedType)
    }
}
