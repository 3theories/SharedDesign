import SwiftUI

// MARK: - CalendarHeatmapView

/// Calendar heatmap view for streak tracking and achievement visualization
/// Inspired by Apple Health's calendar views with intensity-based coloring
public struct CalendarHeatmapView: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        data: [DayData],
        streakInfo: StreakInfo? = nil,
        title: String = "",
        subtitle: String? = nil,
        accentColor: Color = .green,
        showMonthHeaders: Bool = true,
        monthsToShow: Int? = nil,
        orientation: Orientation = .vertical,
        cellDimensions: CellDimensions = .default,
        style: Style = .full,
        timeRange: TimeRange = .quarter,
        onDayTapped: ((DayData) -> Void)? = nil
    ) {
        self.data = data.sorted { $0.date < $1.date }
        self.streakInfo = streakInfo
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.timeRange = timeRange
        // Use provided monthsToShow or derive from timeRange
        self.monthsToShow = monthsToShow ?? timeRange.monthsToShow
        // Hide month headers in minimal style or for day/week time ranges
        let hideHeadersForTimeRange = timeRange == .day || timeRange == .week
        self.showMonthHeaders = style == .minimal || hideHeadersForTimeRange ? false : showMonthHeaders
        self.orientation = orientation
        self.cellDimensions = cellDimensions
        self.style = style
        self.onDayTapped = onDayTapped
    }

    // MARK: Public

    // MARK: - Data Types

    public struct DayData: Identifiable, Hashable {
        // MARK: Lifecycle

        public init(date: Date, value: Double, maxValue: Double, isGoalMet: Bool = false, category: String? = nil) {
            self.date = date
            self.value = value
            self.maxValue = maxValue
            self.isGoalMet = isGoalMet
            self.category = category
        }

        // MARK: Public

        public let id = UUID()
        public let date: Date
        public let value: Double
        public let maxValue: Double
        public let isGoalMet: Bool
        public let category: String?

        /// Intensity from 0.0 to 1.0 based on value relative to max
        public var intensity: Double {
            guard self.maxValue > 0 else {
                return 0
            }
            return min(1.0, self.value / self.maxValue)
        }

        /// Color based on intensity and goal achievement
        public func color(for theme: Color) -> Color {
            if self.value == 0 {
                // Empty days: subtle dark background
                Color.gray.opacity(0.15)
            } else if self.isGoalMet {
                // Goal met: vibrant color
                theme
            } else {
                // Partial progress: theme color with intensity-based opacity
                theme.opacity(0.3 + (self.intensity * 0.5))
            }
        }
    }

    public struct StreakInfo {
        // MARK: Lifecycle

        public init(currentStreak: Int, longestStreak: Int, totalDays: Int, streakDates: [Date]) {
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.totalDays = totalDays
            self.streakDates = streakDates
        }

        // MARK: Public

        public let currentStreak: Int
        public let longestStreak: Int
        public let totalDays: Int
        public let streakDates: [Date]
    }

    // MARK: - Time Range

    /// Time range for the calendar heatmap display
    public enum TimeRange: String, CaseIterable, Sendable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"

        // MARK: Public

        /// Number of days in the time range
        public var days: Int {
            switch self {
            case .day: 1
            case .week: 7
            case .month: 30
            case .quarter: 90
            case .year: 365
            }
        }

        /// Number of months to show in the calendar
        public var monthsToShow: Int {
            switch self {
            case .day: 1
            case .week: 1
            case .month: 1
            case .quarter: 3
            case .year: 12
            }
        }
    }

    public enum Orientation {
        case vertical
        case horizontal
    }

    public struct CellDimensions {
        // MARK: Lifecycle

        public init(width: CGFloat = 18, height: CGFloat = 18, spacing: CGFloat = 4, cornerRadius: CGFloat = 5) {
            self.width = width
            self.height = height
            self.spacing = spacing
            self.cornerRadius = cornerRadius
        }

        // MARK: Public

        public static let `default` = CellDimensions()
        public static let compact = CellDimensions(width: 12, height: 12, spacing: 3, cornerRadius: 3)
        public static let large = CellDimensions(width: 22, height: 22, spacing: 5, cornerRadius: 6)
        /// Minimal style - clean grid without month separation
        public static let minimal = CellDimensions(width: 16, height: 16, spacing: 3, cornerRadius: 4)

        public let width: CGFloat
        public let height: CGFloat
        public let spacing: CGFloat
        public let cornerRadius: CGFloat
    }

    public enum Style {
        case full // Headers, legend, streak badge
        case minimal // Just the grid, no extras
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: self.style == .minimal ? 8 : 16) {
            // Header with streak information (only in full style)
            if self.style == .full && !self.title.isEmpty {
                self.headerView
            }

            // Calendar grid based on time range
            self.calendarContentView

            // Legend and summary (only in full style, not for day/week)
            if self.style == .full && self.timeRange != .day && self.timeRange != .week {
                self.legendView
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                self.animationOffset = 0
                self.animationOpacity = 1
            }
        }
    }

    // MARK: Private

    /// Month grid with date info for year view
    private struct YearMonthGrid: Identifiable {
        // MARK: Lifecycle

        init(month: Date, dayInfos: [MonthDayInfo]) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            self.id = formatter.string(from: month)
            self.month = month
            self.dayInfos = dayInfos
        }

        // MARK: Internal

        let id: String
        let month: Date
        let dayInfos: [MonthDayInfo]
    }

    /// Helper struct for month day info (date can be nil for padding cells)
    private struct MonthDayInfo {
        let date: Date?
    }

    private struct MonthGrid: Identifiable {
        // MARK: Lifecycle

        init(month: Date, days: [DayData?]) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            self.id = formatter.string(from: month)
            self.month = month
            self.days = days
        }

        // MARK: Internal

        let id: String
        let month: Date
        let days: [DayData?]
    }

    /// Locale-aware formatter for compact values (1 fraction digit).
    private static let compactFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    /// Locale-aware formatter for integer values.
    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Locale-aware formatter for values with 1 decimal place.
    private static let oneDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    @Environment(\.theme) private var theme
    @State private var selectedDay: DayData?
    @State private var animationOffset: CGFloat = 0
    @State private var animationOpacity: Double = 0

    private let data: [DayData]
    private let streakInfo: StreakInfo?
    private let title: String
    private let subtitle: String?
    private let accentColor: Color
    private let showMonthHeaders: Bool
    private let monthsToShow: Int
    private let orientation: Orientation
    private let cellDimensions: CellDimensions
    private let style: Style
    private let timeRange: TimeRange
    private let onDayTapped: ((DayData) -> Void)?

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private var weekColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(self.cellDimensions.width), spacing: self.cellDimensions.spacing), count: 7)
    }

    private var monthGrids: [MonthGrid] {
        let endDate = Date()
        let startDate = self.calendar.date(byAdding: .month, value: -self.monthsToShow + 1, to: endDate)!

        var monthGrids: [MonthGrid] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let monthStart = self.calendar.dateInterval(of: .month, for: currentDate)!.start
            let monthEnd = self.calendar.dateInterval(of: .month, for: currentDate)!.end

            // Get all days in the month
            var monthDays: [DayData?] = []
            var date = monthStart

            // Add padding for week alignment
            let weekday = self.calendar.component(.weekday, from: monthStart)
            let paddingDays = (weekday - self.calendar.firstWeekday + 7) % 7
            monthDays.append(contentsOf: Array(repeating: nil, count: paddingDays))

            // Add actual days
            while date < monthEnd {
                let dayData = self.data.first { self.calendar.isDate($0.date, inSameDayAs: date) }
                monthDays.append(dayData)
                date = self.calendar.date(byAdding: .day, value: 1, to: date)!
            }

            monthGrids.append(MonthGrid(month: monthStart, days: monthDays))
            currentDate = self.calendar.date(byAdding: .month, value: 1, to: currentDate)!
        }

        return monthGrids
    }

    /// Today's data for day view
    private var todaysData: DayData? {
        let today = self.calendar.startOfDay(for: Date())
        return self.data.first { self.calendar.isDate($0.date, inSameDayAs: today) }
            ?? self.data.last // Fall back to most recent data if no today data
    }

    /// Last 7 days of data for week view
    private var weekData: [DayData] {
        let today = self.calendar.startOfDay(for: Date())
        let weekAgo = self.calendar.date(byAdding: .day, value: -6, to: today)!

        // Generate all 7 days, using existing data or creating empty placeholders
        return (0..<7).map { dayOffset in
            let date = self.calendar.date(byAdding: .day, value: dayOffset, to: weekAgo)!
            if let existingData = self.data.first(where: { self.calendar.isDate($0.date, inSameDayAs: date) }) {
                return existingData
            } else {
                // Create placeholder for days without data
                return DayData(date: date, value: 0, maxValue: 1, isGoalMet: false)
            }
        }
    }

    /// 12 months of data for year view (legacy - kept for compatibility)
    private var yearMonthGrids: [MonthGrid] {
        let endDate = Date()
        let startDate = self.calendar.date(byAdding: .month, value: -11, to: endDate)!

        var grids: [MonthGrid] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let monthStart = self.calendar.dateInterval(of: .month, for: currentDate)!.start
            let monthEnd = self.calendar.dateInterval(of: .month, for: currentDate)!.end

            var monthDays: [DayData?] = []
            var date = monthStart

            // Add padding for week alignment
            let weekday = self.calendar.component(.weekday, from: monthStart)
            let paddingDays = (weekday - self.calendar.firstWeekday + 7) % 7
            monthDays.append(contentsOf: Array(repeating: nil, count: paddingDays))

            // Add actual days
            while date < monthEnd {
                let dayData = self.data.first { self.calendar.isDate($0.date, inSameDayAs: date) }
                monthDays.append(dayData)
                date = self.calendar.date(byAdding: .day, value: 1, to: date)!
            }

            grids.append(MonthGrid(month: monthStart, days: monthDays))
            currentDate = self.calendar.date(byAdding: .month, value: 1, to: currentDate)!
        }

        return grids
    }

    /// 12 months with date info for year view (includes all days as gray cells)
    private var yearMonthGridsWithDates: [YearMonthGrid] {
        let endDate = Date()
        let startDate = self.calendar.date(byAdding: .month, value: -11, to: endDate)!

        var grids: [YearMonthGrid] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let monthStart = self.calendar.dateInterval(of: .month, for: currentDate)!.start
            let monthEnd = self.calendar.dateInterval(of: .month, for: currentDate)!.end

            var dayInfos: [MonthDayInfo] = []

            // Add padding for week alignment
            let weekday = self.calendar.component(.weekday, from: monthStart)
            let paddingDays = (weekday - self.calendar.firstWeekday + 7) % 7
            dayInfos.append(contentsOf: Array(repeating: MonthDayInfo(date: nil), count: paddingDays))

            // Add all days in the month (including future days)
            var date = monthStart
            while date < monthEnd {
                dayInfos.append(MonthDayInfo(date: date))
                date = self.calendar.date(byAdding: .day, value: 1, to: date)!
            }

            grids.append(YearMonthGrid(month: monthStart, dayInfos: dayInfos))
            currentDate = self.calendar.date(byAdding: .month, value: 1, to: currentDate)!
        }

        return grids
    }

    /// Weekday symbols (S, M, T, W, T, F, S)
    private var weekdaySymbols: [String] {
        let symbols = self.calendar.veryShortWeekdaySymbols
        let firstWeekday = self.calendar.firstWeekday - 1
        return Array(symbols[firstWeekday...]) + Array(symbols[..<firstWeekday])
    }

    /// Current month days for month view (includes padding and all days)
    private var currentMonthDays: [MonthDayInfo] {
        let today = Date()
        let monthStart = self.calendar.dateInterval(of: .month, for: today)!.start
        let monthEnd = self.calendar.dateInterval(of: .month, for: today)!.end

        var days: [MonthDayInfo] = []

        // Add padding for week alignment
        let weekday = self.calendar.component(.weekday, from: monthStart)
        let paddingDays = (weekday - self.calendar.firstWeekday + 7) % 7
        days.append(contentsOf: Array(repeating: MonthDayInfo(date: nil), count: paddingDays))

        // Add all days in the month
        var date = monthStart
        while date < monthEnd {
            days.append(MonthDayInfo(date: date))
            date = self.calendar.date(byAdding: .day, value: 1, to: date)!
        }

        return days
    }

    // MARK: - Formatters

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }

    private var shortDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }

    private var shortMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }

    // MARK: - Time Range Specific Views

    @ViewBuilder
    private var calendarContentView: some View {
        switch self.timeRange {
        case .day:
            self.dayView
        case .week:
            self.weekView
        case .month:
            self.monthView
        case .quarter:
            self.quarterView
        case .year:
            self.yearView
        }
    }

    /// Single day view - large rounded rect showing today's activity
    private var dayView: some View {
        GeometryReader { geometry in
            let todayData = self.todaysData
            let size = min(geometry.size.width, geometry.size.height * 0.8)

            HStack {
                Spacer()
                VStack(spacing: 12) {
                    // Large day cell
                    RoundedRectangle(cornerRadius: 16)
                        .fill(todayData?.color(for: self.accentColor) ?? Color.gray.opacity(0.15))
                        .frame(width: size, height: size * 0.6)
                        .overlay(
                            VStack(spacing: 8) {
                                if let dayData = todayData {
                                    Text(self.dayFormatter.string(from: dayData.date))
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(self.theme.colors.textSecondary)

                                    Text(self.formatValue(dayData.value))
                                        .font(.title.weight(.bold))
                                        .foregroundColor(dayData.isGoalMet ? .white : self.theme.colors.textPrimary)

                                    if dayData.isGoalMet {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white.opacity(0.9))
                                            .accessibilityHidden(true)
                                    }
                                } else {
                                    Text(String(
                                        localized: "calendar.heatmap.noData",
                                        defaultValue: "No Data",
                                        bundle: .module,
                                        comment: "Calendar heatmap empty day label"
                                    ))
                                    .font(.subheadline)
                                    .foregroundColor(self.theme.colors.textSecondary)
                                }
                            }
                        )
                        .onTapGesture {
                            if let dayData = todayData {
                                self.selectedDay = self.selectedDay?.id == dayData.id ? nil : dayData
                                self.onDayTapped?(dayData)
                                HapticManager.shared.trigger(.light)
                            }
                        }

                    // Day label
                    if let dayData = todayData {
                        Text(
                            Calendar.current.isDateInToday(dayData.date)
                                ? String(
                                    localized: "calendar.heatmap.today",
                                    defaultValue: "Today",
                                    bundle: .module,
                                    comment: "Calendar heatmap today label"
                                )
                                : self.dateFormatter.string(from: dayData.date)
                        )
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(self.theme.colors.textSecondary)
                    }
                }
                Spacer()
            }
        }
        .frame(height: 140)
        .opacity(self.animationOpacity)
    }

    /// Week view - row of 7 adaptive cells
    private var weekView: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let cellSpacing: CGFloat = 6
            let totalSpacing = cellSpacing * 6
            let cellSize = (availableWidth - totalSpacing) / 7

            HStack(spacing: cellSpacing) {
                ForEach(self.weekData, id: \.date) { dayData in
                    VStack(spacing: 6) {
                        // Day abbreviation
                        Text(self.shortDayFormatter.string(from: dayData.date))
                            .font(.caption2.weight(.medium))
                            .foregroundColor(self.theme.colors.textTertiary)

                        // Day cell
                        RoundedRectangle(cornerRadius: cellSize * 0.25)
                            .fill(dayData.color(for: self.accentColor))
                            .frame(width: cellSize, height: cellSize)
                            .overlay(
                                Group {
                                    if dayData.isGoalMet {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: cellSize * 0.35, weight: .semibold))
                                            .foregroundColor(.white)
                                            .accessibilityHidden(true)
                                    }
                                }
                            )
                            .onTapGesture {
                                self.selectedDay = self.selectedDay?.id == dayData.id ? nil : dayData
                                self.onDayTapped?(dayData)
                                HapticManager.shared.trigger(.light)
                            }

                        // Day number
                        Text(verbatim: "\(Calendar.current.component(.day, from: dayData.date))")
                            .font(.caption2)
                            .foregroundColor(
                                Calendar.current.isDateInToday(dayData.date)
                                    ? self.accentColor
                                    : self.theme.colors.textSecondary
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 80)
        .opacity(self.animationOpacity)
    }

    /// Month view - single month grid taking full width
    private var monthView: some View {
        let cellSpacing: CGFloat = 3
        let cellSize: CGFloat = 28 // Fixed compact size for month view

        return VStack(alignment: .leading, spacing: 6) {
            // Weekday headers
            HStack(spacing: cellSpacing) {
                ForEach(self.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(self.theme.colors.textTertiary)
                        .frame(width: cellSize)
                }
            }
            .frame(maxWidth: .infinity)

            // Month grid - compact cells without numbers
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: 7),
                spacing: cellSpacing
            ) {
                ForEach(Array(self.currentMonthDays.enumerated()), id: \.offset) { _, dayInfo in
                    if let date = dayInfo.date {
                        // Actual day cell - no numbers, just colored squares
                        let dayData = self.data.first { self.calendar.isDate($0.date, inSameDayAs: date) }
                        let cellColor = dayData?.color(for: self.accentColor) ?? Color.gray.opacity(0.15)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(cellColor)
                            .frame(width: cellSize, height: cellSize)
                            .onTapGesture {
                                if let dayData {
                                    self.selectedDay = self.selectedDay?.id == dayData.id ? nil : dayData
                                    self.onDayTapped?(dayData)
                                    HapticManager.shared.trigger(.light)
                                }
                            }
                    } else {
                        // Padding cell (before first day of month)
                        Color.clear
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(self.animationOpacity)
    }

    /// Quarter view - existing 3-month horizontal scroll
    private var quarterView: some View {
        Group {
            if self.orientation == .horizontal {
                ScrollViewReader { scrollProxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        self.horizontalCalendarGrid
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                scrollProxy.scrollTo("calendar-end", anchor: .trailing)
                            }
                        }
                    }
                }
            } else {
                self.calendarGrid
            }
        }
    }

    /// Year view - 12 months in compact grid layout
    private var yearView: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let monthSpacing: CGFloat = 8
            let monthsPerRow = 4
            let totalSpacing = monthSpacing * CGFloat(monthsPerRow - 1)
            let monthWidth = (availableWidth - totalSpacing) / CGFloat(monthsPerRow)
            let cellSize: CGFloat = (monthWidth - 6 * 1) / 7 // 7 days with 1pt spacing

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: monthSpacing), count: monthsPerRow),
                    spacing: monthSpacing
                ) {
                    ForEach(self.yearMonthGridsWithDates) { monthGrid in
                        VStack(alignment: .leading, spacing: 4) {
                            // Month header
                            Text(self.shortMonthFormatter.string(from: monthGrid.month))
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(self.theme.colors.textSecondary)

                            // Mini month grid
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 1), count: 7),
                                spacing: 1
                            ) {
                                ForEach(Array(monthGrid.dayInfos.enumerated()), id: \.offset) { _, dayInfo in
                                    if let date = dayInfo.date {
                                        // Actual day - show gray for no data, colored for data
                                        let dayData = self.data
                                            .first { self.calendar.isDate($0.date, inSameDayAs: date) }
                                        let cellColor = dayData?.color(for: self.accentColor) ?? Color.gray
                                            .opacity(0.15)

                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(cellColor)
                                            .frame(width: cellSize, height: cellSize)
                                    } else {
                                        // Padding cell - transparent
                                        Color.clear
                                            .frame(width: cellSize, height: cellSize)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(height: 260)
        .opacity(self.animationOpacity)
    }

    // MARK: - View Components

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(self.theme.colors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(self.theme.colors.textSecondary)
                }
            }

            Spacer()

            // Streak information
            if let streakInfo {
                self.streakBadge(streakInfo)
            }
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 12) {
            ForEach(self.monthGrids, id: \.month) { monthGrid in
                VStack(alignment: .leading, spacing: 8) {
                    // Month header
                    if self.showMonthHeaders {
                        Text(self.dateFormatter.string(from: monthGrid.month))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(self.theme.colors.textSecondary)
                    }

                    // Week days grid
                    LazyVGrid(columns: self.weekColumns, spacing: self.cellDimensions.spacing) {
                        ForEach(Array(monthGrid.days.enumerated()), id: \.offset) { _, dayData in
                            self.dayCell(dayData)
                        }
                    }
                }
            }
        }
        .opacity(self.animationOpacity)
        .offset(y: self.animationOffset)
    }

    private var horizontalCalendarGrid: some View {
        HStack(alignment: .top, spacing: self.style == .minimal ? 12 : 20) {
            ForEach(self.monthGrids) { monthGrid in
                VStack(alignment: .leading, spacing: 6) {
                    // Month header
                    if self.showMonthHeaders {
                        Text(self.dateFormatter.string(from: monthGrid.month))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(self.theme.colors.textSecondary)
                    }

                    // Week days grid - fixed height to prevent month height variance
                    LazyVGrid(columns: self.weekColumns, spacing: self.cellDimensions.spacing) {
                        ForEach(Array(monthGrid.days.enumerated()), id: \.offset) { _, dayData in
                            self.dayCell(dayData)
                        }
                    }
                    .frame(minHeight: CGFloat(6) * (self.cellDimensions.height + self.cellDimensions.spacing))
                }
                .id(monthGrid.id)
            }
        }
        .background(
            // Invisible scroll target at the trailing edge (no spacing applied)
            GeometryReader { _ in
                Color.clear
                    .frame(width: 1, height: 1)
                    .id("calendar-end")
            }
            .frame(width: 0, height: 0),
            alignment: .trailing
        )
        .opacity(self.animationOpacity)
        .offset(y: self.animationOffset)
    }

    private var legendView: some View {
        HStack {
            // Simplified intensity legend
            HStack(spacing: 6) {
                Text(String(
                    localized: "calendar.heatmap.legend.less",
                    defaultValue: "Less",
                    bundle: .module,
                    comment: "Calendar heatmap legend label for low intensity"
                ))
                .font(.caption2)
                .foregroundColor(self.theme.colors.textTertiary)

                HStack(spacing: 2) {
                    // Empty
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 12, height: 12)
                    // Partial
                    RoundedRectangle(cornerRadius: 3)
                        .fill(self.accentColor.opacity(0.4))
                        .frame(width: 12, height: 12)
                    // More
                    RoundedRectangle(cornerRadius: 3)
                        .fill(self.accentColor.opacity(0.7))
                        .frame(width: 12, height: 12)
                    // Goal met
                    RoundedRectangle(cornerRadius: 3)
                        .fill(self.accentColor)
                        .frame(width: 12, height: 12)
                }

                Text(String(
                    localized: "calendar.heatmap.legend.more",
                    defaultValue: "More",
                    bundle: .module,
                    comment: "Calendar heatmap legend label for high intensity"
                ))
                .font(.caption2)
                .foregroundColor(self.theme.colors.textTertiary)
            }

            Spacer()

            // Summary stats
            if let streakInfo {
                Text(L10n.format("calendar.heatmap.total_days_format", streakInfo.totalDays))
                    .font(.caption2)
                    .foregroundColor(self.theme.colors.textSecondary)
            }
        }
    }

    private func streakBadge(_ info: StreakInfo) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Image("fire")
                    .resizable().renderingMode(.template).aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                    .foregroundColor(self.accentColor)
                    .accessibilityHidden(true)

                Text(verbatim: "\(info.currentStreak)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(self.theme.colors.textPrimary)
            }

            Text(String(
                localized: "calendar.heatmap.streak.label",
                defaultValue: "day streak",
                bundle: .module,
                comment: "Calendar heatmap streak badge label"
            ))
            .font(.caption2)
            .foregroundColor(self.theme.colors.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(self.accentColor.opacity(0.1))
        )
    }

    private func dayCell(_ dayData: DayData?) -> some View {
        RoundedRectangle(cornerRadius: self.cellDimensions.cornerRadius)
            .fill(dayData?.color(for: self.accentColor) ?? Color.gray.opacity(0.1))
            .frame(width: self.cellDimensions.width, height: self.cellDimensions.height)
            .onTapGesture {
                if let dayData {
                    self.selectedDay = self.selectedDay?.id == dayData.id ? nil : dayData
                    self.onDayTapped?(dayData)
                    HapticManager.shared.trigger(.light)
                }
            }
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            let compact = Self.compactFormatter.string(from: NSNumber(value: value / 1000)) ?? "\(value / 1000)"
            return "\(compact)k"
        } else if value == floor(value) {
            return Self.integerFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        } else {
            return Self.oneDecimalFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
        }
    }
}

