import SwiftUI

// MARK: - InsightsHighlightCard

/// Premium highlight card for showcasing key insights and achievements
/// Features smooth animations and rich visual indicators
public struct InsightsHighlightCard: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        data: HighlightData,
        size: CardSize = .standard,
        customGradient: LinearGradient? = nil,
        animateOnAppear: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.data = data
        self.size = size
        self.customGradient = customGradient
        self.animateOnAppear = animateOnAppear
        self.onTap = onTap
    }

    // MARK: Public

    // MARK: - Data Types

    public struct HighlightData {
        // MARK: Lifecycle

        public init(
            title: String,
            value: String,
            subtitle: String? = nil,
            trend: TrendDirection? = nil,
            trendValue: String? = nil,
            icon: String,
            isSystemIcon: Bool = true,
            category: HighlightCategory,
            achievement: Achievement? = nil
        ) {
            self.title = title
            self.value = value
            self.subtitle = subtitle
            self.trend = trend
            self.trendValue = trendValue
            self.icon = icon
            self.isSystemIcon = isSystemIcon
            self.category = category
            self.achievement = achievement
        }

        // MARK: Public

        public let title: String
        public let value: String
        public let subtitle: String?
        public let trend: TrendDirection?
        public let trendValue: String?
        public let icon: String
        public let isSystemIcon: Bool
        public let category: HighlightCategory
        public let achievement: Achievement?
    }

    public enum TrendDirection {
        case up, down, stable

        // MARK: Public

        public var icon: String {
            switch self {
            case .up: "arrowupright"
            case .down: "arrowdownright"
            case .stable: "minus"
            }
        }

        public var isSystemIcon: Bool {
            switch self {
            case .up, .down: false
            case .stable: true
            }
        }

        public var color: Color {
            switch self {
            case .up: .green
            case .down: .red
            case .stable: .orange
            }
        }
    }

    public enum HighlightCategory {
        case fitness, nutrition, health, fasting, general

        // MARK: Public

        public var primaryColor: Color {
            switch self {
            case .fitness: .red
            case .nutrition: .green
            case .health: .blue
            case .fasting: .purple
            case .general: .orange
            }
        }

        public var gradient: LinearGradient {
            switch self {
            case .fitness:
                LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .nutrition:
                LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .health:
                LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .fasting:
                LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .general:
                LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }

    public struct Achievement {
        // MARK: Lifecycle

        public init(title: String, icon: String, isSystemIcon: Bool = true, isNew: Bool = true) {
            self.title = title
            self.icon = icon
            self.isSystemIcon = isSystemIcon
            self.isNew = isNew
        }

        // MARK: Public

        public let title: String
        public let icon: String
        public let isSystemIcon: Bool
        public let isNew: Bool
    }

    public enum CardSize {
        case compact // 2x2 grid item
        case standard // Full width
        case hero // Large featured card

        // MARK: Internal

        var height: CGFloat {
            switch self {
            case .compact: 115 // Accommodates 2-line titles
            case .standard: 120
            case .hero: 150
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .compact: 20
            case .standard: 24
            case .hero: 32
            }
        }

        var padding: CGFloat {
            switch self {
            case .compact: 12
            case .standard: 14
            case .hero: 16
            }
        }
    }

    // MARK: - Body

    public var body: some View {
        Button(action: {
            self.onTap?()
            self.triggerHaptic()
        }) {
            self.cardContent
                .overlay(self.celebrationOverlay)
        }
        .buttonStyle(PressedButtonStyle(isPressed: self.$isPressed))
        .disabled(self.onTap == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            [self.data.title, self.data.value, self.data.subtitle, self.data.trendValue]
                .compactMap { $0 }.joined(separator: ", ")
        )
        .onAppear {
            self.startAnimations()
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var isPressed = false
    @State private var animatedValue: Double = 0
    @State private var hasAppeared = false
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var achievementScale: CGFloat = 0.5
    @State private var showCelebration = false

    private let data: HighlightData
    private let size: CardSize
    private let customGradient: LinearGradient?
    private let onTap: (() -> Void)?
    private let animateOnAppear: Bool

    // MARK: - Celebration Overlay

    @ViewBuilder
    private var celebrationOverlay: some View {
        if self.showCelebration && self.data.achievement != nil {
            ZStack {
                // Particle burst effect
                ForEach(0..<12, id: \.self) { index in
                    Circle()
                        .fill(self.data.category.primaryColor)
                        .frame(width: 6, height: 6)
                        .offset(self.celebrationOffset(for: index))
                        .opacity(self.showCelebration ? 0 : 1)
                }
            }
            .animation(.easeOut(duration: 0.6), value: self.showCelebration)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Achievement badge row if present
            if let achievement = data.achievement, size == .hero {
                HStack {
                    Spacer()
                    self.achievementBadge(achievement)
                }
                .padding(.horizontal, self.size.padding)
                .padding(.top, self.size.padding)
                .padding(.bottom, 8)
            }

            // Main content
            VStack(alignment: .leading, spacing: self.size == .compact ? 6 : 8) {
                self.headerRow

                if self.size == .hero {
                    // For hero cards, keep content tighter at the top
                    self.valueSection
                        .padding(.top, 4)
                    Spacer()
                } else {
                    // For standard/compact, distribute evenly
                    Spacer(minLength: 2)
                    self.valueSection
                    if self.size != .compact {
                        Spacer(minLength: 2)
                        self.bottomSection
                    }
                }
            }
            .padding(.horizontal, self.size.padding)
            .padding(.top, self.data.achievement != nil && self.size == .hero ? 0 : self.size.padding)
            .padding(.bottom, self.size.padding)
        }
        .frame(minHeight: self.size.height)
        .frame(maxHeight: self.size == .hero ? .infinity : self.size.height)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 16)
                    .fill(self.theme.colors.surface1)

                // Optional gradient overlay
                if let gradient = customGradient {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(gradient.opacity(0.05))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(self.theme.colors.borderSecondary.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: self.theme.colors.shadow.opacity(0.1), radius: 10, x: 0, y: 4)
        .scaleEffect(self.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: self.isPressed)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(self.theme.colors.surface1)
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 10) {
            // Icon styled like MetricCard with enhanced animations
            ZStack {
                // Background glow
                Circle()
                    .fill(self.data.category.primaryColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .blur(radius: 4)
                    .opacity(self.iconOpacity * 0.5)

                Circle()
                    .fill(self.data.category.primaryColor.opacity(0.1))
                    .frame(width: 32, height: 32)

                // Progress ring animation
                Circle()
                    .trim(from: 0, to: self.animatedValue)
                    .stroke(
                        self.data.category.primaryColor.gradient,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))

                AppIconView(name: self.data.icon, isSystemIcon: self.data.isSystemIcon)
                    .frame(width: 16, height: 16)
                    .foregroundColor(self.data.category.primaryColor)
                    .scaleEffect(self.iconScale)
                    .opacity(self.iconOpacity)
            }

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(self.data.title)
                    .font(self.size == .compact ? .caption : .subheadline)
                    .foregroundStyle(self.theme.colors.textSecondary)
                    .lineLimit(self.size == .compact ? 2 : 1)
                    .minimumScaleFactor(0.8)
                    .opacity(self.contentOpacity)

                // Show trend here for compact layouts
                if self.size == .compact, let trend = data.trend, let trendValue = data.trendValue {
                    self.compactTrendIndicator(trend: trend, value: trendValue)
                        .opacity(self.contentOpacity)
                }
            }

            Spacer()

            // Trend indicator for non-compact
            if self.size != .compact, let trend = data.trend, let trendValue = data.trendValue {
                self.trendIndicator(trend: trend, value: trendValue)
                    .opacity(self.contentOpacity)
                    .scaleEffect(self.animateOnAppear ? (self.contentOpacity == 1 ? 1 : 0.8) : 1)
            }
        }
    }

    private var valueSection: some View {
        VStack(alignment: .leading, spacing: self.size == .hero ? 6 : 4) {
            // Main value with number animation
            Text(self.data.value)
                .font(
                    self.size == .compact
                        ? .title3.bold()
                        : self.size == .hero
                            ? .system(
                                size: 42,
                                weight: .bold,
                                design: .rounded
                            )
                            : .title2.bold()
                )
                .foregroundStyle(self.theme.colors.textPrimary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .opacity(self.contentOpacity)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: self.data.value)

            // Subtitle if present
            if let subtitle = data.subtitle {
                Text(subtitle)
                    .font(self.size == .hero ? .subheadline : .caption)
                    .foregroundColor(self.theme.colors.textTertiary)
                    .lineLimit(self.size == .compact ? 1 : 2)
                    .opacity(self.contentOpacity)
            }
        }
    }

    private var bottomSection: some View {
        EmptyView()
    }

    private func trendIndicator(trend: TrendDirection, value: String) -> some View {
        HStack(spacing: 3) {
            AppIconView(name: trend.icon, isSystemIcon: trend.isSystemIcon)
                .frame(width: 10, height: 10)
                .foregroundColor(trend.color)

            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundColor(trend.color)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(trend.color.opacity(0.1))
        )
    }

    private func compactTrendIndicator(trend: TrendDirection, value: String) -> some View {
        HStack(spacing: 2) {
            AppIconView(name: trend.icon, isSystemIcon: trend.isSystemIcon)
                .frame(width: 10, height: 10)
                .foregroundColor(trend.color)

            Text(value)
                .font(.caption2.weight(.medium))
                .foregroundColor(trend.color)
        }
    }

    private func achievementBadge(_ achievement: Achievement) -> some View {
        HStack(spacing: 4) {
            AppIconView(name: achievement.icon, isSystemIcon: achievement.isSystemIcon)
                .frame(width: 10, height: 10)
                .foregroundColor(.white)

            Text(achievement.title)
                .font(.caption2.weight(.bold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(self.data.category.primaryColor)
                .shadow(color: self.data.category.primaryColor.opacity(0.4), radius: 8, y: 2)
        )
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.3), lineWidth: 0.5)
        )
        .scaleEffect(self.achievementScale)
    }

    private func celebrationOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 12.0) * .pi / 180
        let radius: Double = self.showCelebration ? 60 : 0
        return CGSize(
            width: Foundation.cos(angle) * radius,
            height: Foundation.sin(angle) * radius
        )
    }

    // MARK: - Helper Methods

    private func startAnimations() {
        guard self.animateOnAppear else {
            // Skip animations
            self.iconScale = 1.0
            self.iconOpacity = 1.0
            self.contentOpacity = 1.0
            self.animatedValue = 1.0
            self.hasAppeared = true
            self.achievementScale = 1.0
            return
        }

        // Staggered entrance animations
        // Icon appears first with bounce
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
            self.iconScale = 1.0
            self.iconOpacity = 1.0
        }

        // Content fades in
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            self.contentOpacity = 1.0
        }

        // Progress ring animates
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            self.animatedValue = 1.0
        }

        // Mark as appeared for symbol effects
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.hasAppeared = true
        }

        // Achievement badge bounces in and triggers celebration
        if self.data.achievement != nil {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.5)) {
                self.achievementScale = 1.0
            }

            // Trigger celebration effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                HapticManager.shared.trigger(.success)
                withAnimation(.easeOut(duration: 0.6)) {
                    self.showCelebration = true
                }
            }
        }
    }

    private func triggerHaptic() {
        HapticManager.shared.trigger(.light)
    }
}

