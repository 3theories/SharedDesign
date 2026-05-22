import SwiftUI

// MARK: - AIFeatureButton

/// A button specifically designed for AI features with premium/lock states
public struct AIFeatureButton: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        icon: String = "sparkles",
        title: String? = nil,
        size: Size = .medium,
        style: Style = .inline,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        onDisabledTap: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.size = size
        self.style = style
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.onDisabledTap = onDisabledTap
        self.action = action
    }

    // MARK: Public

    // MARK: - Types

    public enum Size {
        case small // Inline buttons (e.g., sparkles next to text field)
        case medium // Standard buttons
        case large // Prominent CTAs

        // MARK: Internal

        var iconSize: CGFloat {
            switch self {
            case .small: 16
            case .medium: 20
            case .large: 24
            }
        }

        var buttonSize: CGFloat {
            switch self {
            case .small: 30
            case .medium: 40
            case .large: 50
            }
        }
    }

    public enum Style {
        case inline // Minimal, icon-only
        case compact // Icon with small label
        case standard // Full button with icon and text
    }

    // MARK: - Body

    public var body: some View {
        Button(action: {
            if !self.isLoading {
                HapticManager.shared.trigger(.light)
                if self.isEnabled {
                    self.action()
                } else if let onDisabledTap {
                    onDisabledTap()
                }
            }
        }) {
            Group {
                switch self.style {
                case .inline:
                    self.inlineContent
                case .compact:
                    self.compactContent
                case .standard:
                    self.standardContent
                }
            }
        }
        .disabled(self.isLoading)
        .accessibilityLabel(self.title ?? String(
            localized: "button.ai.feature",
            defaultValue: "AI Feature",
            bundle: .module
        ))
        .scaleEffect(self.isPressed ? 0.95 : 1.0)
        .animation(self.theme.animations.quick, value: self.isPressed)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                self.isPressed = pressing
            },
            perform: { }
        )
        #if !os(watchOS)
        .onHover { hovering in
            withAnimation(self.theme.animations.bounce) {
                self.sparkleRotation = hovering ? 15 : 0
            }
        }
        #endif
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var isPressed = false
    @State private var sparkleRotation = 0.0

    private let icon: String
    private let title: String?
    private let size: Size
    private let style: Style
    private let isEnabled: Bool
    private let isLoading: Bool
    private let action: () -> Void
    private let onDisabledTap: (() -> Void)?

    private var titleFont: Font {
        switch self.size {
        case .small:
            self.theme.typography.caption1
        case .medium:
            self.theme.typography.subheadline
        case .large:
            self.theme.typography.headline
        }
    }

    private var buttonSizeToGradientSize: SharedButton.Size {
        switch self.size {
        case .small: .small
        case .medium: .medium
        case .large: .large
        }
    }

    // MARK: - Content Layouts

    private var inlineContent: some View {
        ZStack {
            if self.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: self.theme.colors.primary))
                    .scaleEffect(0.8)
            } else {
                ZStack {
                    // Always show the icon with full colors
                    Image(systemName: self.icon)
                        .font(.system(size: self.size.iconSize, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [self.theme.colors.primary, self.theme.colors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(self.sparkleRotation))
                        .opacity(self.isEnabled ? 1 : 0.9)

                    // Lock badge overlay for disabled state
                    if !self.isEnabled {
                        Image("lock")
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(width: self.size.iconSize * 0.6, height: self.size.iconSize * 0.6)
                            .foregroundStyle(self.theme.colors.surface, self.theme.colors.warning)
                            .symbolRenderingMode(.palette)
                            .offset(x: self.size.iconSize * 0.35, y: -self.size.iconSize * 0.35)
                    }
                }
                .symbolEffect(.pulse.byLayer, options: .repeating, value: !self.isEnabled)
            }
        }
        .frame(width: self.size.buttonSize, height: self.size.buttonSize)
    }

    private var compactContent: some View {
        ZStack {
            HStack(spacing: self.theme.spacing.xs) {
                if self.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: self.theme.colors.primary))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: self.icon)
                        .font(.system(size: self.size.iconSize, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .rotationEffect(.degrees(self.sparkleRotation))

                    if let title {
                        Text(title)
                            .font(self.titleFont)
                            .fontWeight(.medium)
                    }

                    // Lock icon at the end
                    if !self.isEnabled {
                        Image("lock")
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(width: self.size.iconSize * 0.7, height: self.size.iconSize * 0.7)
                            .foregroundStyle(self.theme.colors.warning)
                    }
                }
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [self.theme.colors.primary, self.theme.colors.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(self.isEnabled ? 1 : 0.9)
            .padding(.horizontal, self.theme.spacing.sm)
            .padding(.vertical, self.theme.spacing.xs)
            .background(
                Capsule()
                    .fill(self.theme.colors.surface3)
                    .opacity(self.isEnabled ? 1 : 0.95)
            )
        }
        .symbolEffect(.pulse.byLayer, options: .repeating, value: !self.isEnabled)
    }

    private var standardContent: some View {
        ZStack {
            // Always use gradient button but with lock overlay when disabled
            GradientButton(
                self.title ?? "AI Feature",
                icon: self.icon,
                gradientStyle: .ai,
                size: self.buttonSizeToGradientSize,
                isFullWidth: false,
                isLoading: self.isLoading,
                isEnabled: true
            ) { // Keep visual enabled for better appearance
                if self.isEnabled {
                    self.action()
                } else if let onDisabledTap {
                    onDisabledTap()
                }
            }
            .opacity(self.isEnabled ? 1 : 0.95)

            // Lock overlay for disabled state
            if !self.isEnabled {
                HStack(spacing: 0) {
                    Spacer()
                    Image("lock")
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: self.size.iconSize * 0.8, height: self.size.iconSize * 0.8)
                        .foregroundStyle(self.theme.colors.surface, self.theme.colors.warning)
                        .symbolRenderingMode(.palette)
                        .padding(.trailing, self.theme.spacing.sm)
                }
            }
        }
    }
}