// MARK: - Convenience Initializers

extension CalendarHeatmapView {
    /// Create a step goal heatmap
    public static func stepGoals(
        dailySteps: [(Date, Int)],
        goalSteps: Int = 10000,
        orientation: Orientation = .vertical,
        cellDimensions: CellDimensions = .default,
        timeRange: TimeRange = .quarter
    ) -> CalendarHeatmapView {
        let maxSteps = dailySteps.map(\.1).max() ?? goalSteps
        let data = dailySteps.map { date, steps in
            DayData(
                date: date,
                value: Double(steps),
                maxValue: Double(maxSteps),
                isGoalMet: steps >= goalSteps
            )
        }

        // Calculate streak info
        let sortedDates = dailySteps.sorted { $0.0 > $1.0 } // Most recent first
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        let goalMetDates = dailySteps.filter { $0.1 >= goalSteps }.map(\.0)

        // Calculate current streak (from today backwards)
        for (date, steps) in sortedDates {
            if steps >= goalSteps {
                if currentStreak == 0 || Calendar.current.isDate(date, inSameDayAs: Date()) ||
                    Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0 <= currentStreak {
                    currentStreak += 1
                }
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                if currentStreak == 0 {
                    break
                }
                tempStreak = 0
            }
        }

        let streakInfo = StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDays: goalMetDates.count,
            streakDates: goalMetDates
        )

