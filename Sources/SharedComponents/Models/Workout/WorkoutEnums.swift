import Foundation

// MARK: - WorkoutType

/// Workout type enum for shared use
public enum WorkoutType: String, Codable, CaseIterable, Hashable, Sendable {
    case strength
    case cardio
    case hiit
    case flexibility
    case mixed
    case yoga
    case pilates
    case custom

    // MARK: Public

    public var displayName: String {
        switch self {
        case .strength: String(localized: "Strength", comment: "Workout type: Strength training")
        case .cardio: String(localized: "Cardio", comment: "Workout type: Cardiovascular training")
        case .hiit: String(localized: "HIIT", comment: "Workout type: High-Intensity Interval Training")
        case .flexibility: String(localized: "Flexibility", comment: "Workout type: Flexibility training")
        case .mixed: String(localized: "Mixed", comment: "Workout type: Mixed training")
        case .yoga: String(localized: "Yoga", comment: "Workout type: Yoga")
        case .pilates: String(localized: "Pilates", comment: "Workout type: Pilates")
        case .custom: String(localized: "Custom", comment: "Workout type: Custom/user-defined")
        }
    }

    /// Icon used in cross-platform UI surfaces (Watch + iPhone scheduled
    /// workout cards, summaries). All values MUST be valid SF Symbols
    /// because:
    ///   1. The Watch's `Assets.xcassets` does not bundle the iPhone's
    ///      custom-asset icons (`activity`, `yoga`, `stretch`,
    ///      `aiSummary`, etc.) — `Image("activity")` on the Watch resolves
    ///      to a no-op render and the icon badge appears empty.
    ///   2. SF Symbols ship with the OS so they render identically on
    ///      both platforms without per-bundle asset coordination.
    /// Past regression: `cardio` returned the custom asset name
    /// `"activity"` and the Watch's scheduled-workout card showed a blank
    /// circle for every cardio / yoga / flexibility / strength workout.
    public var iconName: String {
        switch self {
        case .strength: "figure.strengthtraining.traditional"
        case .cardio: "figure.run"
        case .hiit: "bolt.heart.fill"
        case .flexibility: "figure.flexibility"
        case .mixed: "figure.mixed.cardio"
        case .yoga: "figure.yoga"
        case .pilates: "figure.pilates"
        case .custom: "sparkles"
        }
    }

    /// Whether `iconName` is a system SF Symbol (`true`) or a custom asset
    /// (`false`). All cases are now SF Symbols — kept the property so
    /// callers using `AppIconView(name:isSystemIcon:)` don't need to be
    /// rewritten, and so a future case that legitimately uses a custom
    /// asset can flip the bit without any caller-side changes.
    public var isSystemIcon: Bool {
        switch self {
        case .strength, .cardio, .hiit, .flexibility, .mixed, .yoga, .pilates, .custom: true
        }
    }
}

// MARK: - WorkoutStatus

/// Workout status for tracking session state
public enum WorkoutStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case paused
    case completed
    case abandoned

    // MARK: Public

    public var displayName: String {
        switch self {
        case .notStarted: String(localized: "Not Started", comment: "Workout status: not yet started")
        case .inProgress: String(localized: "In Progress", comment: "Workout status: currently active")
        case .paused: String(localized: "Paused", comment: "Workout status: temporarily paused")
        case .completed: String(localized: "Completed", comment: "Workout status: finished")
        case .abandoned: String(localized: "Abandoned", comment: "Workout status: user gave up")
        }
    }
}

// MARK: - WorkoutGoalType

/// Workout goal types
public enum WorkoutGoalType: String, Codable, CaseIterable, Hashable, Sendable {
    case time
    case reps

    // MARK: Public

    public var displayName: String {
        switch self {
        case .time: String(localized: "Time", comment: "Workout goal type: time-based")
        case .reps: String(localized: "Reps", comment: "Workout goal type: repetition-based")
        }
    }
}

// MARK: - WorkoutWeightUnit

/// Weight units
public enum WorkoutWeightUnit: String, Codable, CaseIterable, Hashable, Sendable {
    case lbs
    case kg

    // MARK: Public

    public var symbol: String {
        self.rawValue
    }

    public func convert(_ value: Double, to unit: WorkoutWeightUnit) -> Double {
        if self == unit {
            return value
        }

        switch (self, unit) {
        case (.lbs, .kg):
            return value * 0.453592
        case (.kg, .lbs):
            return value * 2.20462
        default:
            return value
        }
    }
}

// MARK: - WorkoutSide

/// Side for unilateral exercises
public enum WorkoutSide: String, Codable, CaseIterable, Hashable, Sendable {
    case left
    case right

    // MARK: Public

    public var displayName: String {
        switch self {
        case .left: String(localized: "Left", comment: "Body side: left side for unilateral exercises")
        case .right: String(localized: "Right", comment: "Body side: right side for unilateral exercises")
        }
    }
}

// MARK: - WorkoutStepType

/// Step types for workout flow
public enum WorkoutStepType: String, Codable, CaseIterable, Hashable, Sendable {
    case exercise
    case recover
    case warmup
    case cooldown

    // MARK: Public

    public var displayName: String {
        switch self {
        case .exercise: String(localized: "Exercise", comment: "Workout step type: exercise")
        case .recover: String(localized: "Rest", comment: "Workout step type: rest/recovery")
        case .warmup: String(localized: "Warm Up", comment: "Workout step type: warm up")
        case .cooldown: String(localized: "Cool Down", comment: "Workout step type: cool down")
        }
    }
}
