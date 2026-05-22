import Foundation
import Observation

// MARK: - ActivityCategory

/// Category of activity
public enum ActivityCategory: String, Codable, Sendable, CaseIterable {
    case workout
    case sport
    case freeform
    case run
    case hike
    case cycle
    case yoga
    case swim
    case indoor
    case rest

    // MARK: Public

    /// Whether this activity type uses freeform state (as opposed to workout or sport state)
    public var usesFreeformState: Bool {
        switch self {
        case .freeform, .run, .hike, .cycle, .yoga, .swim, .indoor, .rest:
            true
        case .workout, .sport:
            false
        }
    }
}

// MARK: - ActivityPlayerState

/// Unified activity player state using @Observable for automatic SwiftUI reactivity
/// Works for workouts, sports, and freeform activities
@Observable
public final class ActivityPlayerState: Codable {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        activityType: ActivityCategory,
        sportType: String? = nil,
        isStarted: Bool = false,
        isPaused: Bool = false,
        isComplete: Bool = false,
        isAbandoned: Bool = false,
        startTime: Date? = nil,
        endTime: Date? = nil,
        lastPausedAt: Date? = nil,
        totalPausedTime: TimeInterval = 0,
        currentHeartRate: Double = 0,
        activeCalories: Double = 0,
        distanceCovered: Double? = nil,
        currentCadence: Double = 0,
        currentStrideLength: Double = 0
    ) {
        self.activityType = activityType
        self.sportType = sportType
        self.isStarted = isStarted
        self.isPaused = isPaused
        self.isComplete = isComplete
        self.isAbandoned = isAbandoned
        self.startTime = startTime
        self.endTime = endTime
        self.lastPausedAt = lastPausedAt
        self.totalPausedTime = totalPausedTime
        self.currentHeartRate = currentHeartRate
        self.activeCalories = activeCalories
        self.distanceCovered = distanceCovered
        self.currentCadence = currentCadence
        self.currentStrideLength = currentStrideLength
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.activityType = try container.decode(ActivityCategory.self, forKey: .activityType)
        self.sportType = try container.decodeIfPresent(String.self, forKey: .sportType)
        self.isStarted = try container.decode(Bool.self, forKey: .isStarted)
        self.isPaused = try container.decode(Bool.self, forKey: .isPaused)
        self.isComplete = try container.decode(Bool.self, forKey: .isComplete)
        self.isAbandoned = try container.decodeIfPresent(Bool.self, forKey: .isAbandoned) ?? false
        self.startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        self.lastPausedAt = try container.decodeIfPresent(Date.self, forKey: .lastPausedAt)
        self.totalPausedTime = try container.decode(TimeInterval.self, forKey: .totalPausedTime)
        self.serverTotalActiveTime = try container.decodeIfPresent(Int.self, forKey: .serverTotalActiveTime) ?? 0
        self.lastSyncTime = try container.decodeIfPresent(Date.self, forKey: .lastSyncTime)
        self.currentHeartRate = try container.decode(Double.self, forKey: .currentHeartRate)
        self.activeCalories = try container.decode(Double.self, forKey: .activeCalories)
        self.distanceCovered = try container.decodeIfPresent(Double.self, forKey: .distanceCovered)
        self.currentCadence = try container.decodeIfPresent(Double.self, forKey: .currentCadence) ?? 0
        self.currentStrideLength = try container.decodeIfPresent(Double.self, forKey: .currentStrideLength) ?? 0
        self.cadenceHistory = try container.decodeIfPresent([CadenceSample].self, forKey: .cadenceHistory) ?? []
        self.strideLengthHistory = try container.decodeIfPresent([StrideLengthSample].self, forKey: .strideLengthHistory) ?? []
        self.heartRateHistory = try container.decodeIfPresent([HeartRateSample].self, forKey: .heartRateHistory) ?? []
        self.workoutState = try container.decodeIfPresent(WorkoutActivityState.self, forKey: .workoutState)
        self.sportState = try container.decodeIfPresent(SportActivityState.self, forKey: .sportState)
        self.freeformState = try container.decodeIfPresent(FreeformActivityState.self, forKey: .freeformState)
        self.activitySessionId = try container.decodeIfPresent(UUID.self, forKey: .activitySessionId)
        self.scheduledWorkoutId = try container.decodeIfPresent(UUID.self, forKey: .scheduledWorkoutId)
    }

    // MARK: Public

    // MARK: - Core State

    public var activityType: ActivityCategory
    public var sportType: String?

    public var isStarted: Bool
    public var isPaused: Bool
    public var isComplete: Bool
    public var isAbandoned: Bool

    // MARK: - Timing

    public var startTime: Date?
    public var endTime: Date?
    public var lastPausedAt: Date?
    public var totalPausedTime: TimeInterval

    /// Server-authoritative timing data
    public var serverTotalActiveTime: Int = 0
    public var lastSyncTime: Date?

    public var activeCalories: Double
    public var distanceCovered: Double? // meters
    public var totalElevationGain: Double? // meters
    public var currentCadence: Double = 0 // steps per minute
    public var currentStrideLength: Double = 0 // meters
    public var cadenceHistory: [CadenceSample] = []
    public var strideLengthHistory: [StrideLengthSample] = []
    public var heartRateHistory: [HeartRateSample] = []

    // MARK: - Observation Version

    /// Increment to force SwiftUI observation on nested struct changes
    /// SwiftUI's @Observable may not detect nested struct mutations reliably
    /// Changing this property forces observation to trigger UI updates
    public private(set) var stateVersion: Int = 0

    // MARK: - Sync

    public var activitySessionId: UUID?
    public var scheduledWorkoutId: UUID?

    public var totalElapsedTime: TimeInterval {
        self.calculateElapsedTime(at: Date())
    }

    // MARK: - Health Metrics

    public var currentHeartRate: Double {
        didSet {
            if oldValue != self.currentHeartRate {
                self.heartRateHistory.append(
                    HeartRateSample(timestamp: Date(), value: self.currentHeartRate)
                )
            }
        }
    }

    public var averageCadence: Double {
        guard !self.cadenceHistory.isEmpty else { return 0 }
        let sum = self.cadenceHistory.reduce(0) { $0 + $1.value }
        return sum / Double(self.cadenceHistory.count)
    }

    public var averageStrideLength: Double {
        guard !self.strideLengthHistory.isEmpty else { return 0 }
        let sum = self.strideLengthHistory.reduce(0) { $0 + $1.value }
        return sum / Double(self.strideLengthHistory.count)
    }

    public var averageHeartRate: Double {
        guard !self.heartRateHistory.isEmpty else {
            return 0
        }
        let sum = self.heartRateHistory.reduce(0) { $0 + $1.value }
        return sum / Double(self.heartRateHistory.count)
    }

    public var maxHeartRate: Double {
        self.heartRateHistory.map(\.value).max() ?? 0
    }

    // MARK: - Convenience Accessors

    /// Whether the activity is currently active (started but not completed)
    public var isActive: Bool {
        self.isStarted && !self.isComplete
    }

    /// Alias for totalElapsedTime for backward compatibility
    public var elapsedTime: TimeInterval {
        self.totalElapsedTime
    }

    /// Alias for activeCalories for backward compatibility
    public var caloriesBurned: Double {
        self.activeCalories
    }

    // MARK: - Workout-Specific (used when activityType == .workout)

    public var workoutState: WorkoutActivityState? {
        didSet { self.stateVersion += 1 }
    }

    // MARK: - Sport-Specific (used when activityType == .sport)

    public var sportState: SportActivityState? {
        didSet { self.stateVersion += 1 }
    }

    // MARK: - Freeform-Specific (used when activityType == .freeform)

    public var freeformState: FreeformActivityState? {
        didSet { self.stateVersion += 1 }
    }

    /// Calculate elapsed time at a specific point in time
    /// This is used by TimelineView for real-time updates
    /// - Parameter date: The reference date to calculate elapsed time at
    /// - Returns: The total elapsed time (excluding paused time)
    public func calculateElapsedTime(at date: Date) -> TimeInterval {
        // Use server-authoritative timing if available
        if self.serverTotalActiveTime > 0, let syncTime = lastSyncTime {
            var elapsed = TimeInterval(self.serverTotalActiveTime)
            if !self.isPaused && !self.isComplete {
                let timeSinceSync = date.timeIntervalSince(syncTime)
                elapsed += timeSinceSync
            }
            return max(0, elapsed)
        }

        // Calculate from local timing
        guard let start = startTime else {
            return 0
        }
        let end = self.isComplete ? (self.endTime ?? date) : date
        var elapsed = end.timeIntervalSince(start)
        elapsed -= self.totalPausedTime

        // If currently paused, don't count time since pause started
        if self.isPaused, let pausedAt = lastPausedAt {
            elapsed -= end.timeIntervalSince(pausedAt)
        }

        return max(0, elapsed)
    }

    /// Calculate total elapsed time (alias for calculateElapsedTime)
    public func calculateTotalElapsedTime() -> TimeInterval {
        self.calculateElapsedTime(at: Date())
    }

    public func start() {
        self.start(at: Date())
    }

    /// Start the activity at a specific time (for synchronizing lap timer with activity start)
    public func start(at time: Date) {
        self.isStarted = true
        self.isPaused = false
        self.startTime = time
    }

    // MARK: - Safe Initialization Methods

    /// Initialize state from external source (Watch sync, backend restore)
    /// CRITICAL: This NEVER overwrites timing - preserves source timing
    /// Use this when receiving state from another device or restoring from server
    public func initializeFromExternal(
        isStarted: Bool,
        isPaused: Bool,
        startTime: Date?,
        totalElapsedTime: TimeInterval = 0,
        totalPausedTime: TimeInterval = 0
    ) {
        self.isStarted = isStarted
        self.isPaused = isPaused
        self.startTime = startTime
        self.totalPausedTime = totalPausedTime

        // Use server-authoritative timing
        if totalElapsedTime > 0 {
            self.serverTotalActiveTime = Int(totalElapsedTime)
            self.lastSyncTime = Date()
        }
    }

    /// Start activity locally (user pressed Start on THIS device)
    /// This is the ONLY method that should set startTime to current time for new activities
    /// Do NOT call this method when syncing from Watch or restoring state
    public func startLocally(at time: Date = Date()) {
        guard !self.isStarted else {
            return
        }
        self.isStarted = true
        self.isPaused = false
        self.startTime = time
    }

    public func pause() {
        guard !self.isPaused else {
            return
        }

        // CRITICAL: Capture the current elapsed time BEFORE setting isPaused
        // This is necessary because calculateElapsedTime doesn't add timeSinceSync when paused
        // If we have server-authoritative timing, update it to include time since last sync
        if self.serverTotalActiveTime > 0, let syncTime = self.lastSyncTime {
            let timeSinceSync = Date().timeIntervalSince(syncTime)
            self.serverTotalActiveTime += Int(timeSinceSync)
            self.lastSyncTime = Date()
        }

        self.isPaused = true
        self.lastPausedAt = Date()

        // Note: Lap paused time will be accumulated on resume
    }

    public func resume() {
        guard self.isPaused else {
            return
        }
        if let pausedAt = lastPausedAt {
            let pausedDuration = Date().timeIntervalSince(pausedAt)
            self.totalPausedTime += pausedDuration

            // Also track lap-specific paused time for freeform activities
            if var freeformState = self.freeformState,
               freeformState.currentLapStartTime != nil {
                freeformState.currentLapPausedTime += pausedDuration
                self.freeformState = freeformState
            }
        }
        self.isPaused = false
        self.lastPausedAt = nil

        // CRITICAL: when using server-authoritative timing (state restored from
        // backend with `serverTotalActiveTime + lastSyncTime`), the elapsed
        // display path is `serverTotalActiveTime + (now - lastSyncTime)` while
        // not paused. If we don't reset `lastSyncTime` here, the audio-prep +
        // countdown + paused-elsewhere window between the previous lastSyncTime
        // and now gets counted as active running — adding bogus seconds to the
        // resumed elapsed display. Reset to NOW so subsequent ticks measure
        // from the actual resume instant.
        if self.serverTotalActiveTime > 0 {
            self.lastSyncTime = Date()
        }
    }

    public func complete() {
        self.isComplete = true
        self.isPaused = false
        self.endTime = Date()
    }

    public func abandon() {
        self.isComplete = true
        self.isAbandoned = true
        self.isPaused = false
        self.endTime = Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.activityType, forKey: .activityType)
        try container.encodeIfPresent(self.sportType, forKey: .sportType)
        try container.encode(self.isStarted, forKey: .isStarted)
        try container.encode(self.isPaused, forKey: .isPaused)
        try container.encode(self.isComplete, forKey: .isComplete)
        try container.encode(self.isAbandoned, forKey: .isAbandoned)
        try container.encodeIfPresent(self.startTime, forKey: .startTime)
        try container.encodeIfPresent(self.endTime, forKey: .endTime)
        try container.encodeIfPresent(self.lastPausedAt, forKey: .lastPausedAt)
        try container.encode(self.totalPausedTime, forKey: .totalPausedTime)
        try container.encode(self.serverTotalActiveTime, forKey: .serverTotalActiveTime)
        try container.encodeIfPresent(self.lastSyncTime, forKey: .lastSyncTime)
        try container.encode(self.currentHeartRate, forKey: .currentHeartRate)
        try container.encode(self.activeCalories, forKey: .activeCalories)
        try container.encodeIfPresent(self.distanceCovered, forKey: .distanceCovered)
        try container.encode(self.currentCadence, forKey: .currentCadence)
        try container.encode(self.currentStrideLength, forKey: .currentStrideLength)
        try container.encode(self.cadenceHistory, forKey: .cadenceHistory)
        try container.encode(self.strideLengthHistory, forKey: .strideLengthHistory)
        try container.encode(self.heartRateHistory, forKey: .heartRateHistory)
        try container.encodeIfPresent(self.workoutState, forKey: .workoutState)
        try container.encodeIfPresent(self.sportState, forKey: .sportState)
        try container.encodeIfPresent(self.freeformState, forKey: .freeformState)
        try container.encodeIfPresent(self.activitySessionId, forKey: .activitySessionId)
        try container.encodeIfPresent(self.scheduledWorkoutId, forKey: .scheduledWorkoutId)
    }

    // MARK: Private

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case activityType, sportType
        case isStarted, isPaused, isComplete, isAbandoned
        case startTime, endTime, lastPausedAt, totalPausedTime
        case serverTotalActiveTime, lastSyncTime
        case currentHeartRate, activeCalories, distanceCovered
        case currentCadence, currentStrideLength, cadenceHistory, strideLengthHistory
        case heartRateHistory
        case workoutState, sportState, freeformState
        case activitySessionId, scheduledWorkoutId
    }
}

