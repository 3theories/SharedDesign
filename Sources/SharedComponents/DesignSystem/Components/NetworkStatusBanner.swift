import SwiftUI

// MARK: - NetworkStatusBanner

/// A banner component that displays network connectivity status
public struct NetworkStatusBanner: View {
    // MARK: Lifecycle

    public init(
        isVisible: Bool,
        message: String,
        type: BannerType,
        onDismiss: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil,
        autoDismissDelay: TimeInterval? = nil
    ) {
        self.isVisible = isVisible
        self.message = message
        self.type = type
        self.onDismiss = onDismiss
        self.onRetry = onRetry
        self.autoDismissDelay = autoDismissDelay
    }

    // MARK: Public

    public enum BannerType: Equatable {
        case noConnection
        case serverUnreachable
        case reconnecting
        case connected // New success state
        case custom(icon: String, color: KeyPath<ColorTokens, Color>)

        // MARK: Public

        public static func == (lhs: BannerType, rhs: BannerType) -> Bool {
            switch (lhs, rhs) {
            case (.noConnection, .noConnection),
                 (.serverUnreachable, .serverUnreachable),
                 (.reconnecting, .reconnecting),
                 (.connected, .connected):
                true
            case let (.custom(lhsIcon, _), .custom(rhsIcon, _)):
                lhsIcon == rhsIcon
            default:
                false
            }
        }

        // MARK: Internal

        var icon: String {
            switch self {
            case .noConnection:
                "wifi.slash"
            case .serverUnreachable:
                "exclamationmark.icloud.fill"
            case .reconnecting:
                "arrow.triangle.2.circlepath"
            case .connected:
                "checkmark.circle.fill"
            case let .custom(icon, _):
                icon
            }
        }

        func color(_ theme: Theme) -> Color {
            switch self {
            case .noConnection:
                theme.colors.error
            case .serverUnreachable:
                Color(red: 1.0, green: 0.75, blue: 0.0) // Orange/amber color
            case .reconnecting:
                theme.colors.info
            case .connected:
                theme.colors.success
            case let .custom(_, colorPath):
                theme.colors[keyPath: colorPath]
            }
        }

        func backgroundColor(_ theme: Theme) -> Color {
            switch self {
            case .noConnection:
                theme.colors.error
            case .serverUnreachable:
                Color(red: 1.0, green: 0.75, blue: 0.0) // Orange/amber background
            case .reconnecting:
                theme.colors.info
            case .connected:
                theme.colors.success
            case let .custom(_, colorPath):
                theme.colors[keyPath: colorPath]
            }
        }
    }

