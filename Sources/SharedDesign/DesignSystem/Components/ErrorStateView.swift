import SwiftUI

/// A view for displaying error states with optional retry action
public struct ErrorStateView: View {
    // MARK: Lifecycle

    public init(
        title: String,
        message: String? = nil,
        icon: String = "exclamationmark.triangle",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        VStack(spacing: self.theme.spacing.lg) {
            // Error icon with background
            ZStack {
                Circle()
                    .fill(self.theme.colors.error.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: self.icon)
                    .font(self.theme.typography.largeTitle)
                    .foregroundColor(self.theme.colors.error)
                    .accessibilityHidden(true)
            }

            VStack(spacing: self.theme.spacing.sm) {
                Text(self.title)
                    .font(self.theme.typography.headline)
                    .foregroundColor(self.theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                if let message {
                    Text(message)
                        .font(self.theme.typography.body)
                        .foregroundColor(self.theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let action {
                Button(action: action) {
                    Text(L10n.string("common.action.try_again", defaultValue: "Try Again"))
                        .font(self.theme.typography.body.weight(.medium))
                        .foregroundColor(self.theme.colors.primary)
                        .padding(.horizontal, self.theme.spacing.lg)
                        .padding(.vertical, self.theme.spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                                .stroke(self.theme.colors.primary, lineWidth: 2)
                        )
                }
                .padding(.top, self.theme.spacing.sm)
            }
        }
        .padding(self.theme.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Internal

    let title: String
    let message: String?
    let icon: String
    let action: (() -> Void)?

    // MARK: Private

    @Environment(\.theme) private var theme
}

#Preview {
    ErrorStateView(
        title: "Something went wrong",
        message: "Please check your connection and try again"
    ) { print("Retry tapped") }
        .environment(\.theme, DefaultTheme())
}
