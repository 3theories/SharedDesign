import SwiftUI

// MARK: - MacroType

/// Macro nutrient types with associated colors
public enum MacroType: String, CaseIterable, Sendable {
    case protein
    case carbs
    case fat
    case fiber
    case calories

    // MARK: Public

    /// Basic macros (protein, carbs, fat) - commonly used for macro distribution views
    public static var basicMacros: [MacroType] {
        [.protein, .carbs, .fat]
    }

    /// Default color for this macro type
    public var color: Color {
        switch self {
        case .protein: ColorPalette.NutritionCategories.protein
        case .carbs: ColorPalette.NutritionCategories.carbs
        case .fat: ColorPalette.NutritionCategories.fats
        case .fiber: ColorPalette.NutritionCategories.fiber
        case .calories: ColorPalette.Fitness.calories
        }
    }

    /// Icon for this macro type
    public var icon: String {
        switch self {
        case .protein: "protein"
        case .carbs: "carbs"
        case .fat: "fat"
        case .fiber: "leaf.arrow.circlepath"
        case .calories: "calorieIntake"
        }
    }

    /// Whether this macro type uses an SF Symbol (true) or a custom asset icon (false)
    public var isSystemIcon: Bool {
        switch self {
        case .protein, .carbs, .fat, .calories: false
        case .fiber: true
        }
    }

    /// Display label for this macro type
    public var label: String {
        switch self {
        case .protein: "Protein"
        case .carbs: "Carbs"
        case .fat: "Fat"
        case .fiber: "Fiber"
        case .calories: "Calories"
        }
    }

    /// Alias for label (backward compatibility)
    public var name: String {
        self.label
    }

    /// Default unit for this macro type
    public var unit: String {
        switch self {
        case .protein, .carbs, .fat, .fiber: "g"
        case .calories: "kcal"
        }
    }

    /// Calories per gram for this macro type
    public var caloriesPerGram: Double {
        switch self {
        case .protein: 4
        case .carbs: 4
        case .fat: 9
        case .fiber: 0
        case .calories: 1
        }
    }

    /// Theme-aware color using nutrient-specific colors
    public func color(from theme: Theme) -> Color {
        switch self {
        case .protein: theme.colors.nutrientProtein
        case .carbs: theme.colors.nutrientCarbs
        case .fat: theme.colors.nutrientFat
        case .fiber: theme.colors.success
        case .calories: theme.colors.warning
        }
    }
}

// MARK: - MacroCardStyle

/// Display style variants for SharedMacroCard
public enum MacroCardStyle: Sendable {
    /// Compact inline row with label and value
    case inline

    /// Tile with progress bar
    case tile

    /// Stat card with animated fill background
    case stat

    /// Minimal badge display
    case badge

    /// Ring progress display
    case ring
}

// MARK: - SharedMacroCard

/// Unified component for displaying macro nutrient information.
/// Consolidates MacroNutrientTile, MacroRow, and MacroStatCard.
public struct SharedMacroCard: View {
    // MARK: Lifecycle

    public init(
        macroType: MacroType,
        value: Double,
        target: Double? = nil,
        style: MacroCardStyle = .tile,
        customLabel: String? = nil,
        customColor: Color? = nil,
        showUnit: Bool = true,
        animationDelay: Double = 0
    ) {
        self.macroType = macroType
        self.value = value
        self.target = target
        self.style = style
        self.customLabel = customLabel
        self.customColor = customColor
        self.showUnit = showUnit
        self.animationDelay = animationDelay
    }

    // MARK: Public

