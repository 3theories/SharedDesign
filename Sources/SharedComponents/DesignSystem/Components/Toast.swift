import SwiftUI

#if !os(watchOS)

    /// Toast notification types
    public enum ToastType {
        case success
        case warning
        case error
        case info

        // MARK: Internal

        var icon: String {
            switch self {
            case .success: "check"
            case .warning: "exclamationmark.triangle.fill"
            case .error: "cancel"
            case .info: "info"
            }
        }

        var isSystemIcon: Bool {
            switch self {
            case .success, .error, .info: false
            case .warning: true
            }
        }

        var color: (Theme) -> Color {
            switch self {
            case .success: { $0.colors.success }
            case .warning: { $0.colors.warning }
            case .error: { $0.colors.error }
            case .info: { $0.colors.info }
            }
        }

        var accessibilityPrefix: String {
            switch self {
            case .success: "Success"
            case .warning: "Warning"
            case .error: "Error"
            case .info: "Information"
            }
        }
    }

    /// Toast duration options
    public enum ToastDuration {
        case short // 2 seconds
        case medium // 4 seconds
        case long // 6 seconds
        case persistent // Manual dismiss only

        // MARK: Internal

        var timeInterval: TimeInterval? {
            switch self {
            case .short: 2.0
            case .medium: 4.0
            case .long: 6.0
            case .persistent: nil
            }
        }
    }

    /// Action for toast notifications
    extension Toast {
        public struct Action {
            // MARK: Lifecycle

            public init(title: String, action: @escaping () -> Void) {
                self.title = title
                self.action = action
            }

            // MARK: Public

            public let title: String
            public let action: () -> Void
        }
    }

    /// Enhanced toast notification with actions and dismissibility
    public struct Toast: View {
        // MARK: Lifecycle

        public init(
            message: String,
            type: ToastType = .info,
            duration: ToastDuration = .medium,
            onDismiss: (() -> Void)? = nil,
            action: Action? = nil
        ) {
            self.message = message
            self.type = type
            self.duration = duration
            self.onDismiss = onDismiss
            self.action = action
        }

        // MARK: Public

        public var body: some View {
            HStack(spacing: self.theme.spacing.sm) {
                Group {
                    if self.type.isSystemIcon {
                        Image(systemName: self.type.icon)
                    } else {
                        Image(self.type.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                }
                .foregroundColor(self.type.color(self.theme))

                Text(self.message)
                    .font(self.theme.typography.body)
                    .foregroundColor(self.theme.colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Action and dismiss buttons container
                HStack(spacing: self.theme.spacing.md) {
                    // Action button
                    if let action {
                        Button(action.title) {
                            action.action()
                        }
                        .font(self.theme.typography.caption1)
                        .foregroundColor(self.type.color(self.theme))
                        .padding(.horizontal, self.theme.spacing.xs)
                        .padding(.vertical, self.theme.spacing.xxs)
                    }

                    // Dismiss button
                    if self.onDismiss != nil {
                        Button {
                            self.onDismiss?()
                        } label: {
                            Image("cancel")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12, height: 12)
                                .foregroundColor(self.theme.colors.textSecondary)
                        }
                        .padding(.horizontal, self.theme.spacing.xs)
                        .padding(.vertical, self.theme.spacing.xxs)
                        .accessibilityLabel("Dismiss notification")
                    }
                }
            }
            .padding(self.theme.spacing.md)
            .background(self.theme.colors.surface1)
            .overlay(
                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                    .stroke(self.theme.colors.borderSecondary, lineWidth: 1)
            )
            .cornerRadius(self.theme.sizing.cornerRadius.medium)
            .shadow(self.theme.shadows.medium)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isStaticText)
        }

        // MARK: Internal

        let message: String
        let type: ToastType
        let duration: ToastDuration
        let onDismiss: (() -> Void)?
        let action: Action?

        // MARK: Private

        @Environment(\.theme) private var theme
    }

    /// View modifier for showing toast notifications
    public struct ToastModifier: ViewModifier {
        // MARK: Lifecycle

        public func body(content: Content) -> some View {
            ZStack {
                content

                if self.isShowing {
                    VStack {
                        Toast(
                            message: self.message,
                            type: self.type,
                            duration: self.duration,
                            onDismiss: {
                                withAnimation {
                                    self.isShowing = false
                                }
                                self.onDismiss?()
                            },
                            action: self.action
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))

                        Spacer()
                    }
                    .animation(.spring(), value: self.isShowing)
                    .onAppear {
                        if let timeInterval = duration.timeInterval {
                            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
                                withAnimation {
                                    self.isShowing = false
                                }
                                self.onDismiss?()
                            }
                        }
                    }
                    .onAppear {
                        AccessibilityAnnouncement.announce("\(self.type.accessibilityPrefix): \(self.message)")
                    }
                }
            }
        }

        // MARK: Internal

        @Binding var isShowing: Bool

        let message: String
        let type: ToastType
        let duration: ToastDuration
        let onDismiss: (() -> Void)?
        let action: Toast.Action?
    }

    extension View {
        /// Show a toast notification
        public func toast(
            isShowing: Binding<Bool>,
            message: String,
            type: ToastType = .info,
            duration: ToastDuration = .medium,
            onDismiss: (() -> Void)? = nil,
            action: Toast.Action? = nil
        ) -> some View {
            modifier(ToastModifier(
                isShowing: isShowing,
                message: message,
                type: type,
                duration: duration,
                onDismiss: onDismiss,
                action: action
            ))
        }

        /// Legacy support - Show a toast notification with TimeInterval duration
        public func toast(
            isShowing: Binding<Bool>,
            message: String,
            type: ToastType = .info,
            duration: TimeInterval = 3.0
        ) -> some View {
            let toastDuration: ToastDuration =
                switch duration {
                case 0...2.5: .short
                case 2.5...5: .medium
                default: .long
                }

            return modifier(ToastModifier(
                isShowing: isShowing,
                message: message,
                type: type,
                duration: toastDuration,
                onDismiss: nil,
                action: nil
            ))
        }
    }

    #Preview("Light Mode") {
        VStack(spacing: 20) {
            Toast(message: "Success!", type: .success)
            Toast(message: "Warning message", type: .warning)
            Toast(
                message: "Error occurred with action",
                type: .error,
                onDismiss: { print("Dismissed") },
                action: Toast.Action(title: "Retry") { print("Retry") }
            )
            Toast(
                message: "Persistent info message",
                type: .info,
                duration: .persistent
            ) { print("Dismissed") }
        }
        .padding()
        #if canImport(UIKit) && !os(watchOS)
            .background(Color(UIColor.systemBackground))
        #else
            .background(Color(.systemBackground))
        #endif
            .environment(\.theme, DefaultTheme(colorScheme: .light))
            .environment(\.colorScheme, .light)
    }

    #Preview("Dark Mode") {
        VStack(spacing: 20) {
            Toast(message: "Success!", type: .success)
            Toast(message: "Warning message", type: .warning)
            Toast(
                message: "Error occurred with action",
                type: .error,
                onDismiss: { print("Dismissed") },
                action: Toast.Action(title: "Retry") { print("Retry") }
            )
            Toast(
                message: "Persistent info message",
                type: .info,
                duration: .persistent
            ) { print("Dismissed") }
        }
        .padding()
        .background(Color.black)
        .environment(\.theme, DefaultTheme(colorScheme: .dark))
        .environment(\.colorScheme, .dark)
    }

#endif // !os(watchOS)
