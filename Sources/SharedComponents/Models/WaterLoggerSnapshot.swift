import Foundation

// MARK: - WaterLoggerState

/// State for the Water Logger widget
public enum WaterLoggerState: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case goalReached = "goal_reached"
    case overGoal = "over_goal"
}

// MARK: - WaterLoggerSnapshot

/// Snapshot of water intake for widget display
public struct WaterLoggerSnapshot: Codable {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        id: String?,
        stateRawValue: String,
        currentIntakeMl: Int,
        dailyGoalMl: Int,
        hourlyIntake: [Int]?,
        lastLogAmountMl: Int?,
        lastLogTimeEpoch: Double?,
        updatedAtEpoch: Double
    ) {
        self.id = id
        self.stateRawValue = stateRawValue
        self.currentIntakeMl = currentIntakeMl
        self.dailyGoalMl = dailyGoalMl
        self.hourlyIntake = hourlyIntake
        self.lastLogAmountMl = lastLogAmountMl
        self.lastLogTimeEpoch = lastLogTimeEpoch
        self.updatedAtEpoch = updatedAtEpoch
    }

    // MARK: Public

    // MARK: - Identification

    public let id: String?

    // MARK: - State

    public let stateRawValue: String

    // MARK: - Water Data

    public let currentIntakeMl: Int
    public let dailyGoalMl: Int

    // MARK: - History (for sparkline visualization)

    /// Hourly intake for the day (up to 24 values)
    public let hourlyIntake: [Int]?

    // MARK: - Last Log Info

    public let lastLogAmountMl: Int?
    public let lastLogTimeEpoch: Double?

    // MARK: - Metadata

    public let updatedAtEpoch: Double

    public var state: WaterLoggerState {
        WaterLoggerState(rawValue: self.stateRawValue) ?? .notStarted
    }

    /// Progress toward daily water goal (0.0 to 1.0, clamped)
    /// Returns 0 for invalid goals or negative values
    public var progress: Double {
        guard self.dailyGoalMl > 0, self.currentIntakeMl >= 0 else {
            return 0
        }
        return min(Double(self.currentIntakeMl) / Double(self.dailyGoalMl), 1.0)
    }

    public var progressPercentage: Int {
        Int(self.progress * 100)
    }

    public var remainingMl: Int {
        max(0, self.dailyGoalMl - self.currentIntakeMl)
    }

    public var formattedIntake: String {
        let safeMl = max(0, currentIntakeMl)
        if safeMl >= 1000 {
            let liters = Double(safeMl) / 1000.0
            return Self.volumeNumberFormatter.string(from: NSNumber(value: liters)) ?? "\(liters)"
        }
        return "\(safeMl)"
    }

    public var formattedGoal: String {
        let safeMl = max(1, dailyGoalMl) // Minimum 1ml to avoid display issues
        if safeMl >= 1000 {
            let liters = Double(safeMl) / 1000.0
            return Self.volumeNumberFormatter.string(from: NSNumber(value: liters)) ?? "\(liters)"
        }
        return "\(safeMl)"
    }

    public var intakeUnit: String {
        max(0, self.currentIntakeMl) >= 1000
            ? String(localized: "L", comment: "Abbreviation for liters")
            : String(localized: "ml", comment: "Abbreviation for milliliters")
    }

    public var goalUnit: String {
        max(1, self.dailyGoalMl) >= 1000
            ? String(localized: "L", comment: "Abbreviation for liters")
            : String(localized: "ml", comment: "Abbreviation for milliliters")
    }

    public var formattedRemaining: String {
        if self.remainingMl >= 1000 {
            let liters = Double(remainingMl) / 1000.0
            let formatted = Self.volumeNumberFormatter.string(from: NSNumber(value: liters)) ?? "\(liters)"
            return String(localized: "\(formatted)L", comment: "Remaining water in liters, e.g. 1.5L")
        }
        return String(localized: "\(self.remainingMl)ml", comment: "Remaining water in milliliters, e.g. 500ml")
    }

    public var lastLogTimeFormatted: String? {
        guard let epoch = lastLogTimeEpoch else {
            return nil
        }
        let date = Date(timeIntervalSince1970: epoch)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: Private

    /// Locale-aware number formatter for volume values (1 fraction digit).
    private static let volumeNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}

// MARK: - WaterLoggerDataProvider

/// Data provider for Water Logger widget
public enum WaterLoggerDataProvider: WidgetDataProvider {
    public typealias SnapshotType = WaterLoggerSnapshot

    public static var snapshotKey: String {
        "water_logger_widget_snapshot_v1"
    }
}
