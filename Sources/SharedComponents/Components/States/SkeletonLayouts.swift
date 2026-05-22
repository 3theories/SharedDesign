import SwiftUI

// MARK: - SkeletonMetricCard

/// Skeleton matching SharedMetricCard layout
public struct SkeletonMetricCard: View {
    // MARK: Lifecycle

    public init(style: MetricCardSkeletonStyle = .standard) {
        self.style = style
    }

    // MARK: Public

    public enum MetricCardSkeletonStyle {
        case compact
        case standard
        case withChart
        case withProgress
    }

    public var body: some View {
        Group {
            switch self.style {
            case .compact:
                self.compactContent
            case .standard:
                self.standardContent
            case .withChart:
                self.chartContent
            case .withProgress:
                self.progressContent
            }
        }
        .background(self.theme.colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
    }

    // MARK: Internal

    let style: MetricCardSkeletonStyle

    // MARK: Private

    @Environment(\.theme) private var theme

    private var compactContent: some View {
        HStack(spacing: self.theme.spacing.sm) {
            SkeletonShape(.circle, size: .iconMedium)
            VStack(alignment: .leading, spacing: 4) {
                SkeletonShape.caption(widthFraction: 0.4)
                SkeletonShape.body(widthFraction: 0.6)
            }
            Spacer()
        }
        .padding(self.theme.spacing.sm)
    }

    private var standardContent: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
            HStack(spacing: self.theme.spacing.sm) {
                SkeletonShape(.circle, size: .iconMedium)
                SkeletonShape.caption(widthFraction: 0.3)
                Spacer()
            }
            SkeletonShape.title(widthFraction: 0.5)
            SkeletonShape.caption(widthFraction: 0.4)
        }
        .padding(self.theme.spacing.md)
    }

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
            HStack(spacing: self.theme.spacing.sm) {
                SkeletonShape(.circle, size: .iconMedium)
                SkeletonShape.caption(widthFraction: 0.3)
                Spacer()
            }
            SkeletonShape.title(widthFraction: 0.4)
            SkeletonShape.card(height: 35)
        }
        .padding(self.theme.spacing.md)
    }

    private var progressContent: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
            SkeletonShape.caption(widthFraction: 0.3)
            SkeletonShape.title(widthFraction: 0.5)
            SkeletonShape.caption(widthFraction: 0.4)
            SkeletonShape.textLine(height: 4, widthFraction: 0.7)
        }
        .padding(.vertical, self.theme.spacing.sm)
        .padding(.horizontal, self.theme.spacing.md)
        .background(self.theme.colors.surface3.opacity(0.3))
    }
}

// MARK: - SkeletonMacroRow

/// Skeleton matching SharedMacroCard row layout
public struct SkeletonMacroRow: View {
    // MARK: Lifecycle

    public init(count: Int = 3) {
        self.count = count
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: self.theme.spacing.sm) {
            ForEach(0..<self.count, id: \.self) { _ in
                VStack(alignment: .leading, spacing: self.theme.spacing.xs) {
                    SkeletonShape.caption(widthFraction: 0.5)
                    SkeletonShape.title(widthFraction: 0.7)
                    SkeletonShape.caption(widthFraction: 0.4)
                    SkeletonShape.textLine(height: 4, widthFraction: 1.0)
                }
                .padding(self.theme.spacing.sm)
                .background(self.theme.colors.surface3.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small))
            }
        }
    }

    // MARK: Internal

    let count: Int

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - SkeletonDateStrip

/// Skeleton for horizontal date picker strip
public struct SkeletonDateStrip: View {
    // MARK: Lifecycle

    public init(dayCount: Int = 7) {
        self.dayCount = dayCount
    }

    // MARK: Public

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: self.theme.spacing.sm) {
                ForEach(0..<self.dayCount, id: \.self) { _ in
                    VStack(spacing: self.theme.spacing.xs) {
                        SkeletonShape.textLine(height: 12, widthFraction: 1.0)
                        SkeletonShape(.circle, size: .custom(width: 36, height: 36))
                    }
                    .frame(width: 50)
                }
            }
            .padding(.horizontal, self.theme.spacing.md)
        }
    }

    // MARK: Internal

    let dayCount: Int

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - SkeletonMealCard

/// Skeleton for meal/recipe cards
public struct SkeletonMealCard: View {
    // MARK: Lifecycle

    public init(showImage: Bool = true, showMacros: Bool = true) {
        self.showImage = showImage
        self.showMacros = showMacros
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if self.showImage {
                SkeletonShape.image(height: 160, cornerRadius: 0)
            }

            VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
                SkeletonShape.title(widthFraction: 0.8)
                SkeletonShape.body(widthFraction: 0.5)

                if self.showMacros {
                    HStack(spacing: self.theme.spacing.sm) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonShape.chip(width: 60, height: 24)
                        }
                    }
                }
            }
            .padding(self.theme.spacing.md)
        }
        .background(self.theme.colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
    }

    // MARK: Internal

    let showImage: Bool
    let showMacros: Bool

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - SkeletonWorkoutCard

/// Skeleton for workout cards
public struct SkeletonWorkoutCard: View {
    // MARK: Lifecycle

    public init(showExercises: Bool = true) {
        self.showExercises = showExercises
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.md) {
            // Header
            HStack(spacing: self.theme.spacing.md) {
                SkeletonShape(.rect, size: .custom(width: 56, height: 56))
                VStack(alignment: .leading, spacing: self.theme.spacing.xs) {
                    SkeletonShape.title(widthFraction: 0.6)
                    SkeletonShape.caption(widthFraction: 0.4)
                }
                Spacer()
            }

            // Stats
            HStack(spacing: self.theme.spacing.lg) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 4) {
                        SkeletonShape.body(widthFraction: 0.8)
                        SkeletonShape.caption(widthFraction: 0.6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Exercise previews
            if self.showExercises {
                VStack(spacing: self.theme.spacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonRow(iconSize: 40, lineCount: 1, showTrailing: true)
                    }
                }
            }
        }
        .padding(self.theme.spacing.md)
        .background(self.theme.colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
    }