// MARK: - HeartRateSample

public struct HeartRateSample: Codable, Sendable {
    // MARK: Lifecycle

    public init(timestamp: Date, value: Double) {
        self.timestamp = timestamp
        self.value = value
    }

    // MARK: Public

    public let timestamp: Date
    public let value: Double
}

// MARK: - CadenceSample

public struct CadenceSample: Codable, Sendable {
    // MARK: Lifecycle

    public init(timestamp: Date, value: Double) {
        self.timestamp = timestamp
        self.value = value
    }

    // MARK: Public

    public let timestamp: Date
    public let value: Double // steps per minute
}

// MARK: - StrideLengthSample

public struct StrideLengthSample: Codable, Sendable {
    // MARK: Lifecycle

    public init(timestamp: Date, value: Double) {
        self.timestamp = timestamp
        self.value = value
    }

    // MARK: Public

    public let timestamp: Date
    public let value: Double // meters
}

// MARK: - WorkoutActivityState

/// State specific to structured workouts
public struct WorkoutActivityState: Codable, Sendable {
    // MARK: Lifecycle

    public init(
        currentRoundIndex: Int = 0,
        currentSetIndex: Int = 0,
        currentStepIndex: Int = 0,
        currentRepeatCount: Int = 1,
        completedSteps: Int = 0,
        totalSteps: Int = 0,
        stepProgress: Double = 0,
        stepStartTime: Date? = nil,
        stepTotalPausedTime: TimeInterval = 0
    ) {
        self.currentRoundIndex = currentRoundIndex
        self.currentSetIndex = currentSetIndex
        self.currentStepIndex = currentStepIndex
        self.currentRepeatCount = currentRepeatCount
        self.completedSteps = completedSteps
        self.totalSteps = totalSteps
        self.stepProgress = stepProgress
        self.stepStartTime = stepStartTime
        self.stepTotalPausedTime = stepTotalPausedTime
    }

