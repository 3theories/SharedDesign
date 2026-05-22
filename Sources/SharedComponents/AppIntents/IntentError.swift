import Foundation

/// Errors that can occur during App Intent execution
public enum IntentError: LocalizedError {
    case repositoryNotInitialized
    case workoutNotFound
    case noScheduledWorkout
    case mealLoggingFailed
    case nutritionEstimationFailed
    case parsingFailed
    case hydrationLoggingFailed
    case featureDisabled(String)
    case networkError(Error)
    case unknown(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case .repositoryNotInitialized:
            "The app is still initializing. Please try again."
        case .workoutNotFound:
            "Could not find the requested workout."
        case .noScheduledWorkout:
            "No workout is scheduled for today."
        case .mealLoggingFailed:
            "Failed to log your meal. Please try again."
        case .nutritionEstimationFailed:
            "Could not estimate nutrition for your meal."
        case .parsingFailed:
            "Could not understand your meal description."
        case .hydrationLoggingFailed:
            "Failed to log water intake. Please try again."
        case let .featureDisabled(feature):
            "\(feature) is not enabled in your settings."
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        case let .unknown(message):
            message
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .repositoryNotInitialized:
            "Wait a moment and try again, or open the app first."
        case .workoutNotFound, .noScheduledWorkout:
            "Open the app to schedule a workout."
        case .mealLoggingFailed, .nutritionEstimationFailed, .hydrationLoggingFailed:
            "Check your internet connection and try again."
        case .parsingFailed:
            "Try describing your meal differently, for example: '2 eggs and toast'."
        case .featureDisabled:
            "Enable this feature in your app settings."
        case .networkError:
            "Check your internet connection and try again."
        case .unknown:
            nil
        }
    }
}
