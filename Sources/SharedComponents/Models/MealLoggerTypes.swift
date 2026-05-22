import Foundation

// MARK: - MealLoggerState

public enum MealLoggerState: String, CaseIterable, Codable, Sendable {
    case notLogged = "not_logged" // No meals logged today
    case inProgress = "in_progress" // Currently logging meals
    case goalReached = "goal_reached" // Daily calorie goal reached
    case overGoal = "over_goal" // Exceeded daily goals
    case mealTime = "meal_time" // Reminder to log meal
}

// MARK: - MealLoggerSnapshot

public struct MealLoggerSnapshot: Codable, Sendable {
    // MARK: Lifecycle

    public init(
        id: String?,
        stateRawValue: String,
        todayCalories: Int,
        todayProtein: Int,
        todayCarbs: Int,
        todayFat: Int,
        dailyCalorieGoal: Int,
        dailyProteinGoal: Int,
        dailyCarbsGoal: Int,
        dailyFatGoal: Int,
        lastMealName: String?,
        lastMealTime: Double?,
        mealsLogged: Int,
        waterIntake: Int,
        dailyWaterGoal: Int,
        updatedAtEpoch: Double
    ) {
        self.id = id
        self.stateRawValue = stateRawValue
        self.todayCalories = todayCalories
        self.todayProtein = todayProtein
        self.todayCarbs = todayCarbs
        self.todayFat = todayFat
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyCarbsGoal = dailyCarbsGoal
        self.dailyFatGoal = dailyFatGoal
        self.lastMealName = lastMealName
        self.lastMealTime = lastMealTime
        self.mealsLogged = mealsLogged
        self.waterIntake = waterIntake
        self.dailyWaterGoal = dailyWaterGoal
        self.updatedAtEpoch = updatedAtEpoch
    }

    // MARK: Public

    public let id: String?
    public let stateRawValue: String
    public let todayCalories: Int
    public let todayProtein: Int
    public let todayCarbs: Int
    public let todayFat: Int
    public let dailyCalorieGoal: Int
    public let dailyProteinGoal: Int
    public let dailyCarbsGoal: Int
    public let dailyFatGoal: Int
    public let lastMealName: String?
    public let lastMealTime: Double?
    public let mealsLogged: Int
    public let waterIntake: Int // in ml
    public let dailyWaterGoal: Int // in ml
    public let updatedAtEpoch: Double

    public var state: MealLoggerState {
        MealLoggerState(rawValue: self.stateRawValue) ?? .notLogged
    }

    /// Progress toward calorie goal (0.0 to 1.0, clamped)
    /// Returns 0 for invalid goals or negative values
    public var caloriesProgress: Double {
        guard self.dailyCalorieGoal > 0, self.todayCalories >= 0 else {
            return 0
        }
        return min(Double(self.todayCalories) / Double(self.dailyCalorieGoal), 1.0)
    }

    /// Progress toward protein goal (0.0 to 1.0, clamped)
    public var proteinProgress: Double {
        guard self.dailyProteinGoal > 0, self.todayProtein >= 0 else {
            return 0
        }
        return min(Double(self.todayProtein) / Double(self.dailyProteinGoal), 1.0)
    }

    /// Progress toward carbs goal (0.0 to 1.0, clamped)
    public var carbsProgress: Double {
        guard self.dailyCarbsGoal > 0, self.todayCarbs >= 0 else {
            return 0
        }
        return min(Double(self.todayCarbs) / Double(self.dailyCarbsGoal), 1.0)
    }

    /// Progress toward fat goal (0.0 to 1.0, clamped)
    public var fatProgress: Double {
        guard self.dailyFatGoal > 0, self.todayFat >= 0 else {
            return 0
        }
        return min(Double(self.todayFat) / Double(self.dailyFatGoal), 1.0)
    }

    /// Progress toward water goal (0.0 to 1.0, clamped)
    public var waterProgress: Double {
        guard self.dailyWaterGoal > 0, self.waterIntake >= 0 else {
            return 0
        }
        return min(Double(self.waterIntake) / Double(self.dailyWaterGoal), 1.0)
    }

    /// Formatted calorie display with negative value protection
    public var formattedCalories: String {
        "\(max(0, self.todayCalories))"
    }

    /// Remaining calories to goal (never negative)
    public var remainingCalories: Int {
        max(0, self.dailyCalorieGoal - self.todayCalories)
    }
}

// MARK: - MealLoggerDataProvider

public enum MealLoggerDataProvider {
    // MARK: Public

    public static func saveSnapshot(_ snapshot: MealLoggerSnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot)

            // Save to BOTH UserDefaults AND file for redundancy
            // UserDefaults is always readable even when device is locked
            // This ensures the widget can always display data

            // 1. Always save to UserDefaults first (most reliable for widgets)
            if let userDefaults = UserDefaults(suiteName: suiteName) {
                userDefaults.set(data, forKey: self.snapshotKey)
                // Force synchronize for cross-process widget access
                userDefaults.synchronize()
            }

            // 2. Also save to file (faster access when available)
            if let url = snapshotURL() {
                try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            }
        } catch {
            print("   ❌ Failed to save meal logger snapshot: \(error)")
        }
    }

    public static func loadSnapshot() -> MealLoggerSnapshot? {
        // Try UserDefaults FIRST - it's always readable even when device is locked
        // This is the most reliable source for widgets
        if let userDefaults = UserDefaults(suiteName: suiteName) {
            if let data = userDefaults.data(forKey: snapshotKey) {
                do {
                    let snapshot = try JSONDecoder().decode(MealLoggerSnapshot.self, from: data)
                    return snapshot
                } catch {
                    print("   ⚠️ MealLoggerDataProvider: Failed to decode UserDefaults snapshot: \(error)")
                }
            }
        } else {
            print("   ⚠️ MealLoggerDataProvider: Could not access UserDefaults for suite: \(self.suiteName)")
        }

        // Fallback to file (may fail when device is locked due to file protection)
        if let url = snapshotURL() {
            do {
                let data = try Data(contentsOf: url)
                let snapshot = try JSONDecoder().decode(MealLoggerSnapshot.self, from: data)
                // Migrate to UserDefaults for future reliability
                if let userDefaults = UserDefaults(suiteName: suiteName) {
                    userDefaults.set(data, forKey: self.snapshotKey)
                    userDefaults.synchronize()
                }
                return snapshot
            } catch {
                print("   ⚠️ MealLoggerDataProvider: Failed to read file snapshot: \(error)")
            }
        }

        print("   ⚠️ MealLoggerDataProvider: No snapshot available from UserDefaults or file")
        return nil
    }

    // MARK: Private

    private static let suiteName = "group.com.3theories.niora"
    private static let snapshotKey = "mealLoggerSnapshot"

    private static func snapshotURL() -> URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName) else {
            print("   ❌ Missing container URL for app group: \(self.suiteName)")
            return nil
        }
        let dir = container.appendingPathComponent("widgets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(self.snapshotKey).json", conformingTo: .json)
    }
}
