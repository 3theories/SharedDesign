import SwiftUI

// MARK: - AIInsightSummaryCard

/// A premium card component for displaying AI-generated insight summaries
/// Features a glass-morphic background, animated sparkle, and refined typography
public struct AIInsightSummaryCard: View {
    // MARK: Lifecycle

    public init(
        summary: String,
        domain: InsightDomain = .workout,
        isLoading: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.summary = summary
        self.domain = domain
        self.isLoading = isLoading
        self.onTap = onTap
    }

    // MARK: Public

    public enum InsightDomain {
        case workout
        case nutrition
        case fasting
        case sleep
        case steps

        // MARK: Internal

        var icon: String {
            switch self {
            case .workout: "liftWeight"
            case .nutrition: "serving"
            case .fasting: "duration"
            case .sleep: "sleep"
            case .steps: "figure.walk"
            }
        }

        var isSystemIcon: Bool {
            switch self {
            case .workout, .sleep, .nutrition, .fasting: false
            case .steps: true
            }
        }

        var accentColor: Color {
            switch self {
            case .workout: Color(red: 0.4, green: 0.6, blue: 1.0)
            case .nutrition: Color(red: 0.3, green: 0.8, blue: 0.5)
            case .fasting: Color(red: 1.0, green: 0.6, blue: 0.2)
            case .sleep: Color(red: 0.5, green: 0.4, blue: 0.9)
            case .steps: Color(red: 0.3, green: 0.75, blue: 0.7)
            }
        }

        var gradientColors: [Color] {
            switch self {
            case .workout: [Color(red: 0.3, green: 0.5, blue: 1.0), Color(red: 0.5, green: 0.3, blue: 0.9)]
            case .nutrition: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.3, green: 0.8, blue: 0.6)]
            case .fasting: [Color(red: 1.0, green: 0.5, blue: 0.1), Color(red: 1.0, green: 0.7, blue: 0.3)]
            case .sleep: [Color(red: 0.4, green: 0.3, blue: 0.8), Color(red: 0.6, green: 0.4, blue: 0.9)]
            case .steps: [Color(red: 0.2, green: 0.65, blue: 0.6), Color(red: 0.4, green: 0.8, blue: 0.75)]
            }
        }

        var title: String {
            switch self {
            case .workout: String(
                    localized: "insight.domain.workout.title",
                    defaultValue: "Workout Insights",
                    bundle: .module,
                    comment: "AI insight domain title for workouts"
                )
            case .nutrition: String(
                    localized: "insight.domain.nutrition.title",
                    defaultValue: "Nutrition Insights",
                    bundle: .module,
                    comment: "AI insight domain title for nutrition"
                )
            case .fasting: String(
                    localized: "insight.domain.fasting.title",
                    defaultValue: "Fasting Insights",
                    bundle: .module,
                    comment: "AI insight domain title for fasting"
                )
            case .sleep: String(
                    localized: "insight.domain.sleep.title",
                    defaultValue: "Sleep Insights",
                    bundle: .module,
                    comment: "AI insight domain title for sleep"
                )
            case .steps: String(
                    localized: "insight.domain.activity.title",
                    defaultValue: "Activity Insights",
                    bundle: .module,
                    comment: "AI insight domain title for activity/steps"
                )
            }
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Clean header
            HStack(spacing: 10) {
                // AI sparkle badge
                ZStack {
                    // Subtle glow
                    Circle()
                        .fill(self.domain.accentColor.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image("aiSummary")
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .foregroundStyle(
                            LinearGradient(
                                colors: self.domain.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(self.sparkleRotation))
                        .accessibilityHidden(true)
                }

                Text(String(
                    localized: "insight.aiSummary.label",
                    defaultValue: "AI Summary",
                    bundle: .module,
                    comment: "AI insight summary card header label"
                ))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(self.theme.colors.textSecondary)

                Spacer()

                // Domain indicator
                AppIconView(name: self.domain.icon, isSystemIcon: self.domain.isSystemIcon)
                    .font(.system(size: 16))
                    .frame(width: 16, height: 16)
                    .foregroundColor(self.domain.accentColor.opacity(0.7))
                    .accessibilityHidden(true)
            }

            // Summary content
            if self.isLoading {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(self.theme.colors.textSecondary.opacity(0.08))
                            .frame(height: 16)
                            .frame(maxWidth: index == 2 ? 200 : .infinity)
                            .shimmer()
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            } else {
                Text(self.summary)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(self.theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)
                    .tracking(0.15)
                    .shadow(color: self.domain.accentColor.opacity(0.08), radius: 8, x: 0, y: 2)
            }
        }
        .padding(16)
        .scaleEffect(self.scale)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(self.theme.colors.surface1)

                // Subtle gradient overlay based on domain
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                self.domain.accentColor.opacity(0.06),
                                self.domain.accentColor.opacity(0.02),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            self.handleTap()
        }
        .hapticOnTap(.light)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3)
                    .repeatForever(autoreverses: true)
            ) {
                self.sparkleRotation = 10
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Internal

    let summary: String
    let domain: InsightDomain
    let isLoading: Bool
    let onTap: (() -> Void)?

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var scale: CGFloat = 1.0
    @State private var sparkleRotation: Double = 0

    // MARK: - Helper Methods

    private func handleTap() {
        withAnimation(AnimationConstants.Spring.bouncy) {
            self.scale = 1.02
        }
        withAnimation(AnimationConstants.Spring.quick.delay(0.1)) {
            self.scale = 1.0
        }

        self.onTap?()
    }
}

// MARK: - Preview

#if DEBUG
    struct AIInsightSummaryCard_Previews: PreviewProvider {
        static var previews: some View {
            ScrollView {
                VStack(spacing: 20) {
                    Text("AI Insight Summary Cards")
                        .font(.title2.bold())
                        .padding()

                    AIInsightSummaryCard(
                        summary: "Great progress this week! You've completed 5 workouts with an average of 450 calories burned per session. Your consistency is improving, especially with strength training.",
                        domain: .workout
                    )

                    AIInsightSummaryCard(
                        summary: "Your nutrition is well-balanced this week with good protein intake (120g avg). Consider increasing fiber-rich foods to reach your daily fiber goal of 30g.",
                        domain: .nutrition
                    )

                    AIInsightSummaryCard(
                        summary: "Excellent fasting consistency! You've maintained 16:8 for 7 days straight. Your body is adapting well to the routine.",
                        domain: .fasting
                    )

                    AIInsightSummaryCard(
                        summary: "Your sleep quality has improved by 15% this week. You're averaging 7.5 hours with good deep sleep phases. Try to maintain your consistent 10:30 PM bedtime.",
                        domain: .sleep
                    )

                    AIInsightSummaryCard(
                        summary: "You're on a 5-day step goal streak! Averaging 9,200 steps daily puts you in the moderately active category. A short evening walk could push you to 10,000.",
                        domain: .steps
                    )

                    AIInsightSummaryCard(
                        summary: "Loading...",
                        domain: .workout,
                        isLoading: true
                    )
                }
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .environment(\.theme, DefaultTheme())
        }
    }
#endif