    // MARK: Public

    public var currentRoundIndex: Int
    public var currentSetIndex: Int
    public var currentStepIndex: Int
    public var currentRepeatCount: Int
    public var completedSteps: Int
    public var totalSteps: Int
    public var stepProgress: Double
    public var stepStartTime: Date?
    public var stepTotalPausedTime: TimeInterval
}

// MARK: - SportActivityState

/// State specific to sports with scoring
public struct SportActivityState: Codable, Sendable {
    // MARK: Lifecycle

    public init(
        currentPeriodIndex: Int = 0,
        userScore: ScoreState = ScoreState(),
        opponentScore: ScoreState = ScoreState(),
        scoringHistory: [ScoreEventState] = [],
        opponent: String? = nil,
        matchType: String? = nil,
        isUserServing: Bool = true,
        isUserBatting: Bool = true,
        isMatchComplete: Bool = false,
        winner: String? = nil,
        engineScoreState: EngineScoreSnapshot? = nil,
        periods: [PeriodState] = [],
        periodConfig: PeriodConfig? = nil
    ) {
        self.currentPeriodIndex = currentPeriodIndex
        self.userScore = userScore
        self.opponentScore = opponentScore
        self.scoringHistory = scoringHistory
        self.opponent = opponent
        self.matchType = matchType
        self.isUserServing = isUserServing
        self.isUserBatting = isUserBatting
        self.isMatchComplete = isMatchComplete
        self.winner = winner
        self.engineScoreState = engineScoreState
        self.periods = periods
        self.periodConfig = periodConfig
    }

