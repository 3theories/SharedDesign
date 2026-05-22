import SwiftUI

/// A premium row with a fixed-width label column on the left and a large rounded pill progress bar on the right.
/// Ideal for Health-like zone rows (e.g., heart rate zones).
public struct SideLabeledPillBarRow: View {
    // MARK: Lifecycle

    public init(
        title: String,
        subtitle: String? = nil,
        valueText: String? = nil,
        progress: Double,
        gradient: [Color],
        baseColor: Color,
        height: CGFloat = 20,
        labelWidth: CGFloat = 120
    ) {
        self.title = title
        self.subtitle = subtitle
        self.valueText = valueText
        self.progress = max(0, min(progress, 1))
        self.gradient = gradient
        self.baseColor = baseColor
        self.height = height
        self.labelWidth = labelWidth
    }

    // MARK: Public

    public var body: some View {
        HStack(alignment: .center, spacing: self.theme.spacing.md) {
            // Left label column
            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(self.theme.typography.title3.weight(.semibold))
                    .foregroundColor(self.theme.colors.textPrimary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(self.theme.typography.footnote)
                        .foregroundColor(self.theme.colors.textSecondary)
                }
            }
            .frame(width: self.labelWidth, alignment: .leading)

            // Right pill progress bar
            GeometryReader { proxy in
                let width = proxy.size.width
                let fillWidth = max(width * self.progress, self.height * 0.6)
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: self.height / 2, style: .continuous)
                        .fill(self.baseColor.opacity(0.2))
                        .frame(height: self.height)
                        .overlay(
                            // Soft inner gloss
                            LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom)
                                .clipShape(RoundedRectangle(cornerRadius: self.height / 2, style: .continuous))
                        )

                    // Fill
                    RoundedRectangle(cornerRadius: self.height / 2, style: .continuous)
                        .fill(LinearGradient(colors: self.gradient, startPoint: .leading, endPoint: .trailing))
                        .frame(width: min(fillWidth, width), height: self.height)
                        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                        .overlay(
                            // Value text inside the fill
                            HStack {
                                if let valueText, !valueText.isEmpty {
                                    Text(valueText)
                                        .font(self.theme.typography.subheadline.weight(.bold))
                                        .foregroundColor(.white)
                                        .padding(.leading, 12)
                                        .padding(.trailing, 8)
                                }
                                Spacer(minLength: 0)
                            }
                        )
                }
            }
            .frame(height: self.height)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Internal

    let title: String
    let subtitle: String?
    let valueText: String?
    let progress: Double
    let gradient: [Color]
    let baseColor: Color
    let height: CGFloat
    let labelWidth: CGFloat

    // MARK: Private

    @Environment(\.theme) private var theme
}

#Preview("SideLabeledPillBarRow") {
    VStack(spacing: 16) {
        SideLabeledPillBarRow(
            title: "Zone 2",
            subtitle: "Light",
            valueText: "9:03",
            progress: 0.45,
            gradient: [.cyan, .teal],
            baseColor: .teal.opacity(0.9),
            height: 22,
            labelWidth: 120
        )

        SideLabeledPillBarRow(
            title: "Zone 3",
            subtitle: "Moderate",
            valueText: "0:46",
            progress: 0.2,
            gradient: [.green, .green.opacity(0.8)],
            baseColor: .green.opacity(0.9),
            height: 22
        )
    }
    .padding()
}