        return CalendarHeatmapView(
            data: data,
            streakInfo: streakInfo,
            title: String(
                localized: "calendar.heatmap.stepGoals.title",
                defaultValue: "Step Goals",
                bundle: .module,
                comment: "Step goals heatmap title"
            ),
            subtitle: String(
                localized: "calendar.heatmap.stepGoals.subtitle",
                defaultValue: "\(goalSteps) steps per day",
                bundle: .module,
                comment: "Step goals heatmap subtitle with daily goal"
            ),
            accentColor: .green,
            orientation: orientation,
            cellDimensions: cellDimensions,
            timeRange: timeRange
        )
    }

    /// Create a workout completion heatmap
    public static func workoutCompletion(
        workoutDays: [Date],
        allDays: [Date],
        orientation: Orientation = .vertical,
        cellDimensions: CellDimensions = .default,
        timeRange: TimeRange = .quarter
    ) -> CalendarHeatmapView {
        let data = allDays.map { date in
            let hasWorkout = workoutDays.contains { Calendar.current.isDate($0, inSameDayAs: date) }
            return DayData(
                date: date,
                value: hasWorkout ? 1.0 : 0.0,
                maxValue: 1.0,
                isGoalMet: hasWorkout
            )
        }

        // Calculate workout streak
        let sortedDates = allDays.sorted { $0 > $1 }
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0

        for date in sortedDates {
            let hasWorkout = workoutDays.contains { Calendar.current.isDate($0, inSameDayAs: date) }
            if hasWorkout {
                if currentStreak == 0 || Calendar.current.isDate(date, inSameDayAs: Date()) {
                    currentStreak += 1
                }
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                if currentStreak == 0 {
                    break
                }
                tempStreak = 0
            }
        }

        let streakInfo = StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDays: workoutDays.count,
            streakDates: workoutDays
        )

        return CalendarHeatmapView(
            data: data,
            streakInfo: streakInfo,
            title: String(
                localized: "calendar.heatmap.workoutDays.title",
                defaultValue: "Workout Days",
                bundle: .module,
                comment: "Workout days heatmap title"
            ),
            subtitle: String(
                localized: "calendar.heatmap.workoutDays.subtitle",
                defaultValue: "Exercise completion",
                bundle: .module,
                comment: "Workout days heatmap subtitle"
            ),
            accentColor: .orange,
            orientation: orientation,
            cellDimensions: cellDimensions,
            timeRange: timeRange
        )
    }

    /// Create a fasting completion heatmap
    public static func fastingCompletion(
        fastingData: [(Date, Double, Double)], // (date, actualHours, goalHours)
        title: String? = nil,
        orientation: Orientation = .vertical,
        cellDimensions: CellDimensions = .default,
        timeRange: TimeRange = .quarter
    ) -> CalendarHeatmapView {
        let title = title ?? String(
            localized: "calendar.heatmap.fastingGoals.title",
            defaultValue: "Fasting Goals",
            bundle: .module,
            comment: "Fasting goals heatmap title"
        )
        let maxHours = fastingData.map(\.1).max() ?? 16.0
        let data = fastingData.map { date, actual, goal in
            DayData(
                date: date,
                value: actual,
                maxValue: maxHours,
                isGoalMet: actual >= goal
            )
        }

        // Calculate fasting streak
        let sortedFasts = fastingData.sorted { $0.0 > $1.0 }
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        let successfulFasts = fastingData.filter { $0.1 >= $0.2 }.map(\.0)

        for (date, actual, goal) in sortedFasts {
            if actual >= goal {
                if currentStreak == 0 || Calendar.current.isDate(date, inSameDayAs: Date()) {
                    currentStreak += 1
                }
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                if currentStreak == 0 {
                    break
                }
                tempStreak = 0
            }
        }

        let streakInfo = StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDays: successfulFasts.count,
            streakDates: successfulFasts
        )

        return CalendarHeatmapView(
            data: data,
            streakInfo: streakInfo,
            title: title,
            subtitle: String(
                localized: "calendar.heatmap.fastingGoals.subtitle",
                defaultValue: "Daily fasting goals",
                bundle: .module,
                comment: "Fasting goals heatmap subtitle"
            ),
            accentColor: .purple,
            orientation: orientation,
            cellDimensions: cellDimensions,
            timeRange: timeRange
        )
    }
}