    // MARK: Public

    public var currentPeriodIndex: Int
    public var userScore: ScoreState
    public var opponentScore: ScoreState
    public var scoringHistory: [ScoreEventState]
    public var opponent: String?
    public var matchType: String?

    /// Serve tracking (for tennis, pickleball, etc.)
    public var isUserServing: Bool

    /// Batting tracking (for cricket and innings-based sports)
    /// In innings-based sports, only the batting team scores
    public var isUserBatting: Bool

    // Match completion
    public var isMatchComplete: Bool
    public var winner: String? // "user" or "opponent"

    /// Detailed score state from engine (for complex sports like tennis)
    public var engineScoreState: EngineScoreSnapshot?

    // Period/innings tracking (for cricket, soccer, basketball, etc.)
    public var periods: [PeriodState]
    public var periodConfig: PeriodConfig?

    // MARK: - Period Helpers

    /// Get current period state
    public var currentPeriod: PeriodState? {
        guard self.currentPeriodIndex < self.periods.count else {
            return nil
        }
        return self.periods[self.currentPeriodIndex]
    }

    /// Get period display name (e.g., "1st Innings", "2nd Half", "Q3")
    public var currentPeriodDisplayName: String? {
        guard let config = self.periodConfig else {
            return nil
        }
        return config.periodName(for: self.currentPeriodIndex + 1)
    }

