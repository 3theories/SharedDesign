import SwiftUI

// MARK: - MetricRow

/// A generic row component for displaying metric key-value pairs
public struct MetricRow: View {
    // MARK: Lifecycle

    public init(
        label: String,
        value: String,
        icon: String? = nil,
        isSystemIcon: Bool = true,
        iconColor: Color? = nil,
        valueColor: Color? = nil,
        accessory: Accessory? = nil
    ) {
        self.label = label
        self.value = value
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.iconColor = iconColor
        self.valueColor = valueColor
        self.accessory = accessory
    }

    // MARK: Public

    public enum Accessory {
        case chevron
        case info
        case badge(String, Color)
        case custom(AnyView)
    }

    public var body: some View {
        HStack(spacing: self.theme.spacing.sm) {
            // Optional icon
            if let icon {
                AppIconView(name: icon, isSystemIcon: self.isSystemIcon)
                    .font(.system(size: 17))
                    .frame(width: 20, height: 20)
                    .foregroundColor(self.iconColor ?? self.theme.colors.textSecondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)
            }

            // Label
            Text(self.label)
                .font(self.theme.typography.body)
                .foregroundColor(self.theme.colors.textPrimary)

            Spacer()

            // Value
            Text(self.value)
                .font(self.theme.typography.body.weight(.semibold))
                .foregroundColor(self.valueColor ?? self.theme.colors.textPrimary)

            // Optional accessory
            if let accessory {
                self.accessoryView(for: accessory)
            }
        }
        .padding(.vertical, self.theme.spacing.xs)
        .accessibilityElement(children: .combine)
    }

    // MARK: Internal

    let label: String
    let value: String
    let icon: String?
    let isSystemIcon: Bool
    let iconColor: Color?
    let valueColor: Color?
    let accessory: Accessory?

    // MARK: Private

    @Environment(\.theme) private var theme

    @ViewBuilder
    private func accessoryView(for accessory: Accessory) -> some View {
        switch accessory {
        case .chevron:
            Image(systemName: "chevron.right")
                .font(self.theme.typography.caption1)
                .foregroundColor(self.theme.colors.textTertiary)
                .accessibilityHidden(true)
        case .info:
            Image("info")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .foregroundColor(self.theme.colors.textSecondary)
                .accessibilityHidden(true)
        case let .badge(text, color):
            Text(text)
                .font(self.theme.typography.caption2.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, self.theme.spacing.xs)
                .padding(.vertical, self.theme.spacing.xxs)
                .background(Capsule().fill(color))
        case let .custom(view):
            view
        }
    }
}

// MARK: - MetricGroup

/// A grouped container for MetricRow items
public struct MetricGroup<Content: View>: View {
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
                    .padding(.horizontal, self.theme.spacing.md)
                    .padding(.bottom, self.theme.spacing.xxs)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(spacing: 0) {
                self.content()
            }
            .padding(.horizontal, self.theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                    .fill(self.theme.colors.surface2)
            )
        }
    }

    // MARK: Internal

    let title: String?
    let content: () -> Content

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - Preview

#if DEBUG
    struct MetricRow_Previews: PreviewProvider {
        static var previews: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // Single rows
                    VStack(spacing: 8) {
                        Text("Individual Rows")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        MetricRow(
                            label: "Total Distance",
                            value: "5.2 km",
                            icon: "location.fill",
                            iconColor: .blue
                        )

                        MetricRow(
                            label: "Calories Burned",
                            value: "425",
                            icon: "flame.fill",
                            iconColor: .orange,
                            valueColor: .orange
                        )

                        MetricRow(
                            label: "Workout Type",
                            value: "Strength",
                            accessory: .chevron
                        )

                        MetricRow(
                            label: "Status",
                            value: "Active",
                            accessory: .badge("PRO", .orange)
                        )
                    }

                    // Grouped metrics
                    MetricGroup(title: "PERFORMANCE METRICS") {
                        MetricRow(
                            label: "Average Speed",
                            value: "12.5 km/h",
                            icon: "speedometer"
                        )
                        Divider()
                        MetricRow(
                            label: "Max Heart Rate",
                            value: "165 bpm",
                            icon: "heart.fill",
                            iconColor: .red
                        )
                        Divider()
                        MetricRow(
                            label: "Recovery Time",
                            value: "48 hours",
                            icon: "duration",
                            isSystemIcon: false,
                            iconColor: .green
                        )
                    }

                    // Another group without title
                    MetricGroup {
                        MetricRow(
                            label: "Weekly Goal",
                            value: "4/5",
                            accessory: .info
                        )
                        Divider()
                        MetricRow(
                            label: "Streak",
                            value: "7 days",
                            icon: "flame.fill",
                            iconColor: .orange,
                            accessory: .badge("New Record!", .green)
                        )
                    }
                }
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .environment(\.theme, DefaultTheme())
        }
    }
#endif
