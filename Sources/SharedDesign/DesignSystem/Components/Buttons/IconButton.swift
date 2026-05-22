import SwiftUI

// MARK: - IconButton

/// A circular icon button component
public struct IconButton: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        icon: String,
        isSystemIcon: Bool = true,
        style: Style = .tinted,
        size: Size = .medium,
        color: KeyPath<ColorTokens, Color>? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        accessibilityLabel: String? = nil
    ) {
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.style = style
        self.size = size
        self.color = color
        self.isEnabled = isEnabled
        self.action = action
        self.accessibilityLabelText = accessibilityLabel
    }

    // MARK: Public

    // MARK: - Types

    public enum Style {
        case filled
        case tinted
        case ghost
    }

    public enum Size {
        case small
        case medium
        case large
    }

    // MARK: - Body

    public var body: some View {
        Button(action: {
            if self.isEnabled {
                HapticManager.shared.trigger(.light)
                self.action()
            }
        }) {
            ZStack {
                // Background
                self.backgroundView

                // Icon
                Group {
                    if self.isSystemIcon {
                        Image(systemName: self.icon)
                            .font(self.iconFont)
                    } else {
                        Image(self.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: self.iconSize, height: self.iconSize)
                    }
                }
                .foregroundColor(self.foregroundColor)
            }
            .frame(width: self.diameter, height: self.diameter)
        }
        .disabled(!self.isEnabled)
        .accessibilityLabel(self.accessibilityLabelText ?? self.icon)
        .scaleEffect(self.isPressed ? 0.9 : 1.0)
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

    private let icon: String
    private let isSystemIcon: Bool
    private let style: Style
    private let size: Size
    private let color: KeyPath<ColorTokens, Color>?
    private let isEnabled: Bool
    private let action: () -> Void
    private let accessibilityLabelText: String?

    private var foregroundColor: Color {
        switch self.style {
        case .filled:
            self.theme.colors.onPrimary
        case .tinted, .ghost:
            self.isEnabled ? self.buttonColor : self.theme.colors.onSurface.opacity(0.3)
        }
    }

    private var buttonColor: Color {
        if let color {
            return self.theme.colors[keyPath: color]
        }
        return self.theme.colors.primary
    }

    private var diameter: CGFloat {
        switch self.size {
        case .small:
            32
        case .medium:
            44
        case .large:
            56
        }
    }

    private var iconFont: Font {
        switch self.size {
        case .small:
            .system(size: 16, weight: .medium)
        case .medium:
            .system(size: 20, weight: .medium)
        case .large:
            .system(size: 24, weight: .medium)
        }
    }

    private var iconSize: CGFloat {
        switch self.size {
        case .small: 16
        case .medium: 20
        case .large: 24
        }
    }

    private var backgroundView: some View {
        Group {
            switch self.style {
            case .filled:
                Circle()
                    .fill(self.buttonColor)
                    .opacity(self.isEnabled ? 1 : 0.5)
            case .tinted:
                Circle()
                    .fill(self.buttonColor.opacity(0.15))
                    .opacity(self.isEnabled ? 1 : 0.5)
            case .ghost:
                Circle()
                    .fill(Color.clear)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension IconButton {
    /// Create a close button
    public static func close(
        style: Style = .ghost,
        size: Size = .medium,
        action: @escaping () -> Void
    ) -> IconButton {
        IconButton(
            icon: "cancel",
            isSystemIcon: false,
            style: style,
            size: size,
            action: action,
            accessibilityLabel: "Close"
        )
    }

    /// Create a back button
    public static func back(
        style: Style = .ghost,
        size: Size = .medium,
        action: @escaping () -> Void
    ) -> IconButton {
        IconButton(
            icon: "chevron.left",
            style: style,
            size: size,
            action: action,
            accessibilityLabel: "Back"
        )
    }

    /// Create a menu button
    public static func menu(
        style: Style = .ghost,
        size: Size = .medium,
        action: @escaping () -> Void
    ) -> IconButton {
        IconButton(
            icon: "line.3.horizontal",
            style: style,
            size: size,
            action: action,
            accessibilityLabel: "Menu"
        )
    }

    /// Create an add button
    public static func add(
        style: Style = .filled,
        size: Size = .medium,
        action: @escaping () -> Void
    ) -> IconButton {
        IconButton(
            icon: "plus",
            isSystemIcon: false,
            style: style,
            size: size,
            action: action,
            accessibilityLabel: "Add"
        )
    }
}

// MARK: - IconButton_Previews

struct IconButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                IconButton(icon: "heart", style: .filled) { }
                IconButton(icon: "heart", style: .tinted) { }
                IconButton(icon: "heart", style: .ghost) { }
            }

            HStack(spacing: 20) {
                IconButton(icon: "star", size: .small) { }
                IconButton(icon: "star", size: .medium) { }
                IconButton(icon: "star", size: .large) { }
            }

            HStack(spacing: 20) {
                IconButton(icon: "bell", color: \.success) { }
                IconButton(icon: "exclamationmark.triangle", color: \.warning) { }
                IconButton(icon: "xmark.circle", color: \.error) { }
            }

            HStack(spacing: 20) {
                IconButton.close { }
                IconButton.back { }
                IconButton.menu { }
                IconButton.add { }
            }
        }
        .padding()
        .environment(\.theme, DefaultTheme())
    }
}