    /// Check if all periods are complete
    public var allPeriodsComplete: Bool {
        guard let config = self.periodConfig else {
            return false
        }
        return self.periods.count >= config.totalPeriods && self.periods.allSatisfy(\.isComplete)
    }

    /// Check if this is an innings-based sport (only batting team scores)
    public var isInningsBased: Bool {
        guard let config = self.periodConfig else {
            return false
        }
        return config.periodType == .innings
    }

    /// Get the current batting team's score
    public var battingTeamScore: ScoreState {
        self.isUserBatting ? self.userScore : self.opponentScore
    }

    /// Get the bowling/fielding team's score (previous innings total)
    public var fieldingTeamScore: ScoreState {
        self.isUserBatting ? self.opponentScore : self.userScore
    }

    /// Get batting team label
    public var battingTeamLabel: String {
        self.isUserBatting ? "You" : (self.opponent ?? "Opponent")
    }

    /// Get bowling team label
    public var bowlingTeamLabel: String {
        self.isUserBatting ? (self.opponent ?? "Opponent") : "You"
    }

    /// Whether this sport uses scoring (most sports do, some meditation/flow activities don't)
    public var hasScoring: Bool {
        get { true } // Default to true, can be set to false for non-scoring activities
        set { /* Allow setting but default behavior is true */ }
    }

    /// Alias for currentPeriodDisplayName (for sync compatibility)
    public var currentPeriodName: String? {
        get { self.currentPeriodDisplayName }
        set { /* Read-only computed property */ }
    }

    /// Start a new period
    public mutating func startPeriod() {
        let periodNumber = self.periods.count + 1
        let period = PeriodState(
            periodNumber: periodNumber,
            startTime: Date(),
            userScore: 0,
            opponentScore: 0
        )
        self.periods.append(period)
        self.currentPeriodIndex = self.periods.count - 1
    }

    /// End the current period
    public mutating func endCurrentPeriod() {
        guard self.currentPeriodIndex < self.periods.count else {
            return
        }
        self.periods[self.currentPeriodIndex].endTime = Date()
        self.periods[self.currentPeriodIndex].isComplete = true
    }

    /// Update score for current period
    public mutating func updatePeriodScore(userPoints: Int = 0, opponentPoints: Int = 0) {
        guard self.currentPeriodIndex < self.periods.count else {
            return
        }
        self.periods[self.currentPeriodIndex].userScore += userPoints
        self.periods[self.currentPeriodIndex].opponentScore += opponentPoints
    }

    /// Switch batting teams (for innings-based sports)
    public mutating func switchBatting() {
        self.isUserBatting.toggle()
    }
}

// MARK: - PeriodState

/// Represents a single period/half/innings/quarter in a sport
public struct PeriodState: Codable, Sendable, Identifiable {
    // MARK: Lifecycle

    public init(
        id: UUID = UUID(),
        periodNumber: Int,
        startTime: Date,
        endTime: Date? = nil,
        userScore: Int = 0,
        opponentScore: Int = 0,
        isComplete: Bool = false,
        events: [ScoreEventState] = []
    ) {
        self.id = id
        self.periodNumber = periodNumber
        self.startTime = startTime
        self.endTime = endTime
        self.userScore = userScore
        self.opponentScore = opponentScore
        self.isComplete = isComplete
        self.events = events
    }

    // MARK: Public

    public let id: UUID
    public let periodNumber: Int
    public let startTime: Date
    public var endTime: Date?
    public var userScore: Int
    public var opponentScore: Int
    public var isComplete: Bool
    public var events: [ScoreEventState]

    /// Duration of the period (if complete)
    public var duration: TimeInterval? {
        guard let end = self.endTime else {
            return nil
        }
        return end.timeIntervalSince(self.startTime)
    }
}

// MARK: - PeriodConfig

/// Configuration for period-based sports
public struct PeriodConfig: Codable, Sendable, Equatable {
    // MARK: Lifecycle

    public init(
        periodType: PeriodType,
        totalPeriods: Int,
        periodDuration: TimeInterval? = nil
    ) {
        self.periodType = periodType
        self.totalPeriods = totalPeriods
        self.periodDuration = periodDuration
    }

    // MARK: Public

    // MARK: - Sport Presets

    /// Cricket - 2 innings
    public static let cricket = PeriodConfig(periodType: .innings, totalPeriods: 2)

    /// T20 Cricket - 2 innings, 20 overs each (120 balls = ~80 minutes per innings)
    public static let cricketT20 = PeriodConfig(periodType: .innings, totalPeriods: 2)

    /// Soccer - 2 halves, 45 minutes each
    public static let soccer = PeriodConfig(periodType: .half, totalPeriods: 2, periodDuration: 45 * 60)

    /// Basketball - 4 quarters, 12 minutes each
    public static let basketball = PeriodConfig(periodType: .quarter, totalPeriods: 4, periodDuration: 12 * 60)

