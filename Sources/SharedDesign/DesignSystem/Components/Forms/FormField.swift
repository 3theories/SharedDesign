import SwiftUI

// MARK: - FormField

/// A reusable form field component with icon and title
public struct FormField<Content: View>: View {
    // MARK: Lifecycle

    public init(
        icon: String = "",
        title: String = "",
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: self.theme.spacing.sm) {
            if !self.icon.isEmpty {
                Text(self.icon)
                    .font(self.theme.typography.title3)
                    .accessibilityHidden(true)
            }

            if !self.title.isEmpty {
                Text(self.title)
                    .font(self.theme.typography.body)
                    .foregroundColor(self.theme.colors.textPrimary)
            }

            if !self.title.isEmpty || !self.icon.isEmpty {
                Spacer()
            }

            self.content()
        }
        .padding(self.theme.spacing.md)
        .frame(minHeight: 44)
        .background(self.theme.colors.surface)
        .cornerRadius(self.theme.sizing.cornerRadius.medium)
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let icon: String
    private let title: String
    private let content: () -> Content
}

// MARK: - FormSection

/// A grouped form field section
public struct FormSection<Content: View>: View {
    // MARK: Lifecycle

    public init(
        title: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.xs) {
            if let title {
                Text(title)
                    .font(self.theme.typography.caption1)
                    .foregroundColor(self.theme.colors.textSecondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, self.theme.spacing.md)
            }

            VStack(spacing: 1) {
                self.content()
            }
            .background(self.theme.colors.surface)
            .cornerRadius(self.theme.sizing.cornerRadius.medium)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let title: String?
    private let content: () -> Content
}

#if DEBUG
    struct FormField_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: 20) {
                FormField(icon: "👤", title: "Name") {
                    TextField("Enter name", text: .constant(""))
                        .multilineTextAlignment(.trailing)
                }

                FormField(icon: "📧", title: "Email") {
                    TextField("Enter email", text: .constant(""))
                        .multilineTextAlignment(.trailing)
                }

                FormSection(title: "Settings") {
                    FormField(icon: "🔔", title: "Notifications") {
                        Toggle(isOn: .constant(true)) { EmptyView() }
                    }

                    FormField(icon: "🌙", title: "Dark Mode") {
                        Toggle(isOn: .constant(false)) { EmptyView() }
                    }
                }
            }
            .padding()
            .environment(\.theme, DefaultTheme())
        }
    }
#endif