    // MARK: Internal

    let showExercises: Bool

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - SkeletonInsightCard

/// Skeleton for AI insight/summary cards
public struct SkeletonInsightCard: View {
    // MARK: Lifecycle

    public init(showIcon: Bool = true) {
        self.showIcon = showIcon
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.md) {
            HStack(spacing: self.theme.spacing.sm) {
                if self.showIcon {
                    SkeletonShape(.rect, size: .custom(width: 36, height: 36))
                }
                SkeletonShape.title(widthFraction: 0.5)
                Spacer()
            }

            SkeletonTextBlock(lineCount: 3, lineHeight: 14, lastLineFraction: 0.7)

            // Badges
            HStack(spacing: self.theme.spacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonShape.chip(width: CGFloat.random(in: 60...90), height: 28)
                }
            }
        }
        .padding(self.theme.spacing.md)
        .background(self.theme.colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
    }

    // MARK: Internal

    let showIcon: Bool

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - SkeletonListSection

/// Skeleton for a list section with header and items
public struct SkeletonListSection: View {
    // MARK: Lifecycle

    public init(
        itemCount: Int = 3,
        showHeader: Bool = true,
        showLeadingIcon: Bool = true
    ) {
        self.itemCount = itemCount
        self.showHeader = showHeader
        self.showLeadingIcon = showLeadingIcon
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
            if self.showHeader {
                HStack {
                    SkeletonShape.caption(widthFraction: 0.3)
                    Spacer()
                }
                .padding(.horizontal, self.theme.spacing.md)
            }

            VStack(spacing: 1) {
                ForEach(0..<self.itemCount, id: \.self) { _ in
                    SkeletonRow(showLeadingIcon: self.showLeadingIcon)
                        .padding(.horizontal, self.theme.spacing.md)
                        .padding(.vertical, self.theme.spacing.sm)
                        .background(self.theme.colors.surface1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
        }
    }

    // MARK: Internal

    let itemCount: Int
    let showHeader: Bool
    let showLeadingIcon: Bool

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - SkeletonStatsGrid

/// Skeleton for a grid of stat cards
public struct SkeletonStatsGrid: View {
    // MARK: Lifecycle

    public init(columns: Int = 2, rows: Int = 2) {
        self.columns = columns
        self.rows = rows
    }

    // MARK: Public

    public var body: some View {
        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: self.theme.spacing.sm), count: self.columns)

        LazyVGrid(columns: gridColumns, spacing: self.theme.spacing.sm) {
            ForEach(0..<(self.columns * self.rows), id: \.self) { _ in
                SkeletonMetricCard(style: .standard)
            }
        }
    }

    // MARK: Internal

    let columns: Int
    let rows: Int

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - SkeletonChart

/// Skeleton for chart/graph placeholders
public struct SkeletonChart: View {
    // MARK: Lifecycle

    public init(height: CGFloat = 200, showLegend: Bool = true) {
        self.height = height
        self.showLegend = showLegend
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.md) {
            // Chart area
            SkeletonShape.card(height: self.height)

            // Legend
            if self.showLegend {
                HStack(spacing: self.theme.spacing.md) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: self.theme.spacing.xs) {
                            SkeletonShape(.circle, size: .custom(width: 10, height: 10))
                            SkeletonShape.textLine(height: 12, widthFraction: 1.0)
                        }
                        .frame(width: 80)
                    }
                }
            }
        }
        .padding(self.theme.spacing.md)
        .background(self.theme.colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
    }

    // MARK: Internal

    let height: CGFloat
    let showLegend: Bool

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - Preview

#Preview("Skeleton Layouts") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Skeleton Layouts")
                .font(.title2.bold())

            // Metric Cards
            VStack(alignment: .leading, spacing: 8) {
                Text("Metric Cards").font(.headline)
                HStack(spacing: 12) {
                    SkeletonMetricCard(style: .compact)
                    SkeletonMetricCard(style: .standard)
                }
                SkeletonMetricCard(style: .withChart)
                    .frame(width: 180)
            }

            Divider()

            // Macro Row
            VStack(alignment: .leading, spacing: 8) {
                Text("Macro Row").font(.headline)
                SkeletonMacroRow()
            }

            Divider()

            // Date Strip
            VStack(alignment: .leading, spacing: 8) {
                Text("Date Strip").font(.headline)
                SkeletonDateStrip()
            }

            Divider()

            // Meal Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Meal Card").font(.headline)
                SkeletonMealCard()
            }

            Divider()

            // Workout Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Workout Card").font(.headline)
                SkeletonWorkoutCard()
            }

            Divider()

            // Insight Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Insight Card").font(.headline)
                SkeletonInsightCard()
            }

            Divider()

            // List Section
            VStack(alignment: .leading, spacing: 8) {
                Text("List Section").font(.headline)
                SkeletonListSection(itemCount: 3)
            }

            Divider()

            // Stats Grid
            VStack(alignment: .leading, spacing: 8) {
                Text("Stats Grid").font(.headline)
                SkeletonStatsGrid(columns: 2, rows: 2)
            }

            Divider()

            // Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Chart").font(.headline)
                SkeletonChart()
            }
        }
        .padding()
    }
    #if os(iOS)
    .background(Color(.systemGroupedBackground))
    #else
    .background(Color.gray.opacity(0.1))
    #endif
    .environment(\.theme, DefaultTheme())
}
