import SwiftUI

// MARK: - AICoachingTipCard

/// A premium card component for displaying AI-generated coaching tips
/// Features a glowing lightbulb icon, refined typography, and actionable advice
public struct AICoachingTipCard: View {
    // MARK: Lifecycle

    public init(
        tip: String,
        isLoading: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.tip = tip
        self.isLoading = isLoading
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Clean header
            HStack(spacing: 10) {
                // Lightbulb icon with subtle glow
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image("tips")
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .foregroundStyle(self.accentGradient)
                        .accessibilityHidden(true)
                }

                Text(String(
                    localized: "coaching.tip.label",
                    defaultValue: "Coaching Tip",
                    bundle: .module,
                    comment: "AI coaching tip card header label"
                ))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(self.theme.colors.textSecondary)

                Spacer()
            }

            // Tip content
            if self.isLoading {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(0..<2, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(self.theme.colors.textSecondary.opacity(0.08))
                            .frame(height: 16)
                            .frame(maxWidth: index == 1 ? 180 : .infinity)
                            .shimmer()
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            } else {
                Text(self.tip)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(self.theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)
                    .tracking(0.15)
                    .shadow(color: Color.orange.opacity(0.08), radius: 8, x: 0, y: 2)
            }
        }
        .padding(16)
        .scaleEffect(self.scale)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(self.theme.colors.surface1)

                // Subtle warm gradient overlay
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.06),
                                Color.yellow.opacity(0.03),
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
        .hapticOnTap(.medium)
        .accessibilityElement(children: .combine)
    }

    // MARK: Internal

    let tip: String
    let isLoading: Bool
    let onTap: (() -> Void)?

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.4

    private let accentGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.8, blue: 0.2), Color(red: 1.0, green: 0.5, blue: 0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Helper Methods

    private func handleTap() {
        withAnimation(AnimationConstants.Spring.bouncy) {
            self.scale = 0.98
        }
        withAnimation(AnimationConstants.Spring.quick.delay(0.1)) {
            self.scale = 1.0
        }

        self.onTap?()
    }
}

// MARK: - Preview

#if DEBUG
    struct AICoachingTipCard_Previews: PreviewProvider {
        static var previews: some View {
            ScrollView {
                VStack(spacing: 20) {
                    Text("AI Coaching Tip Cards")
                        .font(.title2.bold())
                        .padding()

                    AICoachingTipCard(
                        tip: "Try incorporating a 5-minute warm-up before strength training to improve performance and reduce injury risk."
                    )

                    AICoachingTipCard(
                        tip: "To reach your protein goals, consider adding a protein-rich snack between lunch and dinner, like Greek yogurt or nuts."
                    )

                    AICoachingTipCard(
                        tip: "Since you're new to 16:8 fasting, try starting with a 12:12 window and gradually extending it over 2-3 weeks."
                    )

                    AICoachingTipCard(
                        tip: "Your consistency is excellent! Consider challenging yourself with progressive overload by adding 2.5-5 lbs to your lifts each week."
                    )

                    AICoachingTipCard(
                        tip: "Loading...",
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