// MARK: - PressedButtonStyle

private struct PressedButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                self.isPressed = pressed
            }
    }
}

// MARK: - Convenience Initializers

extension InsightsHighlightCard {
    /// Create a fitness highlight card
    public static func fitness(
        title: String,
        value: String,
        subtitle: String? = nil,
        trend: TrendDirection? = nil,
        trendValue: String? = nil,
        icon: String = "liftWeight",
        isSystemIcon: Bool = false,
        size: CardSize = .standard,
        customGradient: LinearGradient? = nil,
        animateOnAppear: Bool = true,
        onTap: (() -> Void)? = nil
    ) -> InsightsHighlightCard {
        let data = HighlightData(
            title: title,
            value: value,
            subtitle: subtitle,
            trend: trend,
            trendValue: trendValue,
            icon: icon,
            isSystemIcon: isSystemIcon,
            category: .fitness
        )

        return InsightsHighlightCard(
            data: data,
            size: size,
            customGradient: customGradient,
            animateOnAppear: animateOnAppear,
            onTap: onTap
        )
    }

    /// Create a nutrition highlight card
    public static func nutrition(
        title: String,
        value: String,
        subtitle: String? = nil,
        trend: TrendDirection? = nil,
        trendValue: String? = nil,
        icon: String = "leaf.fill",
        isSystemIcon: Bool = true,
        size: CardSize = .standard,
        customGradient: LinearGradient? = nil,
        animateOnAppear: Bool = true,
        onTap: (() -> Void)? = nil
    ) -> InsightsHighlightCard {
        let data = HighlightData(
            title: title,
            value: value,
            subtitle: subtitle,
            trend: trend,
            trendValue: trendValue,
            icon: icon,
            isSystemIcon: isSystemIcon,
            category: .nutrition
        )

        return InsightsHighlightCard(
            data: data,
            size: size,
            customGradient: customGradient,
            animateOnAppear: animateOnAppear,
            onTap: onTap
        )
    }

