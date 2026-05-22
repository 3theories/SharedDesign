import SwiftUI

// MARK: - UnifiedNutritionCard

/// Unified nutrition visualization with segmented arc gauge and macro cards
public struct UnifiedNutritionCard: View {
    // MARK: Lifecycle

    public init(data: NutritionData) {
        self.data = data
    }

    // MARK: Public

    public let data: NutritionData

    public var body: some View {
        VStack(spacing: self.theme.spacing.sm) {
            // Main segmented arc gauge
            ZStack {
                // Arc visual
                self.segmentedArc
                    .frame(height: 200)

                // Content overlay
                VStack(spacing: self.theme.spacing.lg) {
                    Spacer()
                        .frame(height: 30)

                    self.calorieIcon

                    Spacer()
                        .frame(height: self.theme.spacing.xs)

                    self.centerCalorieDisplay

                    Spacer()
                }
            }
            .frame(height: 200)

            // Macro breakdown cards
            self.macroBreakdownCards
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                self.animateProgress = true
            }
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var animateProgress = false

    // MARK: - Segmented Arc

    @ViewBuilder
    private var segmentedArc: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            // Make radius larger so the arc is more prominent
            let radius = min(width * 0.85, height * 2.2) / 2
            let centerX = width / 2
            // Center point is at the bottom, so the arc curves upward
            let centerY = height + 10

            ZStack {
                // Background arc segments
                self.backgroundSegments(radius: radius)
                    .position(x: centerX, y: centerY)

                // Progress arc segments
                self.progressSegments(radius: radius)
                    .position(x: centerX, y: centerY)
            }
        }
    }

    @ViewBuilder
    private var centerCalorieDisplay: some View {
        VStack(spacing: self.theme.spacing.xxs / 2) {
            // Show remaining calories to match the label
            Text(verbatim: "\(Int(max(self.data.calories.remaining, 0)))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(self.theme.colors.textPrimary)
                .contentTransition(.numericText())

            Text(L10n.string("chart.unified_nutrition.remaining", defaultValue: "Remaining"))
                .font(self.theme.typography.subheadline)
                .foregroundStyle(self.theme.colors.textSecondary)
        }
    }

    @ViewBuilder
    private var calorieIcon: some View {
        ZStack {
            Circle()
                .fill(self.theme.colors.success.opacity(0.15))
                .frame(width: 40, height: 40)

            Image("fire")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .accessibilityHidden(true)
        }
    }

    // MARK: - Macro Breakdown Cards

    @ViewBuilder
    private var macroBreakdownCards: some View {
        HStack(spacing: self.theme.spacing.sm) {
            MacroCard(
                type: .protein,
                value: self.data.protein,
                animateProgress: self.animateProgress
            )

            MacroCard(
                type: .carbs,
                value: self.data.carbs,
                animateProgress: self.animateProgress
            )

            MacroCard(
                type: .fat,
                value: self.data.fat,
                animateProgress: self.animateProgress
            )
        }
    }

    @ViewBuilder
    private func backgroundSegments(radius: CGFloat) -> some View {
        let lineWidth: CGFloat = 28
        let segmentCount = 20
        let gapAngle: CGFloat = 0.05

        ForEach(0..<segmentCount, id: \.self) { index in
            SegmentArc(
                index: index,
                totalSegments: segmentCount,
                gapAngle: gapAngle,
                radius: radius,
                lineWidth: lineWidth
            )
            .stroke(self.theme.colors.surface3, lineWidth: lineWidth)
        }
    }

    @ViewBuilder
    private func progressSegments(radius: CGFloat) -> some View {
        let lineWidth: CGFloat = 28
        let segmentCount = 20
        let gapAngle: CGFloat = 0.05

        // Calculate how many segments should be filled based on calorie progress
        let progress = self.animateProgress ? self.data.calories.progress : 0
        let filledSegments = Int(Double(segmentCount) * progress)

        ForEach(0..<filledSegments, id: \.self) { index in
            SegmentArc(
                index: index,
                totalSegments: segmentCount,
                gapAngle: gapAngle,
                radius: radius,
                lineWidth: lineWidth
            )
            .stroke(
                self.segmentGradient(for: index, total: segmentCount),
                lineWidth: lineWidth
            )
        }
    }

    private func segmentGradient(for index: Int, total: Int) -> LinearGradient {
        // Use calorie ratio to choose a friendly color mapping
        let ratio = self.data.calories.target > 0 ? (self.data.calories.consumed / self.data.calories.target) : 0

        // Below target → greens, above target → warm red/orange
        let startColor: Color
        let endColor: Color
        if ratio <= 1.0 {
            startColor = self.theme.colors.success
            endColor = self.theme.colors.success.opacity(0.6)
        } else {
            startColor = Color.orange
            endColor = Color.red
        }

        return LinearGradient(
            colors: [startColor, endColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - SegmentArc

private struct SegmentArc: Shape {
    let index: Int
    let totalSegments: Int
    let gapAngle: CGFloat
    let radius: CGFloat
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.maxY)

        // Arc spans from -180° to 0° (bottom half circle)
        let totalAngle = CGFloat.pi
        let segmentAngle = (totalAngle - (gapAngle * CGFloat(self.totalSegments - 1))) / CGFloat(self.totalSegments)

        let startAngle = -.pi + (segmentAngle + self.gapAngle) * CGFloat(self.index)
        let endAngle = startAngle + segmentAngle

        var path = Path()
        path.addArc(
            center: center,
            radius: self.radius,
            startAngle: Angle(radians: startAngle),
            endAngle: Angle(radians: endAngle),
            clockwise: false
        )

        return path
    }
}

// MARK: - MacroCard

private struct MacroCard: View {
    @Environment(\.theme) private var theme
    let type: MacroType
    let value: NutritionData.MacroValue
    let animateProgress: Bool

    var body: some View {
        VStack(spacing: self.theme.spacing.xs) {
            // Icon
            Image(self.type.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(self.type.color(from: self.theme))
                .accessibilityHidden(true)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(self.theme.colors.surface3)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(self.type.color(from: self.theme))
                        .frame(
                            width: geometry.size.width * (self.animateProgress ? self.value.progress : 0),
                            height: 6
                        )
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: self.animateProgress)
                }
            }
            .frame(height: 6)

            // Values
            VStack(spacing: 2) {
                Text("\(Int(self.value.consumed))g")
                    .font(self.theme.typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(self.theme.colors.textPrimary)
                    .contentTransition(.numericText())

                Text(self.type.rawValue)
                    .font(self.theme.typography.caption2)
                    .foregroundStyle(self.theme.colors.textSecondary)
            }
        }
        .padding(.vertical, self.theme.spacing.sm)
        .padding(.horizontal, self.theme.spacing.xs)
        .frame(maxWidth: .infinity)
        .background(self.theme.colors.surface2)
        .cornerRadius(self.theme.sizing.cornerRadius.medium)
    }
}

// MARK: - Preview

#if !os(watchOS)
    #Preview("Unified Nutrition Card - Clean") {
        VStack(spacing: 20) {
            UnifiedNutritionCard(
                data: NutritionData(
                    calories: .init(consumed: 1739, target: 2925),
                    protein: .init(consumed: 120, target: 150),
                    carbs: .init(consumed: 190, target: 300),
                    fat: .init(consumed: 70, target: 80)
                )
            )

            UnifiedNutritionCard(
                data: NutritionData(
                    calories: .init(consumed: 2400, target: 2925),
                    protein: .init(consumed: 145, target: 150),
                    carbs: .init(consumed: 295, target: 300),
                    fat: .init(consumed: 78, target: 80)
                )
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
#endif
