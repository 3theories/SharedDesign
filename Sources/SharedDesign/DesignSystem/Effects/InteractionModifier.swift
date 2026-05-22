import SwiftUI

// MARK: - InteractionStyle

/// Configuration for interactive element feedback
public struct InteractionStyle: Sendable {
    // MARK: Lifecycle

    public init(
        pressedScale: CGFloat = 0.97,
        pressedOpacity: Double = 1.0,
        hapticStyle: HapticStyle = .light,
        showHighlight: Bool = false,
        highlightColor: Color = .white.opacity(0.1),
        animation: Animation = .spring(response: 0.25, dampingFraction: 0.7)
    ) {
        self.pressedScale = pressedScale
        self.pressedOpacity = pressedOpacity
        self.hapticStyle = hapticStyle
        self.showHighlight = showHighlight
        self.highlightColor = highlightColor
        self.animation = animation
    }

    // MARK: Public

    /// Scale factor when pressed (1.0 = no change, 0.95 = 5% smaller)
    public let pressedScale: CGFloat

    /// Opacity when pressed
    public let pressedOpacity: Double

    /// Haptic feedback style on press
    public let hapticStyle: HapticStyle

    /// Whether to show a highlight overlay on press
    public let showHighlight: Bool

    /// Highlight color when pressed
    public let highlightColor: Color

    /// Animation for the press state transition
    public let animation: Animation
}

// MARK: - Preset Interaction Styles

extension InteractionStyle {
    /// Standard button interaction - subtle scale with light haptic
    public static let button = InteractionStyle(
        pressedScale: 0.97,
        pressedOpacity: 0.9,
        hapticStyle: .light
    )

    /// Card interaction - minimal scale with medium haptic
    public static let card = InteractionStyle(
        pressedScale: 0.98,
        pressedOpacity: 1.0,
        hapticStyle: .medium,
        showHighlight: true
    )

    /// List item interaction - no scale, just haptic and highlight
    public static let listItem = InteractionStyle(
        pressedScale: 1.0,
        pressedOpacity: 0.7,
        hapticStyle: .selection,
        showHighlight: true,
        highlightColor: .white.opacity(0.05)
    )

    /// Chip/tag interaction - more noticeable scale
    public static let chip = InteractionStyle(
        pressedScale: 0.95,
        pressedOpacity: 0.85,
        hapticStyle: .light
    )

    /// Icon button interaction - quick, snappy
    public static let iconButton = InteractionStyle(
        pressedScale: 0.92,
        pressedOpacity: 0.8,
        hapticStyle: .light,
        animation: .spring(response: 0.2, dampingFraction: 0.6)
    )

    /// Toggle/switch interaction
    public static let toggle = InteractionStyle(
        pressedScale: 0.96,
        pressedOpacity: 1.0,
        hapticStyle: .selection
    )

    /// Navigation element interaction
    public static let navigation = InteractionStyle(
        pressedScale: 0.98,
        pressedOpacity: 0.9,
        hapticStyle: .medium
    )

    /// Subtle interaction for secondary elements
    public static let subtle = InteractionStyle(
        pressedScale: 0.99,
        pressedOpacity: 0.85,
        hapticStyle: .soft
    )

    /// None - no visual feedback (haptic only)
    public static let hapticOnly = InteractionStyle(
        pressedScale: 1.0,
        pressedOpacity: 1.0,
        hapticStyle: .light,
        showHighlight: false
    )
}

// MARK: - PressStateModifier

/// View modifier that only provides press state feedback without an action
/// Use this when you need press feedback on a view that already has its own action handling
public struct PressStateModifier: ViewModifier {
    // MARK: Lifecycle

    public init(style: InteractionStyle = .button) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        content
            .scaleEffect(self.isPressed ? self.style.pressedScale : 1.0)
            .opacity(self.isPressed ? self.style.pressedOpacity : 1.0)
            .overlay(
                Group {
                    if self.style.showHighlight && self.isPressed {
                        self.style.highlightColor
                    }
                }
            )
            .animation(self.style.animation, value: self.isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !self.isPressed {
                            self.isPressed = true
                            HapticManager.shared.trigger(self.style.hapticStyle)
                        }
                    }
                    .onEnded { _ in
                        self.isPressed = false
                    }
            )
    }

    // MARK: Internal

    let style: InteractionStyle

    // MARK: Private

    @State private var isPressed = false
}

// MARK: - View Extensions

extension View {
    /// Add press state feedback only (for views with existing actions)
    /// - Parameter style: The interaction style to apply
    /// - Returns: A view with press state feedback
    public func pressState(_ style: InteractionStyle = .button) -> some View {
        modifier(PressStateModifier(style: style))
    }
}

// MARK: - InteractiveButtonStyle

/// A button style that applies interaction feedback
public struct InteractiveButtonStyle: ButtonStyle {
    // MARK: Lifecycle

    public init(_ style: InteractionStyle = .button) {
        self.interactionStyle = style
    }

    // MARK: Public

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? self.interactionStyle.pressedScale : 1.0)
            .opacity(configuration.isPressed ? self.interactionStyle.pressedOpacity : 1.0)
            .overlay(
                Group {
                    if self.interactionStyle.showHighlight && configuration.isPressed {
                        self.interactionStyle.highlightColor
                    }
                }
            )
            .animation(self.interactionStyle.animation, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.trigger(self.interactionStyle.hapticStyle)
                }
            }
    }

    // MARK: Internal

    let interactionStyle: InteractionStyle
}

extension ButtonStyle where Self == InteractiveButtonStyle {
    /// Interactive button style with default settings
    public static var interactive: InteractiveButtonStyle {
        InteractiveButtonStyle()
    }

    /// Interactive button style with custom settings
    public static func interactive(_ style: InteractionStyle) -> InteractiveButtonStyle {
        InteractiveButtonStyle(style)
    }
}