    /// Create a health highlight card
    public static func health(
        title: String,
        value: String,
        subtitle: String? = nil,
        trend: TrendDirection? = nil,
        trendValue: String? = nil,
        icon: String = "heart.fill",
        isSystemIcon: Bool = true,
        size: CardSize = .standard,
        achievement: Achievement? = nil,
        customGradient: LinearGradient? = nil,
        animateOnAppear: Bool = true,
        onTap: (() -> Void)? = nil
    ) -> InsightsHighlightCard {
        let data = HighlightData(
            title: title,
            value: value,
            subtitle: subtitle,
            trend: trend,
            trendValue: trendValue,
            icon: icon,
            isSystemIcon: isSystemIcon,
            category: .health,
            achievement: achievement
        )

        return InsightsHighlightCard(
            data: data,
            size: size,
            customGradient: customGradient,
            animateOnAppear: animateOnAppear,
            onTap: onTap
        )
    }

    /// Create a fasting highlight card
    public static func fasting(
        title: String,
        value: String,
        subtitle: String? = nil,
        trend: TrendDirection? = nil,
        trendValue: String? = nil,
        icon: String = "timer",
        isSystemIcon: Bool = true,
        size: CardSize = .standard,
        achievement: Achievement? = nil,
        customGradient: LinearGradient? = nil,
        animateOnAppear: Bool = true,
        onTap: (() -> Void)? = nil
    ) -> InsightsHighlightCard {
        let data = HighlightData(
            title: title,
            value: value,
            subtitle: subtitle,
            trend: trend,
            trendValue: trendValue,
            icon: icon,
            isSystemIcon: isSystemIcon,
            category: .fasting,
            achievement: achievement
        )

        return InsightsHighlightCard(
            data: data,
            size: size,
            customGradient: customGradient,
            animateOnAppear: animateOnAppear,
            onTap: onTap
        )
    }
}

