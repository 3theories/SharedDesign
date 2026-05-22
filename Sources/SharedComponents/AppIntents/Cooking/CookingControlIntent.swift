import AppIntents
import Foundation

#if os(iOS)
    /// Cooking control intent for recipe Live Activity
    ///
    /// Provides cooking controls for Live Activity buttons.
    /// Used by the Lock Screen and Dynamic Island controls during recipe cooking.
    public struct CookingControlIntent: AppIntent, LiveActivityIntent {
        // MARK: Lifecycle

        public init() {
            self.action = .pause
        }

        public init(action: CookingAction) {
            self.action = action
        }

        // MARK: Public

        public static var title: LocalizedStringResource = "Control Cooking"

        public static var description = IntentDescription(
            "Control your active cooking session",
            categoryName: "Cooking"
        )

        /// The action to perform on the cooking session
        @Parameter(title: "Action", description: "The cooking control action")
        public var action: CookingAction

        @MainActor
        public func perform() async throws -> some IntentResult & ProvidesDialog {
            NotificationCenter.default.post(
                name: IntentNotification.cookingControlAction,
                object: nil,
                userInfo: ["action": self.action.rawValue]
            )

            return .result(dialog: IntentDialog(stringLiteral: self.action.confirmationMessage))
        }
    }

    // MARK: - Cooking Action Enum

    extension CookingControlIntent {
        public enum CookingAction: String, AppEnum, CaseIterable, Sendable {
            case pause
            case resume
            case next
            case previous

            // MARK: Public

            public static var typeDisplayRepresentation: TypeDisplayRepresentation {
                "Cooking Action"
            }

            public static var caseDisplayRepresentations: [CookingAction: DisplayRepresentation] {
                [
                    .pause: DisplayRepresentation(
                        title: "Pause Cooking",
                        subtitle: "Pause the current step timer",
                        image: .init(systemName: "pause.circle")
                    ),
                    .resume: DisplayRepresentation(
                        title: "Resume Cooking",
                        subtitle: "Resume the current step timer",
                        image: .init(systemName: "play.circle")
                    ),
                    .next: DisplayRepresentation(
                        title: "Next Step",
                        subtitle: "Move to the next cooking step",
                        image: .init(systemName: "forward")
                    ),
                    .previous: DisplayRepresentation(
                        title: "Previous Step",
                        subtitle: "Go back to the previous step",
                        image: .init(systemName: "backward")
                    )
                ]
            }

            /// Message to confirm the action was performed
            public var confirmationMessage: String {
                switch self {
                case .pause:
                    "Cooking paused"
                case .resume:
                    "Cooking resumed"
                case .next:
                    "Moving to next step"
                case .previous:
                    "Going back to previous step"
                }
            }
        }
    }

    // MARK: - App Shortcut Phrases

    extension CookingControlIntent {
        public static var parameterSummary: some ParameterSummary {
            Summary("\(\.$action) cooking")
        }
    }

    // MARK: - Convenience Factory Methods

    extension CookingControlIntent {
        /// Create a pause cooking intent
        public static var pause: CookingControlIntent {
            CookingControlIntent(action: .pause)
        }

        /// Create a resume cooking intent
        public static var resume: CookingControlIntent {
            CookingControlIntent(action: .resume)
        }

        /// Create a next step intent
        public static var next: CookingControlIntent {
            CookingControlIntent(action: .next)
        }

        /// Create a previous step intent
        public static var previous: CookingControlIntent {
            CookingControlIntent(action: .previous)
        }
    }
#endif