    /// Tennis - Best of 3 sets
    public static let tennisBestOf3 = PeriodConfig(periodType: .set, totalPeriods: 3)

    /// Tennis - Best of 5 sets
    public static let tennisBestOf5 = PeriodConfig(periodType: .set, totalPeriods: 5)

    /// Volleyball - Best of 5 sets
    public static let volleyball = PeriodConfig(periodType: .set, totalPeriods: 5)

    /// Badminton - Best of 3 games
    public static let badminton = PeriodConfig(periodType: .game, totalPeriods: 3)

    /// Hockey - 3 periods, 20 minutes each
    public static let hockey = PeriodConfig(periodType: .period, totalPeriods: 3, periodDuration: 20 * 60)

    public let periodType: PeriodType
    public let totalPeriods: Int
    public let periodDuration: TimeInterval? // nil for untimed (like cricket innings)

    /// Get locale-aware display name for a specific period number.
    /// Uses `String(localized:)` so period names can be translated.
    public func periodName(for number: Int) -> String {
        let ordinal = Self.ordinalString(number)
        switch self.periodType {
        case .innings:
            return String(localized: "\(ordinal) Innings", comment: "Ordinal innings label, e.g. 1st Innings")
        case .half:
            return number == 1
                ? String(localized: "1st Half", comment: "First half of a game")
                : String(localized: "2nd Half", comment: "Second half of a game")
        case .quarter:
            return String(localized: "Q\(number)", comment: "Quarter abbreviation, e.g. Q1")
        case .set:
            return String(localized: "\(ordinal) Set", comment: "Ordinal set label, e.g. 1st Set")
        case .game:
            return String(localized: "Game \(number)", comment: "Game number label, e.g. Game 1")
        case .period:
            return String(localized: "\(ordinal) Period", comment: "Ordinal period label, e.g. 1st Period")
        case .round:
            return String(localized: "Round \(number)", comment: "Round number label, e.g. Round 1")
        case .over:
            return String(localized: "Over \(number)", comment: "Cricket over number label, e.g. Over 1")
        }
    }

    // MARK: Private