    public var body: some View {
        Group {
            if self.isVisible {
                self.bannerContent
                    .onAppear {
                        // Reset states when appearing
                        self.isExpanded = true
                        self.dragOffset = 0

                        if let delay = autoDismissDelay {
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                withAnimation(.spring(response: 0.3)) {
                                    self.onDismiss?()
                                }
                            }
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: self.isVisible)
                    .offset(y: self.dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height < 0 {
                                    self.dragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height < -20 {
                                    withAnimation(.spring(response: 0.3)) {
                                        self.onDismiss?()
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3)) {
                                        self.dragOffset = 0
                                    }
                                }
                            }
                    )
            }
        }
    }

    // MARK: Internal

    let isVisible: Bool
    let message: String
    let type: BannerType
    let onDismiss: (() -> Void)?
    let onRetry: (() -> Void)?
    let autoDismissDelay: TimeInterval?

    // MARK: Private

    @Environment(\.theme) private var theme

    @State private var isExpanded: Bool = true
    @State private var dragOffset: CGFloat = 0

    private var bannerContent: some View {
        HStack(spacing: self.theme.spacing.sm) {
            // Icon with subtle animation
            Image(systemName: self.type.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(self.type == .connected ? .white : Color.black.opacity(0.8))
                .frame(width: 28, height: 28)
                .rotationEffect(self.type == .reconnecting ? .degrees(360) : .zero)
                .animation(
                    self.type == .reconnecting
                        ? Animation.linear(duration: 2).repeatForever(autoreverses: false)
                        : .default,
                    value: self.type
                )
                .scaleEffect(self.type == .connected ? 1.1 : 1.0)

            // Message
            Text(self.message)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(self.type == .connected ? .white : Color.black.opacity(0.85))
                .lineLimit(1)

            Spacer(minLength: self.theme.spacing.xs)

            // Action buttons
            HStack(spacing: self.theme.spacing.sm) {
                // Retry button if available
                if let onRetry, type != .connected {
                    Button(action: onRetry) {
                        Text(String(
                            localized: "network.banner.retry",
                            defaultValue: "Retry",
                            bundle: .module,
                            comment: "Network status banner retry button"
                        ))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, self.theme.spacing.md)
                        .padding(.vertical, self.theme.spacing.xs)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.2))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Dismiss button
                if self.onDismiss != nil {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            self.isExpanded = false
                            self.onDismiss?()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(self.type == .connected ? .white.opacity(0.9) : Color.black.opacity(0.6))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(self.type == .connected ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, self.theme.spacing.md)
        .padding(.vertical, self.theme.spacing.sm)
        .frame(minHeight: 56)
        .background(
            Group {
                if self.type == .connected {
                    // Success gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.8, blue: 0.4),
                            Color(red: 0.3, green: 0.85, blue: 0.5)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    // Error/warning solid background
                    self.type.backgroundColor(self.theme)
                }
            }
            .edgesIgnoringSafeArea(.horizontal)
        )
    }
}

// MARK: - NetworkStatusBannerModifier

public struct NetworkStatusBannerModifier: ViewModifier {
    @Environment(\.theme) private var theme

    let isVisible: Bool
    let message: String
    let type: NetworkStatusBanner.BannerType
    let onDismiss: (() -> Void)?
    let onRetry: (() -> Void)?
    let autoDismissDelay: TimeInterval?

    public func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            // Main content pushed down when banner is shown
            content
                .offset(y: self.isVisible ? 56 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: self.isVisible)

            // Network status banner overlay
            NetworkStatusBanner(
                isVisible: self.isVisible,
                message: self.message,
                type: self.type,
                onDismiss: self.onDismiss,
                onRetry: self.onRetry,
                autoDismissDelay: self.autoDismissDelay
            )
        }
    }
}

// MARK: - View Extension

extension View {
    /// Shows a network status banner that pushes content down
    public func networkStatusBanner(
        isVisible: Bool,
        message: String,
        type: NetworkStatusBanner.BannerType,
        onDismiss: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil,
        autoDismissDelay: TimeInterval? = nil
    ) -> some View {
        modifier(NetworkStatusBannerModifier(
            isVisible: isVisible,
            message: message,
            type: type,
            onDismiss: onDismiss,
            onRetry: onRetry,
            autoDismissDelay: autoDismissDelay
        ))
    }
}

// MARK: - Preview

#if DEBUG
    struct NetworkStatusBanner_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                // Light mode previews
                VStack {
                    Spacer()

                    VStack(spacing: 20) {
                        NetworkStatusBanner(
                            isVisible: true,
                            message: "No internet connection",
                            type: .noConnection
                        ) { print("Dismissed") }

                        NetworkStatusBanner(
                            isVisible: true,
                            message: "Server unreachable",
                            type: .serverUnreachable,
                            onDismiss: { print("Dismissed") },
                            onRetry: { print("Retry") }
                        )

                        NetworkStatusBanner(
                            isVisible: true,
                            message: "Reconnecting...",
                            type: .reconnecting
                        )
                    }

                    Spacer()
                }
                .environment(\.theme, DefaultTheme(colorScheme: .light))
                .previewDisplayName("Light Mode")

                // Dark mode previews
                VStack {
                    Spacer()

                    VStack(spacing: 20) {
                        NetworkStatusBanner(
                            isVisible: true,
                            message: "No internet connection",
                            type: .noConnection
                        ) { print("Dismissed") }

                        NetworkStatusBanner(
                            isVisible: true,
                            message: "Server unreachable",
                            type: .serverUnreachable,
                            onDismiss: { print("Dismissed") },
                            onRetry: { print("Retry") }
                        )

                        NetworkStatusBanner(
                            isVisible: true,
                            message: "Reconnecting...",
                            type: .reconnecting
                        )
                    }

                    Spacer()
                }
                .background(Color.black)
                .environment(\.theme, DefaultTheme(colorScheme: .dark))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode")
            }
        }
    }
#endif
