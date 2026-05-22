import AppIntents
import Foundation

#if os(iOS)
    /// Workout control intent with granular actions
    ///
    /// This provides workout controls for Siri, Shortcuts, and Live Activity integration.
    /// Used by the Live Activity buttons and Siri voice commands.
    ///
    /// Siri Phrases:
    /// - "Hey Siri, pause my workout"
    /// - "Hey Siri, resume my workout"
    /// - "Hey Siri, skip this exercise"
    /// - "Hey Siri, finish my workout"
    /// - "Hey Siri, what's next in my workout?"
    public struct WorkoutControlIntent: AppIntent, LiveActivityIntent {
        // MARK: Lifecycle

        public init() {
            self.action = .pause
        }

        public init(action: WorkoutAction) {
            self.action = action
        }

        // MARK: Public

        public static var title: LocalizedStringResource = "Control Workout"

        public static var description = IntentDescription(
            "Control your active workout session",
            categoryName: "Workout"
        )

        /// The action to perform on the workout
        @Parameter(title: "Action", description: "The workout control action")
        public var action: WorkoutAction

        @MainActor
        public func perform() async throws -> some IntentResult & ProvidesDialog {
            // Post notification using the shared notification name
            // This ensures both legacy and new observers receive the action
            NotificationCenter.default.post(
                name: NSNotification.Name("WorkoutControlAction"),
                object: nil,
                userInfo: ["action": self.action]
            )

            return .result(dialog: IntentDialog(stringLiteral: self.action.confirmationMessage))
        }
    }

    // MARK: - Workout Action Enum

    extension WorkoutControlIntent {
        public enum WorkoutAction: String, AppEnum, CaseIterable, Sendable {
            case pause
            case resume
            case next
            case skip
            case finish
            case previousExercise = "previous"

            // MARK: Public

            public static var typeDisplayRepresentation: TypeDisplayRepresentation {
                "Workout Action"
            }

            public static var caseDisplayRepresentations: [WorkoutAction: DisplayRepresentation] {
                [
                    .pause: DisplayRepresentation(
                        title: "Pause Workout",
                        subtitle: "Pause your current workout",
                        image: .init(systemName: "pause.circle")
                    ),
                    .resume: DisplayRepresentation(
                        title: "Resume Workout",
                        subtitle: "Continue your workout",
                        image: .init(systemName: "play.circle")
                    ),
                    .next: DisplayRepresentation(
                        title: "Next Exercise",
                        subtitle: "Move to the next exercise",
                        image: .init(systemName: "forward")
                    ),
                    .skip: DisplayRepresentation(
                        title: "Skip Exercise",
                        subtitle: "Skip the current exercise entirely",
                        image: .init(systemName: "forward.end")
                    ),
                    .finish: DisplayRepresentation(
                        title: "Finish Workout",
                        subtitle: "End your workout early",
                        image: .init(systemName: "checkmark.circle")
                    ),
                    .previousExercise: DisplayRepresentation(
                        title: "Previous Exercise",
                        subtitle: "Go back to the previous exercise",
                        image: .init(systemName: "backward")
                    )
                ]
            }

            /// Message to confirm the action was performed
            public var confirmationMessage: String {
                switch self {
                case .pause:
                    "Workout paused"
                case .resume:
                    "Workout resumed"
                case .next:
                    "Moving to next exercise"
                case .skip:
                    "Exercise skipped"
                case .finish:
                    "Workout finished"
                case .previousExercise:
                    "Going back to previous exercise"
                }
            }
        }
    }

    // MARK: - App Shortcut Phrases

    extension WorkoutControlIntent {
        public static var parameterSummary: some ParameterSummary {
            Summary("\(\.$action) workout")
        }
    }

    // MARK: - Convenience Factory Methods

    extension WorkoutControlIntent {
        /// Create a pause workout intent
        public static var pause: WorkoutControlIntent {
            WorkoutControlIntent(action: .pause)
        }

        /// Create a resume workout intent
        public static var resume: WorkoutControlIntent {
            WorkoutControlIntent(action: .resume)
        }

        /// Create a next exercise intent
        public static var next: WorkoutControlIntent {
            WorkoutControlIntent(action: .next)
        }

        /// Create a skip exercise intent
        public static var skip: WorkoutControlIntent {
            WorkoutControlIntent(action: .skip)
        }

        /// Create a finish workout intent
        public static var finish: WorkoutControlIntent {
            WorkoutControlIntent(action: .finish)
        }
    }
#endif
