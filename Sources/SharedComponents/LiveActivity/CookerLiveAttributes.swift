import Foundation

#if canImport(ActivityKit) && os(iOS)
    import ActivityKit

    @available(iOS 16.1, *)
    public struct CookerLiveAttributes: ActivityAttributes {
        // MARK: Lifecycle

        public init(recipeName: String, totalSteps: Int) {
            self.recipeName = recipeName
            self.totalSteps = totalSteps
        }

        // MARK: Public

        public struct ContentState: Codable, Hashable {
            // MARK: Lifecycle

            public init(
                isPaused: Bool = false,
                isComplete: Bool = false,
                currentStepIndex: Int = 0,
                currentStepText: String = "",
                nextStepText: String? = nil,
                startTime: Date? = nil,
                totalPausedTime: TimeInterval = 0,
                lastPausedAt: Date? = nil,
                stepTimerEndTime: Date? = nil,
                stepTimerStartTime: Date? = nil,
                stepTimerPausedTime: TimeInterval = 0,
                hasStepTimer: Bool = false,
                stepLabel: String = "",
                stepProgress: Double = 0,
                totalSteps: Int = 0
            ) {
                self.isPaused = isPaused
                self.isComplete = isComplete
                self.currentStepIndex = currentStepIndex
                self.currentStepText = currentStepText
                self.nextStepText = nextStepText
                self.startTime = startTime
                self.totalPausedTime = totalPausedTime
                self.lastPausedAt = lastPausedAt
                self.stepTimerEndTime = stepTimerEndTime
                self.stepTimerStartTime = stepTimerStartTime
                self.stepTimerPausedTime = stepTimerPausedTime
                self.hasStepTimer = hasStepTimer
                self.stepLabel = stepLabel
                self.stepProgress = stepProgress
                self.totalSteps = totalSteps
            }

            // MARK: Public

            public var isPaused: Bool
            public var isComplete: Bool

            // Step info
            public var currentStepIndex: Int
            public var currentStepText: String
            public var nextStepText: String?

            // Overall elapsed time
            public var startTime: Date?
            public var totalPausedTime: TimeInterval
            public var lastPausedAt: Date?

            // Step timer (countdown)
            public var stepTimerEndTime: Date?
            public var stepTimerStartTime: Date?
            public var stepTimerPausedTime: TimeInterval
            public var hasStepTimer: Bool

            // Display helpers
            public var stepLabel: String
            public var stepProgress: Double
            public var totalSteps: Int

            /// Timer interval for elapsed time display (count-up timer)
            /// Used with Text(timerInterval:countsDown:false) for smooth animation
            public var elapsedTimerInterval: ClosedRange<Date>? {
                guard let start = self.startTime, !self.isPaused else {
                    return nil
                }
                return start...Date().addingTimeInterval(Self.maxTimerDuration)
            }

            /// Timer interval for step countdown progress bar
            /// Returns nil when paused to freeze the progress bar animation
            public var stepTimerInterval: ClosedRange<Date>? {
                guard let start = self.stepTimerStartTime,
                      let end = self.stepTimerEndTime,
                      end > start,
                      !self.isPaused else {
                    return nil
                }
                return start...end
            }

            /// Total elapsed cooking time
            public var totalElapsedTime: TimeInterval {
                guard let start = self.startTime else {
                    return 0
                }
                var elapsed = Date().timeIntervalSince(start)
                elapsed -= self.totalPausedTime
                if self.isPaused, let pausedAt = self.lastPausedAt {
                    elapsed -= Date().timeIntervalSince(pausedAt)
                }
                return max(0, elapsed)
            }

            // MARK: Private

            /// Maximum duration for elapsed timer (24 hours)
            private static let maxTimerDuration: TimeInterval = 24 * 60 * 60
        }

        // Static (set once at start)
        public var recipeName: String
        public var totalSteps: Int
    }
#endif
