import SwiftUI

// MARK: - ActionButton

/// A prominent action button with customizable styling, used for primary actions
public struct ActionButton: View {
    // MARK: Lifecycle

    public init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        size: Size = .medium,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.action = action
    }

    // MARK: Public

    public enum Style {
        case primary // Solid orange background
        case secondary // Orange outline
        case success // Green background
        case danger // Red background
        case custom(background: Color, foreground: Color)

        // MARK: Internal

        var hasBorder: Bool {
            switch self {
            case .secondary:
                true
            default:
                false
            }
        }

        func backgroundColor(theme: Theme) -> Color {
            switch self {
            case .primary:
                theme.colors.primary
            case .secondary:
                Color.clear
            case .success:
                theme.colors.success
            case .danger:
                theme.colors.error
            case let .custom(background, _):
                background
            }
        }

        func foregroundColor(theme: Theme) -> Color {
            switch self {
            case .primary:
                .white
            case .secondary:
                theme.colors.primary
            case .success:
                .white
            case .danger:
                .white
            case let .custom(_, foreground):
                foreground
            }
        }
    }

    public enum Size {
        case small
        case medium
        case large

        // MARK: Internal

        var height: CGFloat {
            switch self {
            case .small: 36
            case .medium: 44
            case .large: 56
            }
        }

        var fontSize: Font {
            switch self {
            case .small: .subheadline
            case .medium: .body
            case .large: .title3
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: 14
            case .medium: 16
            case .large: 20
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: 8
            case .medium: 12
            case .large: 16
            }
        }
    }

    public var body: some View {
        Button(action: {
            if !self.isLoading {
                self.action()
            }
        }) {
            HStack(spacing: 8) {
                if self.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(
                            tint: self.style
                                .foregroundColor(theme: self.theme)
                        ))
                        .scaleEffect(0.8)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: self.size.iconSize))
                            .accessibilityHidden(true)
                    }

                    Text(self.title)
                        .font(self.size.fontSize.weight(.semibold))
                }
            }
            .frame(maxWidth: self.isFullWidth ? .infinity : nil)
            .frame(height: self.size.height)
            .padding(.horizontal, self.size.height / 2)
            .background(
                RoundedRectangle(cornerRadius: self.size.cornerRadius)
                    .fill(self.style.backgroundColor(theme: self.theme))
                    .overlay(
                        self.style.hasBorder
                            ? RoundedRectangle(cornerRadius: self.size.cornerRadius)
                                .stroke(self.theme.colors.primary, lineWidth: 2)
                            : nil
                    )
            )
            .foregroundColor(self.style.foregroundColor(theme: self.theme))
            .opacity(self.isEnabled && !self.isLoading ? 1 : 0.6)
            .scaleEffect(self.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: self.isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(self.isLoading || !self.isEnabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            self.isPressed = pressing
        } perform: { }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @State private var isPressed = false

    private let title: String
    private let icon: String?
    private let style: Style
    private let size: Size
    private let isFullWidth: Bool
    private let isLoading: Bool
    private let action: () -> Void
}

// MARK: - Shadow Extension

extension ActionButton {
    /// Add shadow to action button
    public func withShadow() -> some View {
        modifier(ActionButtonShadowModifier(style: self.style))
    }
}

// MARK: - ActionButtonShadowModifier

private struct ActionButtonShadowModifier: ViewModifier {
    // MARK: Lifecycle

    func body(content: Content) -> some View {
        content.shadow(
            color: self.style.backgroundColor(theme: self.theme).opacity(0.3),
            radius: 8,
            y: 4
        )
    }

    // MARK: Internal

    let style: ActionButton.Style

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - ActionButton_Previews

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Sizes
            ActionButton("Small Button", size: .small) { }
            ActionButton("Medium Button", icon: "arrow.right", size: .medium) { }
            ActionButton("Large Button", icon: "plus", size: .large) { }

            Divider()

            // Styles
            ActionButton("Primary", style: .primary) { }
            ActionButton("Secondary", style: .secondary) { }
            ActionButton("Success", icon: "checkmark", style: .success) { }
            ActionButton("Danger", icon: "trash", style: .danger) { }

            Divider()

            // States
            ActionButton("Loading Button", isLoading: true) { }
            ActionButton("Disabled Button", style: .primary) { }
                .disabled(true)

            // Full width
            ActionButton("Full Width Button", isFullWidth: true) { }
                .withShadow()
        }
        .padding()
        .environment(\.theme, DefaultTheme())
    }
}
