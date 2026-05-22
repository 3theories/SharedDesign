import SwiftUI

// MARK: - GradientButton

/// A button with gradient background for premium/special CTAs
public struct GradientButton: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        _ title: String,
        icon: String? = nil,
        gradientStyle: GradientStyle = .premium,
        size: SharedButton.Size = .medium,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradientStyle = gradientStyle
        self.size = size
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    // MARK: Public

    // MARK: - Types

    public enum GradientStyle {
        case primary // Brand primary gradient
        case premium // Premium/paywall gradient
        case ai // AI features gradient
        case custom(gradient: LinearGradient)
    }

    // MARK: - Body

    public var body: some View {
        Button(action: {
            if !self.isLoading && self.isEnabled {
                HapticManager.shared.trigger(.medium)
                self.action()
            }
        }) {
            ZStack {
                // Gradient background
                self.gradient
                    .opacity(self.isEnabled ? 1 : 0.5)

                // Shimmer effect when enabled
                if self.isEnabled && !self.isLoading {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.2),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .rotationEffect(.degrees(15))
                    .offset(x: self.isPressed ? 200 : -200)
                    .animation(
                        .easeInOut(duration: 2.5).repeatForever(autoreverses: false),
                        value: self.isPressed
                    )
                    .allowsHitTesting(false)
                }

                // Content
                if self.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    HStack(spacing: self.theme.spacing.xs) {
                        if let icon {
                            Image(systemName: icon)
                                .font(self.iconFont)
                                .accessibilityHidden(true)
                        }

                        Text(self.title)
                            .font(self.textFont)
                            .fontWeight(.semibold)
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: self.isFullWidth ? .infinity : nil)
            .frame(height: self.height)
            .clipShape(Capsule())
            .shadow(
                color: self.shadowColor,
                radius: self.isEnabled ? 8 : 0,
                x: 0,
                y: 4
            )
        }
        .disabled(!self.isEnabled || self.isLoading)
        .scaleEffect(self.isPressed ? 0.97 : 1.0)
        .animation(self.theme.animations.quick, value: self.isPressed)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                self.isPressed = pressing
            },
            perform: { }
        )
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var isPressed = false

    private let title: String
    private let icon: String?
    private let gradientStyle: GradientStyle
    private let size: SharedButton.Size
    private let isFullWidth: Bool
    private let isLoading: Bool
    private let isEnabled: Bool
    private let action: () -> Void

    private var height: CGFloat {
        switch self.size {
        case .small:
            self.theme.sizing.buttonHeight.small
        case .medium:
            self.theme.sizing.buttonHeight.medium
        case .large:
            self.theme.sizing.buttonHeight.large
        }
    }

    private var textFont: Font {
        switch self.size {
        case .small:
            ExtendedTypography.buttonSmall
        case .medium:
            ExtendedTypography.buttonMedium
        case .large:
            ExtendedTypography.buttonLarge
        }
    }

    private var iconFont: Font {
        switch self.size {
        case .small:
            .system(size: 14, weight: .semibold)
        case .medium:
            .system(size: 16, weight: .semibold)
        case .large:
            .system(size: 18, weight: .semibold)
        }
    }

    private var gradient: LinearGradient {
        switch self.gradientStyle {
        case .primary:
            self.theme.gradients.brandPrimary
        case .premium:
            self.theme.gradients.premium
        case .ai:
            // Use primary gradient for AI features for consistency
            self.theme.gradients.brandPrimary
        case let .custom(gradient):
            gradient
        }
    }

    private var shadowColor: Color {
        switch self.gradientStyle {
        case .primary:
            self.theme.colors.primary.opacity(0.3)
        case .premium:
            self.theme.colors.accentGold.opacity(0.3)
        case .ai:
            // Use primary shadow for AI features for consistency
            self.theme.colors.primary.opacity(0.3)
        case .custom:
            Color.black.opacity(0.1)
        }
    }
}

// MARK: - GradientButton_Previews

struct GradientButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Gradient styles
            GradientButton("Get Started", icon: "arrow.right", gradientStyle: .primary) { }
            GradientButton("Upgrade to Premium", icon: "crown.fill", gradientStyle: .premium) { }
            GradientButton("AI Coach", icon: "sparkles", gradientStyle: .ai) { }

            Divider()

            // Sizes
            GradientButton("Small", size: .small) { }
            GradientButton("Medium", size: .medium) { }
            GradientButton("Large", size: .large) { }

            Divider()

            // States
            GradientButton("Loading", isLoading: true) { }
            GradientButton("Disabled", isEnabled: false) { }

            // Full width
            GradientButton("Unlock All Features", icon: "lock.open.fill", isFullWidth: true) { }

            // Custom gradient
            GradientButton(
                "Custom Gradient",
                gradientStyle: .custom(gradient: LinearGradient(
                    colors: [.orange, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )),
                isFullWidth: true
            ) { }
        }
        .padding()
        .environment(\.theme, DefaultTheme())
    }
}
