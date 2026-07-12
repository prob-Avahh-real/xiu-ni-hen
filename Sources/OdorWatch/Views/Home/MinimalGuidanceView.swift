import SwiftUI

/// Minimal guidance panel — shows one odor type's guidance as a numbered list.
/// Clean, single-focus, no accordion UI.
struct MinimalGuidanceView: View {
    @Environment(\.dismiss) private var dismiss
    let highlightedType: OdorType?

    @State private var selectedType: OdorType?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text("排查指引")
                    .font(DesignTokens.Typography.h2)
                Spacer()
                Button {
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

            // Type selector — horizontal chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(OdorType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedType = type }
                        } label: {
                            Text(type.rawValue)
                                .font(DesignTokens.Typography.caption.weight(selectedType == type ? .semibold : .regular))
                                .foregroundStyle(selectedType == type ? .white : DesignTokens.Colors.text)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedType == type ? DesignTokens.Colors.accent : Color.clear)
                                .clipShape(Capsule())
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.pill)
                                        .stroke(DesignTokens.Colors.separator, lineWidth: selectedType == type ? 0 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.marginH)
            }
            .padding(.vertical, DesignTokens.Spacing.padding)

            MinimalSeparator()

            // Guidance steps
            if let type = selectedType {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Danger level indicator
                        HStack(spacing: DesignTokens.Spacing.tight) {
                            Text("危险等级")
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                            HStack(spacing: 3) {
                                ForEach(1...5, id: \.self) { i in
                                    Rectangle()
                                        .fill(i <= type.dangerLevel ? DesignTokens.Colors.alert : DesignTokens.Colors.separator)
                                        .frame(width: 12, height: 4)
                                        .clipShape(Capsule())
                                }
                            }
                            Text("\(type.dangerLevel)/5")
                                .font(DesignTokens.Typography.micro)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.marginH)
                        .padding(.vertical, DesignTokens.Spacing.padding)

                        MinimalSeparator()

                        ForEach(Array(type.guidance.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 16) {
                                Text("\(idx + 1)")
                                    .font(DesignTokens.Typography.body.weight(.medium))
                                    .foregroundStyle(DesignTokens.Colors.accent)
                                    .frame(width: 24, alignment: .center)

                                Text(step)
                                    .font(DesignTokens.Typography.body)
                                    .foregroundStyle(DesignTokens.Colors.text)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.marginH)
                            .padding(.vertical, 14)

                            if idx < type.guidance.count - 1 {
                                MinimalSeparator()
                                    .padding(.leading, DesignTokens.Spacing.marginH + 24)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: DesignTokens.Spacing.tight) {
                    Spacer().frame(height: 60)
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(DesignTokens.Colors.textSecondary.opacity(0.4))
                    Text("选择气味类型查看排查指引")
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Spacer()
                }
            }
        }
        .background(DesignTokens.Colors.background)
        .onAppear {
            if let type = highlightedType {
                selectedType = type
            }
        }
    }
}
