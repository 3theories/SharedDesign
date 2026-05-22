import SwiftUI

// MARK: - CircularIconButton

/// A circular button with an icon, commonly used in toolbars and action sheets
public struct CircularIconButton: View {
    // MARK: Lifecycle

    public init(
        icon: String,
        isSystemIcon: Bool = true,
        color: Color = .accentColor,
        size: Size = .medium,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.color = color
        self.size = size
        self.action = action
    }

    // MARK: Public

    public enum Size {
        case small // 32pt
        case medium // 40pt
        case large // 48pt

        // MARK: Internal

        var dimension: CGFloat {
            switch self {
            case .small: 32
            case .medium: 40
            case .large: 48
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: 16
            case .medium: 20
            case .large: 24
            }
        }
    }

    public var body: some View {
        Button(action: self.action) {
            ZStack {
                Circle()
                    .fill(self.color.opacity(0.2))
                    .frame(width: self.size.dimension, height: self.size.dimension)

                Group {
                    if self.isSystemIcon {
                        Image(systemName: self.icon)
                            .font(.system(size: self.size.iconSize, weight: .semibold))
                    } else {
                        Image(self.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: self.size.iconSize, height: self.size.iconSize)
                    }
                }
                .foregroundColor(self.isEnabled ? self.color : self.theme.colors.textDisabled)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(self.isEnabled ? 1 : AnimationConstants.Scale.buttonPress)
        .animation(AnimationConstants.Easing.quickOut, value: self.isEnabled)
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    private let icon: String
    private let isSystemIcon: Bool
    private let color: Color
    private let size: Size
    private let action: () -> Void
}

// MARK: - Convenience Initializers

extension CircularIconButton {
    /// Create a checkmark button
    public static func checkmark(
        color: Color = .green,
        size: Size = .medium,
        action: @escaping () -> Void
    ) -> CircularIconButton {
        CircularIconButton(
            icon: "check",
            isSystemIcon: false,
            color: color,
            size: size,
            action: action
        )
    }

    /// Create a close/cancel button
    public static func close(
        color: Color = .red,
        size: Size = .medium,
        action: @escaping () -> Void
    ) -> CircularIconButton {
        CircularIconButton(
            icon: "cancel",
            isSystemIcon: false,
            color: color,
            size: size,
            action: action
        )
    }

    /// Create an edit button
    public static func edit(
        color: Color = .accentColor,
        size: Size = .medium,
        action: @escaping () -> Void
    ) -> CircularIconButton {
        CircularIconButton(
            icon: "pencil",
            color: color,
            size: size,
            action: action
        )
    }
}

// MARK: - CircularIconButton_Previews

struct CircularIconButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                CircularIconButton(icon: "plus", color: .orange, size: .small) { }
                CircularIconButton(icon: "heart.fill", color: .red, size: .medium) { }
                CircularIconButton(icon: "bell", color: .blue, size: .large) { }
            }

            HStack(spacing: 20) {
                CircularIconButton.checkmark { }
                CircularIconButton.close { }
                CircularIconButton.edit { }
            }

            CircularIconButton(icon: "star", color: .yellow) { }
                .disabled(true)
        }
        .padding()
        .environment(\.theme, DefaultTheme())
    }
}
