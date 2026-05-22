import AppIntents
import Foundation
#if canImport(ActivityKit) && os(iOS)
    import ActivityKit
    import os.log
#endif

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when an activity control action is triggered from Live Activity or Siri
    /// UserInfo contains "action" key with ActivityControlIntent.ActivityAction.rawValue
    public static let activityControlAction = Notification.Name("com.niora.activityControlAction")
}

#if os(iOS)
    /// Activity control intent for freeform and sport activities
    ///
    /// This provides activity controls for Siri, Shortcuts, and Live Activity integration.
    /// Used by the Live Activity buttons for controlling running, yoga, tennis, and other activities.
    ///
    /// Siri Phrases:
    /// - "Hey Siri, pause my activity"
    /// - "Hey Siri, resume my activity"
    /// - "Hey Siri, record a lap"
    /// - "Hey Siri, end my activity"
    public struct ActivityControlIntent: AppIntent, LiveActivityIntent {
        // MARK: Lifecycle

        public init() {
            self.action = .pause
        }

        public init(action: ActivityAction) {
            self.action = action
        }

        // MARK: Public

        public static var title: LocalizedStringResource = "Control Activity"

        public static var description = IntentDescription(
            "Control your active activity session",
            categoryName: "Activity"
        )

        /// The action to perform on the activity
        @Parameter(title: "Action", description: "The activity control action")
        public var action: ActivityAction

        @MainActor
        public func perform() async throws -> some IntentResult & ProvidesDialog {
            let log = Logger(subsystem: "com.3theories.niora", category: "LA-CTRL")
            log.info("[LA-CTRL] perform() begin action=\(self.action.rawValue, privacy: .public) processName=\(ProcessInfo.processInfo.processName, privacy: .public)")

            // Update the running Live Activity widget DIRECTLY here,
            // before posting the NotificationCenter side-effect. iOS
            // gives `LiveActivityIntent.perform()` a foreground-
            // equivalent runtime window; observer chains that dispatch
            // their `Activity.update()` to a downstream Task miss that
            // window and the widget visibly lags (sometimes until the
            // user manually foregrounds the app). Calling `update()`
            // inside `perform()` guarantees the system schedules the
            // widget refresh before our runtime window expires.
            await Self.applyOptimisticActivityUpdate(action: self.action, log: log)

            // Post notification so app-side logic (mesh submission,
            // VM state, mini-player) still runs. This handles the
            // structural pause/resume — the optimistic widget update
            // above just makes the visual feedback instant.
            log.info("[LA-CTRL] posting NotificationCenter .activityControlAction")
            NotificationCenter.default.post(
                name: .activityControlAction,
                object: nil,
                userInfo: ["action": self.action.rawValue]
            )

            log.info("[LA-CTRL] perform() returning")
            return .result(dialog: IntentDialog(stringLiteral: self.action.confirmationMessage))
        }

        /// Apply pause/resume directly to the running activity Live
        /// Activity widget. Runs in the intent's process (== app
        /// process for `LiveActivityIntent`), so we have permission
        /// to update its content state.
        @MainActor
        private static func applyOptimisticActivityUpdate(
            action: ActivityAction,
            log: Logger
        ) async {
            guard action == .pause || action == .resume else {
                log.debug("[LA-CTRL] skipping direct widget update — action is \(action.rawValue, privacy: .public)")
                return
            }

            let activities = Activity<ActivityLiveActivityAttributes>.activities
            log.info("[LA-CTRL] activities.count=\(activities.count, privacy: .public)")
            guard let activity = activities.first else {
                log.warning("[LA-CTRL] no running ActivityLiveActivity to update — bailing")
                return
            }
            log.info("[LA-CTRL] updating widget id=\(activity.id, privacy: .public) currentIsPaused=\(activity.content.state.isPaused, privacy: .public)")

            // The service writes the widget's content state with
            // `startTime = legacyEffectiveStartTime` (paused time
            // absorbed into the start) and `totalPausedTime = 0`.
            // The optimistic update must preserve that invariant:
            //   - on pause: stamp `lastPausedAt` so the elapsed-time
            //     formula (`elapsed -= now - lastPausedAt` while
            //     paused) freezes the visible counter.
            //   - on resume: shift `startTime` forward by the just-
            //     elapsed pause window so the widget's running formula
            //     (`elapsed = now - startTime - totalPausedTime`)
            //     resumes at the correct value. Mutating
            //     `totalPausedTime` here would double-count the pause
            //     once the next service-driven update arrives with
            //     `totalPausedTime = 0` again.
            var updated = activity.content.state
            let isPaused = action == .pause
            updated.isPaused = isPaused
            if isPaused {
                updated.lastPausedAt = Date()
            } else if let pausedAt = updated.lastPausedAt {
                let pausedDuration = Date().timeIntervalSince(pausedAt)
                if let start = updated.startTime {
                    updated.startTime = start.addingTimeInterval(pausedDuration)
                }
                updated.lastPausedAt = nil
            }

            // 15s stale window matches the rest of the LiveActivityManager
            // calls so the widget doesn't visually freeze even if no
            // follow-up update arrives.
            let staleDate = Date().addingTimeInterval(15)
            await activity.update(.init(state: updated, staleDate: staleDate))
            log.info("[LA-CTRL] widget update completed isPaused=\(isPaused, privacy: .public)")
        }
    }

    // MARK: - Activity Action Enum

    extension ActivityControlIntent {
        public enum ActivityAction: String, AppEnum, CaseIterable, Sendable {
            case pause
            case resume
            case recordLap
            case recordSet
            case endActivity

            // MARK: Public

            public static var typeDisplayRepresentation: TypeDisplayRepresentation {
                "Activity Action"
            }

            public static var caseDisplayRepresentations: [ActivityAction: DisplayRepresentation] {
                [
                    .pause: DisplayRepresentation(
                        title: "Pause Activity",
                        subtitle: "Pause your current activity",
                        image: .init(systemName: "pause.circle")
                    ),
                    .resume: DisplayRepresentation(
                        title: "Resume Activity",
                        subtitle: "Continue your activity",
                        image: .init(systemName: "play.circle")
                    ),
                    .recordLap: DisplayRepresentation(
                        title: "Record Lap",
                        subtitle: "Record a lap in your activity",
                        image: .init(systemName: "stopwatch")
                    ),
                    .recordSet: DisplayRepresentation(
                        title: "Record Set",
                        subtitle: "Record a set in your activity",
                        image: .init(systemName: "checkmark.circle")
                    ),
                    .endActivity: DisplayRepresentation(
                        title: "End Activity",
                        subtitle: "End your current activity",
                        image: .init(systemName: "stop.circle")
                    )
                ]
            }

            /// Message to confirm the action was performed
            public var confirmationMessage: String {
                switch self {
                case .pause:
                    "Activity paused"
                case .resume:
                    "Activity resumed"
                case .recordLap:
                    "Lap recorded"
                case .recordSet:
                    "Set recorded"
                case .endActivity:
                    "Activity ended"
                }
            }
        }
    }

    // MARK: - App Shortcut Phrases

    extension ActivityControlIntent {
        public static var parameterSummary: some ParameterSummary {
            Summary("\(\.$action) activity")
        }
    }

    // MARK: - Convenience Factory Methods

    extension ActivityControlIntent {
        /// Create a pause activity intent
        public static var pause: ActivityControlIntent {
            ActivityControlIntent(action: .pause)
        }

        /// Create a resume activity intent
        public static var resume: ActivityControlIntent {
            ActivityControlIntent(action: .resume)
        }

        /// Create a record lap intent
        public static var recordLap: ActivityControlIntent {
            ActivityControlIntent(action: .recordLap)
        }

        /// Create a record set intent
        public static var recordSet: ActivityControlIntent {
            ActivityControlIntent(action: .recordSet)
        }

        /// Create an end activity intent
        public static var endActivity: ActivityControlIntent {
            ActivityControlIntent(action: .endActivity)
        }
    }
#endif