// MARK: - Preview

#Preview("Insights Highlight Cards") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Insights Highlight Cards")
                .font(.title2.bold())
                .padding()

            // Hero card
            InsightsHighlightCard.health(
                title: "Daily Steps",
                value: "12,847",
                subtitle: "Goal: 10,000 steps",
                trend: .up,
                trendValue: "+23%",
                icon: "figure.walk",
                size: .hero,
                achievement: InsightsHighlightCard.Achievement(
                    title: "7 Day Streak!",
                    icon: "flame.fill"
                )
            )

            // Grid of compact cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                InsightsHighlightCard.fitness(
                    title: "Workouts",
                    value: "5",
                    trend: .up,
                    trendValue: "+2",
                    size: .compact
                )

                InsightsHighlightCard.nutrition(
                    title: "Calories",
                    value: "2,140",
                    trend: .stable,
                    trendValue: "±50",
                    size: .compact
                )

                InsightsHighlightCard.health(
                    title: "Sleep",
                    value: "7.5h",
                    trend: .up,
                    trendValue: "+30m",
                    icon: "moon.fill",
                    size: .compact
                )

                InsightsHighlightCard.fasting(
                    title: "Fast",
                    value: "16:8",
                    trend: .stable,
                    trendValue: "On track",
                    size: .compact
                )
            }

            // Standard cards
            VStack(spacing: 16) {
                InsightsHighlightCard.fitness(
                    title: "Weekly Active Calories",
                    value: "2,847",
                    subtitle: "From 6 workouts this week",
                    trend: .up,
                    trendValue: "+15%"
                )

                InsightsHighlightCard.nutrition(
                    title: "Protein Intake",
                    value: "125g",
                    subtitle: "Daily average this week",
                    trend: .up,
                    trendValue: "+8%",
                    icon: "flame.fill"
                )
            }
        }
        .padding()
    }
}
