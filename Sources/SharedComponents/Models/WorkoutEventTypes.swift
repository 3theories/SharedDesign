import Foundation
import HealthKit

// MARK: - WorkoutEventType

public enum WorkoutEventType {
    public static let uiStateUpdate = "uiStateUpdate" // Deprecated - use specific events
    public static let exerciseChange = "exerciseChange"
    public static let roundChange = "roundChange"
    public static let workoutStart = "workoutStart"
    public static let workoutComplete = "workoutComplete"
    public static let workoutDismiss = "workoutDismiss"
    public static let stepNavigation = "stepNavigation"
}

// MARK: - HKWorkoutEvent Extensions

extension HKWorkoutEvent {
    /// Creates a workout event for UI state updates
    public static func uiStateEvent(state: WorkoutPlayerState) -> HKWorkoutEvent? {
        do {
            let encoder = JSONEncoder()
            let stateData = try encoder.encode(state)
            let stateString = String(data: stateData, encoding: .utf8) ?? ""

            let metadata: [String: Any] = [
                "eventType": WorkoutEventType.uiStateUpdate,
                "state": stateString,
                "timestamp": Date()
            ]

            return HKWorkoutEvent(
                type: .marker,
                dateInterval: DateInterval(start: Date(), duration: 0),
                metadata: metadata
            )
        } catch {
            print("Failed to create UI state event: \(error)")
            return nil
        }
    }

    /// Creates a workout event for exercise changes
    public static func exerciseChangeEvent(exerciseName: String, setIndex: Int, stepIndex: Int) -> HKWorkoutEvent {
        let metadata: [String: Any] = [
            "eventType": WorkoutEventType.exerciseChange,
            "exerciseName": exerciseName,
            "setIndex": setIndex,
            "stepIndex": stepIndex,
            "timestamp": Date()
        ]

        return HKWorkoutEvent(
            type: .marker,
            dateInterval: DateInterval(start: Date(), duration: 0),
            metadata: metadata
        )
    }

    /// Creates a workout event for round changes
    public static func roundChangeEvent(roundIndex: Int, roundName: String) -> HKWorkoutEvent {
        let metadata: [String: Any] = [
            "eventType": WorkoutEventType.roundChange,
            "roundIndex": roundIndex,
            "roundName": roundName,
            "timestamp": Date()
        ]

        // Use marker type instead of segment for round changes
        // Segment events require non-zero duration
        return HKWorkoutEvent(
            type: .marker,
            dateInterval: DateInterval(start: Date(), duration: 0),
            metadata: metadata
        )
    }

    /// Creates a workout start event
    public static func workoutStartEvent(workoutName: String, roundCount: Int) -> HKWorkoutEvent {
        let metadata: [String: Any] = [
            "eventType": WorkoutEventType.workoutStart,
            "workoutName": workoutName,
            "roundCount": roundCount,
            "timestamp": Date()
        ]

        return HKWorkoutEvent(
            type: .marker,
            dateInterval: DateInterval(start: Date(), duration: 0),
            metadata: metadata
        )
    }

    /// Creates a workout completion event
    public static func workoutCompleteEvent() -> HKWorkoutEvent {
        let metadata: [String: Any] = [
            "eventType": WorkoutEventType.workoutComplete,
            "timestamp": Date()
        ]

        return HKWorkoutEvent(
            type: .marker,
            dateInterval: DateInterval(start: Date(), duration: 0),
            metadata: metadata
        )
    }

    /// Creates a workout dismiss event
    public static func workoutDismissEvent() -> HKWorkoutEvent {
        let metadata: [String: Any] = [
            "eventType": WorkoutEventType.workoutDismiss,
            "timestamp": Date()
        ]

        return HKWorkoutEvent(
            type: .marker,
            dateInterval: DateInterval(start: Date(), duration: 0),
            metadata: metadata
        )
    }

    /// Creates a step navigation event
    public static func stepNavigationEvent(
        roundIndex: Int,
        setIndex: Int,
        stepIndex: Int,
        repeatCount: Int
    ) -> HKWorkoutEvent {
        let metadata: [String: Any] = [
            "eventType": WorkoutEventType.stepNavigation,
            "roundIndex": roundIndex,
            "setIndex": setIndex,
            "stepIndex": stepIndex,
            "repeatCount": repeatCount,
            "timestamp": Date()
        ]

        return HKWorkoutEvent(
            type: .marker,
            dateInterval: DateInterval(start: Date(), duration: 0),
            metadata: metadata
        )
    }
}

// MARK: - Parsing Helpers

extension HKWorkoutEvent {
    public var customEventType: String? {
        metadata?["eventType"] as? String
    }

    public func parseUIState() -> WorkoutPlayerState? {
        guard self.customEventType == WorkoutEventType.uiStateUpdate,
              let stateString = metadata?["state"] as? String,
              let stateData = stateString.data(using: .utf8) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(WorkoutPlayerState.self, from: stateData)
        } catch {
            print("Failed to parse UI state from event: \(error)")
            return nil
        }
    }
}