// MARK: - Convenience Initializers

extension AIFeatureButton {
    /// Creates an inline sparkles button for AI features
    public static func sparkles(
        size: Size = .small,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        onDisabledTap: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) -> AIFeatureButton {
        AIFeatureButton(
            icon: "sparkles",
            size: size,
            style: .inline,
            isEnabled: isEnabled,
            isLoading: isLoading,
            onDisabledTap: onDisabledTap,
            action: action
        )
    }

    /// Creates a generation button with wand icon
    public static func generate(
        title: String = "Generate",
        size: Size = .medium,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        onDisabledTap: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) -> AIFeatureButton {
        AIFeatureButton(
            icon: "wand.and.stars",
            title: title,
            size: size,
            style: .standard,
            isEnabled: isEnabled,
            isLoading: isLoading,
            onDisabledTap: onDisabledTap,
            action: action
        )
    }
}

// MARK: - AIFeatureButton_Previews

struct AIFeatureButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("AI Feature Buttons").font(.headline)

            Divider()

            // Inline styles
            Text("Inline Styles").font(.caption)
            HStack(spacing: 20) {
                AIFeatureButton.sparkles(size: .small) { }
                AIFeatureButton.sparkles(size: .medium) { }
                AIFeatureButton.sparkles(size: .large) { }
            }

            Divider()

            // Compact styles
            Text("Compact Styles").font(.caption)
            VStack(spacing: 10) {
                AIFeatureButton(title: "Analyze", size: .small, style: .compact) { }
                AIFeatureButton(title: "Generate", size: .medium, style: .compact) { }
                AIFeatureButton(title: "AI Coach", size: .large, style: .compact) { }
            }

            Divider()

            // Standard styles
            Text("Standard Styles").font(.caption)
            VStack(spacing: 10) {
                AIFeatureButton.generate(size: .small) { }
                AIFeatureButton.generate(title: "Generate Workout", size: .medium) { }
                AIFeatureButton.generate(title: "Create with AI", size: .large) { }
            }

            Divider()

            // States
            Text("States").font(.caption)
            VStack(spacing: 10) {
                AIFeatureButton.generate(title: "Enabled", isEnabled: true) { }
                AIFeatureButton.generate(title: "Disabled", isEnabled: false) { }
                AIFeatureButton.generate(title: "Loading", isLoading: true) { }
            }
        }
        .padding()
        .environment(\.theme, DefaultTheme())
    }
}
