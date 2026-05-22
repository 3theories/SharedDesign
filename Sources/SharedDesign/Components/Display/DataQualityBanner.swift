import SwiftUI

// MARK: - DataQualityBanner

/// A banner component that displays warnings when insights are based on limited data.
///
/// Use this component to inform users when analysis results may not be representative
/// due to insufficient data points.
///
/// Example usage:
/// ```swift
/// if let message = viewModel.dataQualityMessage {
///     DataQualityBanner(message: message)
/// }
/// ```
public struct DataQualityBanner: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Creates a data quality banner with the specified message.
    /// - Parameters:
    ///   - message: The primary warning message describing the data limitation.
    ///   - title: The banner title. Defaults to "Limited Data".
    ///   - suggestion: A helpful suggestion for the user. Defaults to suggesting a longer time period.
    public init(
        message: String,
        title: String? = nil,
        suggestion: String? = nil
    ) {
        self.message = message
        self.title = title ?? String(
            localized: "dataQuality.banner.title",
            defaultValue: "Limited Data",
            bundle: .module,
            comment: "Data quality warning banner title"
        )
        self.suggestion = suggestion ?? String(
            localized: "dataQuality.banner.suggestion",
            defaultValue: "Try selecting a longer time period for more accurate insights.",
            bundle: .module,
            comment: "Data quality warning banner suggestion"
        )
    }

    // MARK: Public

    // MARK: - Body

    public var body: some View {
        HStack(spacing: self.theme.spacing.md) {
            Image("info")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 17, height: 17)
                .foregroundColor(self.theme.colors.warning)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: self.theme.spacing.xxs) {
                Text(self.title)
                    .font(self.theme.typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(self.theme.colors.textPrimary)

                Text(self.message)
                    .font(self.theme.typography.footnote)
                    .foregroundColor(self.theme.colors.textSecondary)

                Text(self.suggestion)
                    .font(self.theme.typography.caption1)
                    .foregroundColor(self.theme.colors.textTertiary)
            }

            Spacer()
        }
        .padding(self.theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium, style: .continuous)
                .fill(self.theme.colors.warningBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium, style: .continuous)
                        .stroke(self.theme.colors.warning.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: Internal

    let message: String
    let title: String
    let suggestion: String

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - Preview

#if DEBUG && !os(watchOS)
    #Preview("Data Quality Banner - Default") {
        VStack(spacing: 16) {
            DataQualityBanner(
                message: "Average based on 2 days of data - limited data."
            )

            DataQualityBanner(
                message: "Only 1 session logged - may not be representative.",
                title: "Insufficient Data",
                suggestion: "Log more workouts for accurate trend analysis."
            )

            DataQualityBanner(
                message: "No meals logged this period."
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
#endif