// MARK: - Preview

#Preview("Calendar Heatmap - Time Ranges") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Calendar Heatmap Time Ranges")
                .font(.title2.bold())
                .padding()

            // Sample data
            let calendar = Calendar.current
            let today = Date()
            let stepData = (0..<365).compactMap { offset -> (Date, Int)? in
                guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                    return nil
                }
                let steps = Int.random(in: 3000...15000)
                return (date, steps)
            }

            let fastingData = (0..<365).compactMap { offset -> (Date, Double, Double)? in
                guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                    return nil
                }
                let actual = Double.random(in: 8...20)
                let goal = 16.0
                return (date, actual, goal)
            }

            // Day View
            Text("Day View")
                .font(.headline)
            CalendarHeatmapView.stepGoals(dailySteps: stepData, timeRange: .day)
                .padding(.horizontal)

            Divider()

            // Week View
            Text("Week View")
                .font(.headline)
            CalendarHeatmapView.stepGoals(dailySteps: stepData, timeRange: .week)
                .padding(.horizontal)

            Divider()

            // Month View
            Text("Month View")
                .font(.headline)
            CalendarHeatmapView.fastingCompletion(fastingData: fastingData, timeRange: .month)
                .padding(.horizontal)

            Divider()

            // Quarter View (existing horizontal)
            Text("Quarter View (3 Months)")
                .font(.headline)
            CalendarHeatmapView.stepGoals(
                dailySteps: stepData,
                orientation: .horizontal,
                timeRange: .quarter
            )
            .padding(.horizontal)

            Divider()

            // Year View
            Text("Year View")
                .font(.headline)
            CalendarHeatmapView.fastingCompletion(fastingData: fastingData, timeRange: .year)
                .padding(.horizontal)
        }
        .padding()
    }
}
