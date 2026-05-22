import SwiftUI

// MARK: - PremiumFormSection

/// A premium card-based form section with header and subtle depth
/// Provides visual grouping and hierarchy for form content
public struct PremiumFormSection<Content: View>: View {
    // MARK: Lifecycle

    public init(
        title: String? = nil,
        icon: String? = nil,
        isSystemIcon: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
            if let title {
                HStack(spacing: self.theme.spacing.xs) {
                    if let icon {
                        AppIconView(name: icon, isSystemIcon: self.isSystemIcon)
                            .frame(width: 17, height: 17)
                            .foregroundColor(self.theme.colors.textSecondary)
                            .accessibilityHidden(true)
                    }

                    Text(title)
                        .font(self.theme.typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(self.theme.colors.textSecondary)
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.horizontal, self.theme.spacing.xs)
            }

            VStack(spacing: self.theme.spacing.md) {
                self.content()
            }
            .padding(self.theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.large)
                    .fill(self.theme.colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.large)
                    .strokeBorder(self.theme.colors.surface3.opacity(0.5), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 2
            )
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let title: String?
    private let icon: String?
    private let isSystemIcon: Bool
    private let content: () -> Content
}