    public var body: some View {
        Group {
            switch self.style {
            case .inline:
                self.inlineContent
            case .tile:
                self.tileContent
            case .stat:
                self.statContent
            case .badge:
                self.badgeContent
            case .ring:
                self.ringContent
            }
        }
        .onAppear {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(self.animationDelay)
            ) {
                self.hasAppeared = true
                self.animatedProgress = self.progress
            }
        }
    }

    // MARK: Internal

    // Required
    let macroType: MacroType
    let value: Double

    // Optional
    let target: Double?
    let style: MacroCardStyle
    let customLabel: String?
    let customColor: Color?
    let showUnit: Bool
    let animationDelay: Double

    // MARK: Private

    /// Locale-aware formatter for compact values (e.g., "1.2k").
    private static let compactNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    /// Locale-aware formatter for integer-style values.
    private static let integerNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    @Environment(\.theme) private var theme
    @State private var hasAppeared = false
    @State private var animatedProgress: Double = 0

    private var color: Color {
        self.customColor ?? self.macroType.color
    }

    private var label: String {
        self.customLabel ?? self.macroType.label
    }

    private var unit: String {
        self.macroType.unit
    }

    private var progress: Double {
        guard let target, target > 0 else {
            return 1.0
        }
        return min(self.value / target, 1.0)
    }

    private var displayValue: String {
        if self.value >= 1000 {
            let compact = Self.compactNumberFormatter
                .string(from: NSNumber(value: self.value / 1000)) ?? "\(self.value / 1000)"
            return "\(compact)k"
        } else {
            return Self.integerNumberFormatter.string(from: NSNumber(value: self.value)) ?? "\(Int(self.value))"
        }
    }

    // MARK: - Inline Style

    private var inlineContent: some View {
        HStack {
            Text(self.label)
                .font(self.theme.typography.body)
                .foregroundStyle(self.theme.colors.textPrimary)

            Spacer()

            HStack(spacing: 0) {
                Text(self.displayValue)
                    .font(self.theme.typography.body.weight(.semibold))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: self.value)
                    .foregroundStyle(self.color)

                if self.showUnit {
                    Text(verbatim: " \(self.unit)")
                        .font(self.theme.typography.body)
                        .foregroundStyle(self.theme.colors.textSecondary)
                }
            }
        }
        .padding(.vertical, self.theme.spacing.sm)
        .padding(.horizontal, self.theme.spacing.md)
        .background(self.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small))
    }

    // MARK: - Tile Style

    private var tileContent: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.xxs) {
            Text(self.label)
                .font(self.theme.typography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(self.color)

            Text(self.displayValue)
                .font(self.theme.typography.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: self.value)

            if let target {
                Text(verbatim: "/ \(Int(target))\(self.showUnit ? self.unit : "")")
                    .font(self.theme.typography.footnote)
                    .foregroundStyle(self.theme.colors.textSecondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(self.theme.colors.surface3)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(self.color.gradient)
                        .frame(
                            width: geometry.size.width * self.animatedProgress,
                            height: 4
                        )
                }
            }
            .frame(height: 4)
        }
        .frame(minHeight: 80)
        .padding(.vertical, self.theme.spacing.sm)
        .padding(.horizontal, self.theme.spacing.md)
        .background(self.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small))
    }

    // MARK: - Stat Style

    private var statContent: some View {
        VStack(spacing: self.theme.spacing.xs) {
            Text(self.displayValue)
                .font(self.theme.typography.title2.bold())
                .foregroundStyle(self.color)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: self.value)

            Text(self.label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(self.theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .frame(height: 24)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(.vertical, self.theme.spacing.md)
        .background(
            GeometryReader { geometry in
                Rectangle()
                    .fill(self.color.opacity(0.1))
                    .frame(width: geometry.size.width * self.animatedProgress)
            }
            .background(self.theme.colors.surface2)
        )
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
    }

    // MARK: - Badge Style

    private var badgeContent: some View {
        HStack(spacing: self.theme.spacing.xxs) {
            Circle()
                .fill(self.color)
                .frame(width: 8, height: 8)

            Text(self.displayValue)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(self.theme.colors.textPrimary)

            if self.showUnit {
                Text(self.unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(self.theme.colors.textSecondary)
            }
        }
        .padding(.horizontal, self.theme.spacing.sm)
        .padding(.vertical, self.theme.spacing.xxs)
        .background(self.color.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Ring Style

    private var ringContent: some View {
        VStack(spacing: self.theme.spacing.xs) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(self.color.opacity(0.2), lineWidth: 6)
                    .frame(width: 56, height: 56)

                // Progress ring
                Circle()
                    .trim(from: 0, to: self.animatedProgress)
                    .stroke(
                        self.color.gradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                // Value
                Text(self.displayValue)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(self.theme.colors.textPrimary)
            }

            Text(self.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(self.theme.colors.textSecondary)
        }
    }
}

// MARK: - Convenience Initializers

extension SharedMacroCard {
    /// Create a protein macro card
    public static func protein(
        value: Double,
        target: Double? = nil,
        style: MacroCardStyle = .tile
    ) -> SharedMacroCard {
        SharedMacroCard(macroType: .protein, value: value, target: target, style: style)
    }

    /// Create a carbs macro card
    public static func carbs(
        value: Double,
        target: Double? = nil,
        style: MacroCardStyle = .tile
    ) -> SharedMacroCard {
        SharedMacroCard(macroType: .carbs, value: value, target: target, style: style)
    }

    /// Create a fat macro card
    public static func fat(
        value: Double,
        target: Double? = nil,
        style: MacroCardStyle = .tile
    ) -> SharedMacroCard {
        SharedMacroCard(macroType: .fat, value: value, target: target, style: style)
    }

    /// Create a fiber macro card
    public static func fiber(
        value: Double,
        target: Double? = nil,
        style: MacroCardStyle = .tile
    ) -> SharedMacroCard {
        SharedMacroCard(macroType: .fiber, value: value, target: target, style: style)
    }

    /// Create a calories macro card
    public static func calories(
        value: Double,
        target: Double? = nil,
        style: MacroCardStyle = .stat
    ) -> SharedMacroCard {
        SharedMacroCard(macroType: .calories, value: value, target: target, style: style)
    }
}

// MARK: - MacroRowGroup

/// A group of macro cards displayed in a row
public struct MacroRowGroup: View {
    // MARK: Lifecycle

    public init(
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        style: MacroCardStyle = .tile,
        proteinTarget: Double? = nil,
        carbsTarget: Double? = nil,
        fatTarget: Double? = nil,
        fiberTarget: Double? = nil
    ) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.style = style
        self.proteinTarget = proteinTarget
        self.carbsTarget = carbsTarget
        self.fatTarget = fatTarget
        self.fiberTarget = fiberTarget
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: self.theme.spacing.sm) {
            SharedMacroCard.protein(
                value: self.protein,
                target: self.proteinTarget,
                style: self.style
            )

            SharedMacroCard.carbs(
                value: self.carbs,
                target: self.carbsTarget,
                style: self.style
            )

            SharedMacroCard.fat(
                value: self.fat,
                target: self.fatTarget,
                style: self.style
            )

            if let fiber {
                SharedMacroCard.fiber(
                    value: fiber,
                    target: self.fiberTarget,
                    style: self.style
                )
            }
        }
    }

    // MARK: Internal

    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let style: MacroCardStyle
    let proteinTarget: Double?
    let carbsTarget: Double?
    let fatTarget: Double?
    let fiberTarget: Double?

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - Preview

#Preview("SharedMacroCard Styles") {
    ScrollView {
        VStack(spacing: 24) {
            Text("SharedMacroCard Styles")
                .font(.title2.bold())

            // Tile Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Tile Style").font(.headline)
                HStack(spacing: 8) {
                    SharedMacroCard.protein(value: 120, target: 150, style: .tile)
                    SharedMacroCard.carbs(value: 190, target: 300, style: .tile)
                    SharedMacroCard.fat(value: 65, target: 80, style: .tile)
                }
            }

            // Stat Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Stat Style").font(.headline)
                HStack(spacing: 8) {
                    SharedMacroCard.protein(value: 45, style: .stat)
                    SharedMacroCard.carbs(value: 78, style: .stat)
                    SharedMacroCard.fat(value: 23, style: .stat)
                }
            }

            // Inline Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Inline Style").font(.headline)
                VStack(spacing: 8) {
                    SharedMacroCard.protein(value: 120, style: .inline)
                    SharedMacroCard.carbs(value: 190, style: .inline)
                    SharedMacroCard.fat(value: 65, style: .inline)
                }
            }

            // Badge Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Badge Style").font(.headline)
                HStack(spacing: 8) {
                    SharedMacroCard.protein(value: 45, style: .badge)
                    SharedMacroCard.carbs(value: 78, style: .badge)
                    SharedMacroCard.fat(value: 23, style: .badge)
                    SharedMacroCard.fiber(value: 12, style: .badge)
                }
            }

            // Ring Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Ring Style").font(.headline)
                HStack(spacing: 16) {
                    SharedMacroCard(macroType: .protein, value: 120, target: 150, style: .ring)
                    SharedMacroCard(macroType: .carbs, value: 190, target: 300, style: .ring)
                    SharedMacroCard(macroType: .fat, value: 65, target: 80, style: .ring)
                }
            }

            // Macro Row Group
            VStack(alignment: .leading, spacing: 8) {
                Text("Macro Row Group").font(.headline)
                MacroRowGroup(
                    protein: 120,
                    carbs: 190,
                    fat: 65,
                    fiber: 25,
                    style: .tile,
                    proteinTarget: 150,
                    carbsTarget: 300,
                    fatTarget: 80,
                    fiberTarget: 30
                )
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