    /// Locale-aware ordinal formatter (produces "1st", "2nd", "3rd" etc. per locale).
    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    private static func ordinalString(_ number: Int) -> String {
        self.ordinalFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - PeriodType

/// Type of period for different sports
public enum PeriodType: String, Codable, Sendable {
    case innings // Cricket
    case half // Soccer, American Football
    case quarter // Basketball, American Football
    case set // Tennis, Volleyball
    case game // Badminton, Table Tennis
    case period // Hockey
    case round // Boxing, MMA
    case over // Cricket overs
}

// MARK: - EngineScoreSnapshot

/// Snapshot of score engine state for display purposes
public struct EngineScoreSnapshot: Codable, Sendable, Equatable {
    // MARK: Lifecycle

    public init(
        userPrimary: String = "0",
        userSecondary: String? = nil,
        userTertiary: String? = nil,
        userDetail: String? = nil,
        opponentPrimary: String = "0",
        opponentSecondary: String? = nil,
        opponentTertiary: String? = nil,
        opponentDetail: String? = nil,
        periodName: String? = nil,
        currentPeriod: Int? = nil,
        totalPeriods: Int? = nil,
        matchInfo: String? = nil
    ) {
        self.userPrimary = userPrimary
        self.userSecondary = userSecondary
        self.userTertiary = userTertiary
        self.userDetail = userDetail
        self.opponentPrimary = opponentPrimary
        self.opponentSecondary = opponentSecondary
        self.opponentTertiary = opponentTertiary
        self.opponentDetail = opponentDetail
        self.periodName = periodName
        self.currentPeriod = currentPeriod
        self.totalPeriods = totalPeriods
        self.matchInfo = matchInfo
    }

    // MARK: Public

    // User score
    public var userPrimary: String
    public var userSecondary: String?
    public var userTertiary: String?
    public var userDetail: String?

    // Opponent score
    public var opponentPrimary: String
    public var opponentSecondary: String?
    public var opponentTertiary: String?
    public var opponentDetail: String?

    // Period info
    public var periodName: String?
    public var currentPeriod: Int?
    public var totalPeriods: Int?

    /// Match info (e.g., "Second Set • Your Serve")
    public var matchInfo: String?
}

// MARK: - ScoreState

public struct ScoreState: Codable, Sendable {
    // MARK: Lifecycle

    public init(points: Int = 0, displayValue: String = "0") {
        self.points = points
        self.displayValue = displayValue
    }

    // MARK: Public

    public var points: Int
    public var displayValue: String
}

// MARK: - ScoreEventState

public struct ScoreEventState: Codable, Sendable {
    // MARK: Lifecycle

    public init(timestamp: Date, eventType: String, scorer: String, points: Int) {
        self.timestamp = timestamp
        self.eventType = eventType
        self.scorer = scorer
        self.points = points
    }

    // MARK: Public

    public let timestamp: Date
    public let eventType: String
    public let scorer: String // "user" or "opponent"
    public let points: Int
}

// MARK: - FreeformActivityState

/// State specific to freeform activities (yoga, runs, walks, HIIT)
public struct FreeformActivityState: Codable, Sendable {
    // MARK: Lifecycle

    public init(
        activityName: String,
        notes: String? = nil,
        intensity: String? = nil,
        location: String? = nil,
        trackingMode: ActivityTrackingMode = .continuous
    ) {
        self.activityName = activityName
        self.notes = notes
        self.intensity = intensity
        self.location = location
        self.laps = []
        self.currentLapStartTime = nil
        self.sets = []
        self.currentSetNumber = 1
        self.trackingMode = trackingMode
    }

    // MARK: Public

    public var activityName: String
    public var notes: String?
    public var intensity: String? // "light", "moderate", "vigorous"
    public var location: String?

    // Lap tracking (for running, cycling, swimming)
    public var laps: [LapState]
    public var currentLapStartTime: Date?
    public var currentLapPausedTime: TimeInterval = 0

    // Set tracking (for HIIT, strength-style activities)
    public var sets: [SetState]
    public var currentSetNumber: Int

    /// Activity mode
    public var trackingMode: ActivityTrackingMode

    /// Get the best (fastest) lap
    public var bestLap: LapState? {
        self.laps.min { $0.duration < $1.duration }
    }

    /// Get average lap time
    public var averageLapTime: TimeInterval? {
        guard !self.laps.isEmpty else {
            return nil
        }
        let totalTime = self.laps.reduce(0) { $0 + $1.duration }
        return totalTime / Double(self.laps.count)
    }

    /// Get total reps across all sets
    public var totalReps: Int {
        self.sets.compactMap(\.reps).reduce(0, +)
    }

    /// Get total set time
    public var totalSetTime: TimeInterval {
        self.sets.compactMap(\.duration).reduce(0, +)
    }

    // MARK: - Convenience Properties (for sync)

    /// Current lap number (completed laps + 1)
    /// Shows "Lap 1" when starting, "Lap 2" after completing first lap, etc.
    /// Returns 0 if lap tracking hasn't started yet (currentLapStartTime == nil)
    public var lapCount: Int {
        get {
            // Only show "current lap number" if lap tracking has started
            if self.currentLapStartTime != nil {
                self.laps.count + 1
            } else {
                self.laps.count
            }
        }
        set { /* Read-only convenience property */ }
    }

    /// Number of *recorded* sets — mirrors `laps.count`-style semantics.
    /// The watch chip hides this when zero, so the previous `sets.count + 1`
    /// made running/walking activities (which never record sets) always show
    /// "1". Use `currentSetNumber` for the "in-progress" label ("Set N").
    public var setCount: Int {
        get { self.sets.count }
        set { /* Read-only convenience property */ }
    }

    /// Best lap time (shortest duration)
    public var bestLapTime: TimeInterval? {
        get { self.bestLap?.duration }
        set { /* Read-only convenience property */ }
    }

    // MARK: - Lap Helpers

    /// Start tracking a new lap
    public mutating func startLap(at time: Date = Date()) {
        self.currentLapStartTime = time
        self.currentLapPausedTime = 0 // Reset paused time for new lap
    }

    /// Complete current lap and start a new one
    public mutating func recordLap(
        at time: Date = Date(),
        distance: Double? = nil,
        heartRate: Double? = nil,
        calories: Double? = nil
    ) {
        guard let startTime = self.currentLapStartTime else {
            return
        }

        // Calculate lap duration excluding paused time
        var lapDuration = time.timeIntervalSince(startTime)
        lapDuration -= self.currentLapPausedTime
        lapDuration = max(0, lapDuration)

        let lapNumber = self.laps.count + 1

        let lap = LapState(
            lapNumber: lapNumber,
            startTime: startTime,
            endTime: time,
            duration: lapDuration,
            distance: distance,
            averageHeartRate: heartRate,
            calories: calories
        )

        self.laps.append(lap)
        self.currentLapStartTime = time // Start next lap immediately
        self.currentLapPausedTime = 0 // Reset paused time for new lap
    }

    /// Get current lap duration
    /// - Parameters:
    ///   - time: The reference time to calculate duration at
    ///   - isPaused: Whether the activity is currently paused
    ///   - lastPausedAt: The timestamp when the activity was last paused
    /// - Returns: The lap duration excluding paused time
    public func currentLapDuration(
        at time: Date = Date(),
        isPaused: Bool = false,
        lastPausedAt: Date? = nil
    ) -> TimeInterval? {
        guard let startTime = self.currentLapStartTime else {
            return nil
        }

        var elapsed = time.timeIntervalSince(startTime)

        // Subtract total paused time for this lap
        elapsed -= self.currentLapPausedTime

        // If currently paused, subtract time since pause started
        if isPaused, let pausedAt = lastPausedAt {
            elapsed -= time.timeIntervalSince(pausedAt)
        }

        return max(0, elapsed)
    }

    // MARK: - Set Helpers

    /// Record completing a set
    public mutating func recordSet(
        at time: Date = Date(),
        reps: Int? = nil,
        duration: TimeInterval? = nil,
        weight: Double? = nil,
        heartRate: Double? = nil,
        calories: Double? = nil
    ) {
        let set = SetState(
            setNumber: self.currentSetNumber,
            completedAt: time,
            reps: reps,
            duration: duration,
            weight: weight,
            averageHeartRate: heartRate,
            calories: calories
        )

        self.sets.append(set)
        self.currentSetNumber += 1
    }
}

// MARK: - ActivityTrackingMode

/// Determines how the activity tracks progress
public enum ActivityTrackingMode: String, Codable, Sendable, Equatable {
    /// Continuous timing (default) - just tracks total time
    case continuous

    /// Lap-based - tracks individual laps (running, cycling, swimming)
    case laps

    /// Set-based - tracks sets/reps (HIIT, strength)
    case sets

    /// Interval-based - tracks work/rest intervals
    case intervals
}

// MARK: - LapState

/// Represents a single lap in a lap-based activity
public struct LapState: Codable, Sendable, Identifiable, Equatable {
    // MARK: Lifecycle

    public init(
        id: UUID = UUID(),
        lapNumber: Int,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        distance: Double? = nil,
        averageHeartRate: Double? = nil,
        calories: Double? = nil
    ) {
        self.id = id
        self.lapNumber = lapNumber
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.distance = distance
        self.averageHeartRate = averageHeartRate
        self.calories = calories
    }

    // MARK: Public

    public let id: UUID
    public let lapNumber: Int
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    public let distance: Double? // meters
    public let averageHeartRate: Double?
    public let calories: Double?

    /// Format duration as MM:SS or HH:MM:SS
    public var formattedDuration: String {
        let minutes = Int(self.duration) / 60
        let seconds = Int(self.duration) % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Calculate pace (min/km or min/mi) if distance is available
    public func pace(inMiles: Bool = false) -> String? {
        guard let distance = self.distance, distance > 0 else {
            return nil
        }
        let distanceInUnit = inMiles ? distance / 1609.34 : distance / 1000.0
        let paceSeconds = self.duration / distanceInUnit
        let paceMinutes = Int(paceSeconds) / 60
        let paceRemainingSeconds = Int(paceSeconds) % 60
        return String(format: "%d:%02d", paceMinutes, paceRemainingSeconds)
    }
}

// MARK: - SetState

/// Represents a single set in a set-based activity
public struct SetState: Codable, Sendable, Identifiable, Equatable {
    // MARK: Lifecycle

    public init(
        id: UUID = UUID(),
        setNumber: Int,
        completedAt: Date,
        reps: Int? = nil,
        duration: TimeInterval? = nil,
        weight: Double? = nil,
        averageHeartRate: Double? = nil,
        calories: Double? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.completedAt = completedAt
        self.reps = reps
        self.duration = duration
        self.weight = weight
        self.averageHeartRate = averageHeartRate
        self.calories = calories
    }

    // MARK: Public

    public let id: UUID
    public let setNumber: Int
    public let completedAt: Date
    public let reps: Int?
    public let duration: TimeInterval? // for timed sets
    public let weight: Double? // for weighted exercises (kg)
    public let averageHeartRate: Double?
    public let calories: Double?

    /// Format set info as a locale-aware readable string.
    /// Uses `String(localized:)` for translatable parts and `DateComponentsFormatter` for durations.
    /// Creates formatter per call since `allowedUnits` varies by duration value.
    public var summary: String {
        var parts: [String] = []

        if let reps = self.reps {
            parts.append(String(localized: "\(reps) reps", comment: "Number of repetitions in a set"))
        }

        if let duration = self.duration {
            let durationFormatter = DateComponentsFormatter()
            durationFormatter.unitsStyle = .abbreviated
            durationFormatter.zeroFormattingBehavior = .dropAll
            let seconds = Int(duration)
            durationFormatter.allowedUnits = seconds >= 60 ? [.minute, .second] : [.second]
            if let formatted = durationFormatter.string(from: duration) {
                parts.append(formatted)
            }
        }

        if let weight = self.weight {
            let measurement = Measurement(value: weight, unit: UnitMass.kilograms)
            let formatter = MeasurementFormatter()
            formatter.unitOptions = .providedUnit
            formatter.numberFormatter.maximumFractionDigits = 1
            formatter.numberFormatter.minimumFractionDigits = 1
            parts.append(formatter.string(from: measurement))
        }

        return parts.isEmpty
            ? String(localized: "Set \(self.setNumber)", comment: "Set number label, e.g. Set 1")
            : parts.joined(separator: " \u{00B7} ")
    }
}
