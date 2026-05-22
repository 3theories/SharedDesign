import SwiftUI

// MARK: - RoundedButtonStyle

/// A button style that creates a rounded rectangle background with customizable colors
public struct RoundedButtonStyle: ButtonStyle {
    // MARK: Lifecycle

    public init(
        backgroundColor: Color,
        foregroundColor: Color = .white,
        cornerRadius: CGFloat = 12,
        height: CGFloat? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
        self.height = height
    }

    // MARK: Public

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(self.isEnabled ? self.foregroundColor : self.foregroundColor.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: self.height)
            .background(
                RoundedRectangle(cornerRadius: self.cornerRadius)
                    .fill(self.isEnabled ? self.backgroundColor : self.backgroundColor.opacity(0.6))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    // MARK: Internal

    let backgroundColor: Color
    let foregroundColor: Color
    let cornerRadius: CGFloat
    let height: CGFloat?

    // MARK: Private

    @Environment(\.isEnabled) private var isEnabled
}

// MARK: - PillButtonStyle

/// A button style that creates a pill/capsule shaped background
public struct PillButtonStyle: ButtonStyle {
    // MARK: Lifecycle

    public init(
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 8
    ) {
        self.backgroundColor = backgroundColor ?? Color.accentColor
        self.foregroundColor = foregroundColor ?? .white
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    // MARK: Public

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundColor(self.isEnabled ? self.foregroundColor : self.foregroundColor.opacity(0.6))
            .padding(.horizontal, self.horizontalPadding)
            .padding(.vertical, self.verticalPadding)
            .background(
                Capsule()
                    .fill(self.isEnabled ? self.backgroundColor : self.backgroundColor.opacity(0.6))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    // MARK: Internal

    let backgroundColor: Color
    let foregroundColor: Color
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    // MARK: Private

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.theme) private var theme
}

// MARK: - ToolbarButtonStyle

/// A button style optimized for toolbar buttons with icons
public struct ToolbarButtonStyle: ButtonStyle {
    // MARK: Lifecycle

    public init(tintColor: Color? = nil) {
        self.tintColor = tintColor ?? Color.accentColor
    }

    // MARK: Public

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(self.tintColor)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    // MARK: Internal

    let tintColor: Color

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - GhostButtonStyle

/// A minimal button style with no background, only shows on press
public struct GhostButtonStyle: ButtonStyle {
    // MARK: Lifecycle

    public init(pressedBackgroundColor: Color? = nil) {
        self.pressedBackgroundColor = pressedBackgroundColor ?? Color.gray.opacity(0.1)
    }

    // MARK: Public

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? self.pressedBackgroundColor : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    // MARK: Internal

    let pressedBackgroundColor: Color

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - FloatingActionButtonStyle

/// A circular floating action button style
public struct FloatingActionButtonStyle: ButtonStyle {
    // MARK: Lifecycle

    public init(
        size: CGFloat = 56,
        backgroundColor: Color = .accentColor,
        foregroundColor: Color = .white,
        shadowRadius: CGFloat = 8
    ) {
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.shadowRadius = shadowRadius
    }

    // MARK: Public

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .foregroundColor(self.isEnabled ? self.foregroundColor : self.foregroundColor.opacity(0.6))
            .frame(width: self.size, height: self.size)
            .background(
                Circle()
                    .fill(self.isEnabled ? self.backgroundColor : self.backgroundColor.opacity(0.6))
                    .shadow(
                        color: self.backgroundColor.opacity(0.3),
                        radius: self.shadowRadius,
                        y: self.shadowRadius / 2
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(AnimationConstants.Spring.bouncy, value: configuration.isPressed)
    }

    // MARK: Internal

    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let shadowRadius: CGFloat

    // MARK: Private

    @Environment(\.isEnabled) private var isEnabled
}

// MARK: - CardPressButtonStyle

/// A button style for card-like components that provides scale feedback
public struct CardPressButtonStyle: ButtonStyle {
    // MARK: Lifecycle

    public init(scale: CGFloat = AnimationConstants.Scale.cardPress, enableHaptic: Bool = false) {
        self.scale = scale
        self.enableHaptic = enableHaptic
    }

    // MARK: Public

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? self.scale : 1.0)
            .animation(AnimationConstants.Spring.stiff, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && self.enableHaptic {
                    HapticManager.shared.trigger(.light)
                }
            }
    }

    // MARK: Internal

    let scale: CGFloat
    let enableHaptic: Bool
}

// MARK: - Extension for Easy Access

extension Button {
    public func roundedStyle(
        backgroundColor: Color,
        foregroundColor: Color = .white,
        cornerRadius: CGFloat = 12,
        height: CGFloat? = nil
    ) -> some View {
        self.buttonStyle(
            RoundedButtonStyle(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                cornerRadius: cornerRadius,
                height: height
            )
        )
    }

    public func pillStyle(
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil
    ) -> some View {
        self.buttonStyle(
            PillButtonStyle(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor
            )
        )
    }

    public func toolbarStyle(tintColor: Color? = nil) -> some View {
        self.buttonStyle(ToolbarButtonStyle(tintColor: tintColor))
    }

    public func ghostStyle() -> some View {
        self.buttonStyle(GhostButtonStyle())
    }

    public func floatingActionStyle(
        size: CGFloat = 56,
        backgroundColor: Color = .accentColor
    ) -> some View {
        self.buttonStyle(
            FloatingActionButtonStyle(
                size: size,
                backgroundColor: backgroundColor
            )
        )
    }
}

// MARK: - ButtonStyles_Previews

struct ButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            // Rounded button style
            Button("Start Fast") { }
                .roundedStyle(backgroundColor: .orange, height: 44)

            Button("End Fast") { }
                .roundedStyle(backgroundColor: .red, height: 44)

            // Pill button style
            HStack {
                Button("Today") { }
                    .pillStyle(backgroundColor: .green)

                Button("Tomorrow") { }
                    .pillStyle(backgroundColor: .blue)
            }

            // Toolbar buttons
            HStack(spacing: 20) {
                Button(action: { }) {
                    Image(systemName: "ellipsis.circle")
                }
                .toolbarStyle(tintColor: .orange)

                Button(action: { }) {
                    Image(systemName: "pencil")
                }
                .toolbarStyle(tintColor: .blue)
            }

            // Ghost button
            Button("Cancel") { }
                .ghostStyle()
                .padding(.horizontal)

            // Floating action button
            Button(action: { }) {
                Image(systemName: "plus")
            }
            .floatingActionStyle()
        }
        .padding()
        .environment(\.theme, DefaultTheme())
    }
}
