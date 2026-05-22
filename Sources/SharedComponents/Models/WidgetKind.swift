import Foundation

// MARK: - WidgetDefaults

/// Centralized default values for widget data
/// Use these constants instead of hardcoding values across widget code
public enum WidgetDefaults {
    // MARK: - Nutrition Goals

    /// Default daily calorie goal (kcal)
    public static let caloriesGoal = 2000

    /// Default daily protein goal (grams)
    public static let proteinGoal = 150

    /// Default daily carbs goal (grams)
    public static let carbsGoal = 250

    /// Default daily fat goal (grams)
    public static let fatGoal = 65

    // MARK: - Hydration

    /// Default daily water goal (ml)
    public static let waterGoalMl = 2500

    // MARK: - Steps

    /// Default daily steps goal
    public static let stepsGoal = 10000

    // MARK: - Quick Add Amounts

    /// Small water quick-add amount (ml)
    public static let waterQuickAddSmall = 150

    /// Medium water quick-add amount (ml)
    public static let waterQuickAddMedium = 250

    /// Large water quick-add amount (ml)
    public static let waterQuickAddLarge = 500
}

// MARK: - WidgetKind

/// Centralized widget kind identifiers
public enum WidgetKind {
    // MARK: - Nutrition Widgets

    /// Meal Logger widget - tracks daily meals and calories
    public static let mealLogger = "NioraMealLoggerWidget"

    /// Water Logger widget - tracks hydration with interactive logging
    public static let waterLogger = "NioraWaterLoggerWidget"

    // MARK: - Fitness Widgets

    /// Workout widget - shows scheduled/active workouts
    public static let workout = "NioraWorkoutWidget"

    /// Fasting widget - tracks intermittent fasting status
    public static let fasting = "NioraFastingWidget"

    // MARK: - Control Widgets

    /// Water Logger Control Center widget
    public static let waterLoggerControl = "com.3theories.niora.WaterLoggerControl"

    /// Workout Control widget
    public static let workoutControl = "com.3theories.niora.WorkoutWidget"

    // MARK: - All Kinds

    /// All widget kinds for bulk reload operations
    public static let all: [String] = [
        mealLogger,
        waterLogger,
        workout,
        fasting
    ]
}
