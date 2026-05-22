import Foundation

/// Notification names for App Intent communication with the main app
///
/// Intents in extensions post these notifications. The main app's IntentHandler
/// observes them and performs the actual operations via repositories.
public enum IntentNotification {
    // MARK: - Workout Notifications

    /// Posted when a workout control action is triggered (pause/resume/next/skip/finish)
    /// UserInfo: ["action": WorkoutControlIntent.WorkoutAction]
    public static let workoutControlAction = Notification.Name("WorkoutControlAction")

    /// Posted when a workout should be started
    /// UserInfo: ["workoutId": UUID?] - nil means start today's scheduled workout
    public static let startWorkout = Notification.Name("IntentStartWorkout")

    /// Posted when today's workout should be skipped
    /// UserInfo: ["reason": String?]
    public static let skipWorkout = Notification.Name("IntentSkipWorkout")

    // MARK: - Cooking Notifications

    /// Posted when a cooking control action is triggered from Live Activity
    /// UserInfo: ["action": CookingControlIntent.CookingAction.rawValue]
    public static let cookingControlAction = Notification.Name("com.niora.cookingControlAction")

    // MARK: - Nutrition Notifications

    /// Posted when a quick meal should be logged
    /// UserInfo: ["mealType": String?, "description": String?]
    public static let logMeal = Notification.Name("IntentLogMeal")

    /// Posted when the Snap Meal camera should open
    /// UserInfo: ["mealType": String?]
    public static let snapMeal = Notification.Name("IntentSnapMeal")

    /// Posted when water intake should be logged
    /// UserInfo: ["amount": Double] - amount in milliliters
    public static let logWater = Notification.Name("IntentLogWater")

    /// Posted when the user wants to view today's workout
    public static let viewTodaysWorkout = Notification.Name("IntentViewTodaysWorkout")

    // MARK: - Fasting Notifications

    /// Posted when a fasting session should be started
    public static let startFasting = Notification.Name("IntentStartFasting")

    /// Posted when a fasting session should be ended
    public static let endFasting = Notification.Name("IntentEndFasting")

    // MARK: - Action Completion Notifications

    /// Posted when a contextual action has completed successfully
    /// This triggers a refresh of home view data and recommendations
    public static let contextualActionCompleted = Notification.Name("ContextualActionCompleted")

    /// Posted when a meal has been logged successfully
    /// Triggers refresh of nutrition data and recommendations
    public static let mealLogged = Notification.Name("MealLogged")

    /// Posted when water has been logged successfully
    /// Triggers refresh of hydration data and recommendations
    public static let waterLogged = Notification.Name("WaterLogged")

    // MARK: - Helper Methods

    /// Post a notification on the main thread
    @MainActor
    public static func post(_ name: Notification.Name, userInfo: [String: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
    }
}
