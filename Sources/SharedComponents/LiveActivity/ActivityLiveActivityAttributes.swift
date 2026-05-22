import Foundation

#if canImport(ActivityKit) && os(iOS)
    import ActivityKit

    @available(iOS 16.1, *)
    public struct ActivityLiveActivityAttributes: ActivityAttributes {
        // MARK: Lifecycle

        /// Initialize for workout activities (structured workout programs)
        public init(workoutName: String, workoutType: String) {
            self.workoutName = workoutName
            self.workoutType = workoutType
            self.activityCategory = "workout"
        }

        /// Initialize for freeform or sport activities
        public init(activityName: String, activityCategory: String, sportType: String? = nil) {
            self.workoutName = activityName
            self.workoutType = sportType ?? activityCategory
            self.activityCategory = activityCategory
        }

        // MARK: Public

        public struct ContentState: Codable, Hashable {
            // MARK: Lifecycle

            public init(
                isStarted: Bool,
                isPaused: Bool,
                isComplete: Bool,
                currentRoundName: String,
                currentStepName: String,
                currentStepType: String,
                currentStepMetrics: String,
                nextStepName: String?,
                heartRate: Double,
                activeCalories: Double,
                startTime: Date? = nil,
                endTime: Date? = nil,
                lastPausedAt: Date? = nil,
                totalPausedTime: TimeInterval = 0,
                isTransitioning: Bool = false,
                transitionStepName: String? = nil,
                transitionSecondsRemaining: Int? = nil,
                stepStartTime: Date? = nil,
                stepEndTime: Date? = nil,
                stepTotalPausedTime: TimeInterval = 0,
                // Activity-specific fields
                activityCategory: String? = nil,
                activityName: String? = nil,
                trackingMode: String? = nil,
                lapCount: Int? = nil,
                currentLapTime: TimeInterval? = nil,
                bestLapTime: TimeInterval? = nil,
                setCount: Int? = nil,
                distanceMeters: Double? = nil,
                sportType: String? = nil,
                periodName: String? = nil
            ) {
                self.isStarted = isStarted
                self.isPaused = isPaused
                self.isComplete = isComplete
                self.currentRoundName = currentRoundName
                self.currentStepName = currentStepName
                self.currentStepType = currentStepType
                self.currentStepMetrics = currentStepMetrics
                self.nextStepName = nextStepName
                self.heartRate = heartRate
                self.activeCalories = activeCalories
                self.startTime = startTime
                self.endTime = endTime
                self.lastPausedAt = lastPausedAt
                self.totalPausedTime = totalPausedTime
                self.isTransitioning = isTransitioning
                self.transitionStepName = transitionStepName
                self.transitionSecondsRemaining = transitionSecondsRemaining
                self.stepStartTime = stepStartTime
                self.stepEndTime = stepEndTime
                self.stepTotalPausedTime = stepTotalPausedTime
                // Activity-specific fields
                self.activityCategory = activityCategory
                self.activityName = activityName
                self.trackingMode = trackingMode
                self.lapCount = lapCount
                self.currentLapTime = currentLapTime
                self.bestLapTime = bestLapTime
                self.setCount = setCount
                self.distanceMeters = distanceMeters
                self.sportType = sportType
                self.periodName = periodName
            }

            // MARK: Public

            public var isStarted: Bool
            public var isPaused: Bool
            public var isComplete: Bool
            public var currentRoundName: String
            public var currentStepName: String
            public var currentStepType: String
            public var currentStepMetrics: String
            public var nextStepName: String?

            public var heartRate: Double
            public var activeCalories: Double

            // Workout timing
            public var startTime: Date?
            public var endTime: Date?
            public var lastPausedAt: Date?
            public var totalPausedTime: TimeInterval

            // Transition state
            public var isTransitioning: Bool = false
            public var transitionStepName: String?
            public var transitionSecondsRemaining: Int?

            // Step timing for ProgressView(timerInterval:)
            // These define the time range for the progress bar animation
            // iOS handles smooth animation automatically - no need to push updates every second!
            public var stepStartTime: Date?
            public var stepEndTime: Date? // Used for ProgressView(timerInterval:)
            public var stepTotalPausedTime: TimeInterval

            // MARK: - Activity-specific fields (for freeform and sport activities)

            /// Activity category: "workout", "freeform", or "sport"
            public var activityCategory: String?

            /// Display name for the activity (e.g., "Running", "Tennis")
            public var activityName: String?

            /// Freeform-specific
            /// Tracking mode: "continuous", "laps", or "sets"
            public var trackingMode: String?
            /// Number of completed laps
            public var lapCount: Int?
            /// Current lap elapsed time in seconds
            public var currentLapTime: TimeInterval?
            /// Best (fastest) lap time in seconds
            public var bestLapTime: TimeInterval?
            /// Number of completed sets
            public var setCount: Int?
            /// Distance covered in meters
            public var distanceMeters: Double?

            /// Sport-specific
            /// Sport type (e.g., "tennis", "cricket", "basketball")
            public var sportType: String?
            /// Current period name (e.g., "1st Set", "Q2", "2nd Innings")
            public var periodName: String?

            // MARK: - Activity Type Helpers

            /// Whether this is a workout activity (structured workout programs)
            public var isWorkoutActivity: Bool {
                self.activityCategory == "workout" || self.activityCategory == nil
            }

            /// Whether this is a freeform activity (running, yoga, HIIT, etc.)
            public var isFreeformActivity: Bool {
                self.activityCategory == "freeform"
            }

            /// Whether this is a sport activity (tennis, cricket, basketball, etc.)
            public var isSportActivity: Bool {
                self.activityCategory == "sport"
            }

            // MARK: - Type-Safe Tracking Mode

            /// Whether tracking mode is "laps"
            public var isLapTracking: Bool {
                self.trackingMode == ActivityTrackingMode.laps.rawValue
            }

            /// Whether tracking mode is "sets"
            public var isSetTracking: Bool {
                self.trackingMode == ActivityTrackingMode.sets.rawValue
            }

            /// Whether tracking mode is "continuous"
            public var isContinuousTracking: Bool {
                self.trackingMode == nil || self.trackingMode == ActivityTrackingMode.continuous.rawValue
            }

            // MARK: - Validation Helpers

            /// Validates that sport activities have required period name
            /// Returns true if valid, logs warning if sport activity is missing period name
            public var hasPeriodNameIfRequired: Bool {
                if self.isSportActivity && self.periodName == nil {
                    // Note: This is expected at activity start before first period begins
                    return false
                }
                return true
            }

            /// Timer interval for elapsed time display (count-up timer for activities)
            /// Used with Text(timerInterval:countsDown:false) for smooth animation
            public var elapsedTimerInterval: ClosedRange<Date>? {
                guard let start = self.startTime, !self.isPaused else {
                    return nil
                }
                // For count-up timer, we set a far-future end date
                // iOS will animate from start to "now" smoothly
                return start...Date().addingTimeInterval(Self.maxTimerDuration)
            }

            /// Timer interval for ProgressView - only valid for time-based steps
            /// Returns nil if step is not time-based or times are not set
            public var stepTimerInterval: ClosedRange<Date>? {
                guard let start = self.stepStartTime,
                      let end = self.stepEndTime,
                      end > start else {
                    return nil
                }
                return start...end
            }

            /// Whether this is a time-based step (has timer interval)
            public var isTimedStep: Bool {
                self.stepTimerInterval != nil
            }

            /// Step duration in seconds (for display, parsed from metrics or calculated from interval)
            public var stepDuration: TimeInterval {
                if let start = self.stepStartTime, let end = self.stepEndTime {
                    return end.timeIntervalSince(start)
                }
                // Fallback to parsing from metrics
                guard let seconds = Double(self.currentStepMetrics) else {
                    return 0
                }
                return seconds
            }

            public var totalElapsedTime: TimeInterval {
                guard let start = self.startTime else {
                    return 0
                }
                let endDate = self.isComplete ? (self.endTime ?? Date()) : Date()
                var elapsed = endDate.timeIntervalSince(start)

                // Subtract total paused time
                elapsed -= self.totalPausedTime

                // If currently paused, also subtract time since last pause
                if self.isPaused, let pausedAt = self.lastPausedAt {
                    elapsed -= endDate.timeIntervalSince(pausedAt)
                }

                return max(0, elapsed)
            }

            // MARK: - Activity Icon

            /// Whether the activity icon is an SF Symbol (true) or a custom asset icon (false)
            public var activityIconIsSystemIcon: Bool {
                if self.isSportActivity {
                    return true
                } else {
                    let name = (self.activityName ?? "").lowercased()
                    if name.contains("hiit") || name.contains("interval") {
                        return false
                    }
                    return true
                }
            }

            /// Icon name for the current activity type
            /// Centralizes icon logic to avoid duplication across views
            public var activityIcon: String {
                if self.isSportActivity {
                    // Sport-specific icons
                    switch self.sportType?.lowercased() {
                    case "tennis": return "figure.tennis"
                    case "pickleball": return "figure.pickleball"
                    case "badminton": return "figure.badminton"
                    case "squash": return "figure.squash"
                    case "cricket": return "figure.cricket"
                    case "basketball": return "basketball"
                    case "soccer", "football": return "figure.soccer"
                    case "volleyball": return "figure.volleyball"
                    case "hockey": return "figure.hockey"
                    case "golf": return "figure.golf"
                    case "boxing": return "figure.boxing"
                    default: return "figure.run"
                    }
                } else {
                    // Freeform activity icons based on activity name
                    let name = (self.activityName ?? "").lowercased()
                    if name.contains("run") {
                        return "figure.run"
                    } else if name.contains("yoga") {
                        return "figure.yoga"
                    } else if name.contains("hiit") || name.contains("interval") {
                        return "fire"
                    } else if name.contains("cycling") || name.contains("bike") {
                        return "figure.outdoor.cycle"
                    } else if name.contains("swim") {
                        return "figure.pool.swim"
                    } else if name.contains("walk") {
                        return "figure.walk"
                    } else if name.contains("hike") {
                        return "figure.hiking"
                    } else if name.contains("row") {
                        return "figure.rower"
                    } else if name.contains("dance") {
                        return "figure.dance"
                    } else if name.contains("pilates") {
                        return "figure.pilates"
                    } else if name.contains("stretch") {
                        return "figure.flexibility"
                    } else {
                        return "figure.run"
                    }
                }
            }

            // MARK: - Distance Formatting

            /// Formats distance in meters to a locale-aware human-readable string.
            /// Uses `Measurement` and `MeasurementFormatter` for proper unit localization.
            /// Returns nil for nil, zero, or negative values.
            public func formattedDistance(_ meters: Double?) -> String? {
                guard let meters, meters > 0 else {
                    return nil
                }
                let measurement = Measurement(value: meters, unit: UnitLength.meters)
                let formatter = MeasurementFormatter()
                formatter.unitOptions = .naturalScale
                formatter.numberFormatter.maximumFractionDigits = meters >= 1000 ? 1 : 0
                return formatter.string(from: measurement)
            }

            // MARK: Private

            /// Maximum duration for elapsed timer (7 days in seconds)
            /// Used as far-future end date for count-up timer animation
            /// Note: Set to 7 days to support ultra-endurance activities
            private static let maxTimerDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        }

        public var workoutName: String
        public var workoutType: String

        /// Activity category: "workout", "freeform", or "sport"
        public var activityCategory: String
    }

#endif
