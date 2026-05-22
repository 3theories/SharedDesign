import SwiftUI

#if os(iOS)
    import UIKit

    /// Haptic feedback styles (iOS only)
    public enum HapticStyle {
        case light
        case medium
        case heavy
        case soft
        case rigid
        case selection
        case success
        case warning
        case error

        // MARK: Internal

        /// Get the corresponding UIImpactFeedbackGenerator.FeedbackStyle
        var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle? {
            switch self {
            case .light: .light
            case .medium: .medium
            case .heavy: .heavy
            case .soft: .soft
            case .rigid: .rigid
            default: nil
            }
        }

        /// Get the corresponding UINotificationFeedbackGenerator.FeedbackType
        var notificationStyle: UINotificationFeedbackGenerator.FeedbackType? {
            switch self {
            case .success: .success
            case .warning: .warning
            case .error: .error
            default: nil
            }
        }
    }

    /// Haptic feedback manager (iOS only)
    public class HapticManager {
        // MARK: Lifecycle

        private init() {
            // Prepare generators
            self.impactGenerators.values.forEach { $0.prepare() }
            self.selectionGenerator.prepare()
            self.notificationGenerator.prepare()
        }

        // MARK: Public

        public static let shared = HapticManager()

        /// Trigger haptic feedback
        public func trigger(_ style: HapticStyle) {
            switch style {
            case .selection:
                self.selectionGenerator.selectionChanged()
                self.selectionGenerator.prepare() // Re-prepare for next use

            case .success, .warning, .error:
                if let notificationStyle = style.notificationStyle {
                    self.notificationGenerator.notificationOccurred(notificationStyle)
                    self.notificationGenerator.prepare() // Re-prepare for next use
                }

            default:
                if let impactStyle = style.impactStyle,
                   let generator = impactGenerators[impactStyle] {
                    generator.impactOccurred()
                    generator.prepare() // Re-prepare for next use
                }
            }
        }

        /// Trigger haptic feedback with intensity
        public func trigger(_ style: HapticStyle, intensity: CGFloat) {
            if let impactStyle = style.impactStyle,
               let generator = impactGenerators[impactStyle] {
                generator.impactOccurred(intensity: intensity)
                generator.prepare() // Re-prepare for next use
            } else {
                self.trigger(style) // Fallback to regular trigger
            }
        }

        // MARK: Private

        private let impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [
            .light: UIImpactFeedbackGenerator(style: .light),
            .medium: UIImpactFeedbackGenerator(style: .medium),
            .heavy: UIImpactFeedbackGenerator(style: .heavy),
            .soft: UIImpactFeedbackGenerator(style: .soft),
            .rigid: UIImpactFeedbackGenerator(style: .rigid)
        ]

        private let selectionGenerator = UISelectionFeedbackGenerator()
        private let notificationGenerator = UINotificationFeedbackGenerator()
    }

    /// Haptic feedback presets for common interactions
    public enum HapticPresets {
        /// Button interactions
        public enum Button {
            public static let tap = HapticStyle.light
            public static let press = HapticStyle.medium
            public static let release = HapticStyle.light
            public static let toggle = HapticStyle.selection
        }

        /// Navigation interactions
        public enum Navigation {
            public static let tabChange = HapticStyle.medium
            public static let pageSwipe = HapticStyle.light
            public static let pullToRefresh = HapticStyle.medium
            public static let reachEnd = HapticStyle.light
        }

        /// Gesture interactions
        public enum Gesture {
            public static let longPress = HapticStyle.medium
            public static let pinch = HapticStyle.light
            public static let rotate = HapticStyle.light
            public static let swipe = HapticStyle.light
        }

        /// Feedback interactions
        public enum Feedback {
            public static let success = HapticStyle.success
            public static let warning = HapticStyle.warning
            public static let error = HapticStyle.error
            public static let delete = HapticStyle.medium
        }

        /// Slider and picker interactions
        public enum Control {
            public static let sliderTick = HapticStyle.selection
            public static let pickerSelection = HapticStyle.selection
            public static let stepperIncrement = HapticStyle.light
            public static let switchToggle = HapticStyle.medium
        }

        // MARK: - Workout-Specific Haptic Patterns

        /// Workout-specific haptic feedback patterns
        public enum Workout {
            /// Set completion feedback
            public static let setComplete = HapticStyle.medium

            /// Exercise transition feedback
            public static let exerciseTransition = HapticStyle.heavy

            /// Rest period start
            public static let restStart = HapticStyle.light

            /// Rest period end/workout resume
            public static let restEnd = HapticStyle.medium

            /// Workout milestone reached (e.g., halfway point)
            public static let milestone = HapticStyle.success

            /// Workout completion
            public static let workoutComplete = HapticStyle.success

            /// Personal record achieved
            public static let personalRecord = HapticStyle.success

            /// Form warning (e.g., improper range of motion)
            public static let formWarning = HapticStyle.warning

            /// Rep count increment
            public static let repCount = HapticStyle.selection

            /// Weight adjustment
            public static let weightAdjust = HapticStyle.light

            /// Timer tick (every 10 seconds during rest)
            public static let timerTick = HapticStyle.light

            /// Intensity zone change
            public static let zoneChange = HapticStyle.medium
        }

        /// Heart rate and intensity zone feedback
        public enum HeartRate {
            /// Entering target zone
            public static let enterTargetZone = HapticStyle.medium

            /// Leaving target zone (too low)
            public static let belowTargetZone = HapticStyle.light

            /// Exceeding target zone (too high)
            public static let aboveTargetZone = HapticStyle.heavy

            /// Maximum heart rate warning
            public static let maxHRWarning = HapticStyle.warning

            /// Heart rate milestone (every 10 BPM change)
            public static let hrMilestone = HapticStyle.light
        }

        /// Nutrition tracking feedback
        public enum Nutrition {
            /// Meal logged
            public static let mealLogged = HapticStyle.light

            /// Daily goal reached
            public static let dailyGoalReached = HapticStyle.success

            /// Macro target hit (protein, carbs, fat)
            public static let macroTarget = HapticStyle.medium

            /// Calorie target reached
            public static let calorieTarget = HapticStyle.success

            /// Hydration milestone
            public static let hydrationMilestone = HapticStyle.light

            /// Nutrient deficiency warning
            public static let nutrientWarning = HapticStyle.warning

            /// Meal plan suggestion
            public static let mealSuggestion = HapticStyle.selection
        }

        /// Goal and achievement feedback
        public enum Achievement {
            /// Daily goal completed
            public static let dailyGoal = HapticStyle.success

            /// Weekly goal completed
            public static let weeklyGoal = HapticStyle.success

            /// Streak milestone (7, 30, 100 days)
            public static let streakMilestone = HapticStyle.success

            /// Badge earned
            public static let badgeEarned = HapticStyle.success

            /// Level up
            public static let levelUp = HapticStyle.success

            /// Challenge completed
            public static let challengeComplete = HapticStyle.success

            /// Progress milestone (25%, 50%, 75%)
            public static let progressMilestone = HapticStyle.medium
        }

        /// Chart and visualization interactions
        public enum Chart {
            /// Data point selection
            public static let dataPointSelect = HapticStyle.selection

            /// Chart segment tap
            public static let segmentTap = HapticStyle.light

            /// Chart zoom/pan gesture
            public static let chartGesture = HapticStyle.light

            /// Progress ring milestone (every 10%)
            public static let progressMilestone = HapticStyle.light

            /// Goal completion animation
            public static let goalComplete = HapticStyle.success

            /// Chart refresh/update
            public static let chartRefresh = HapticStyle.light

            /// Data export completed
            public static let exportComplete = HapticStyle.medium
        }

        /// Sleep and recovery feedback
        public enum Sleep {
            /// Bedtime reminder
            public static let bedtimeReminder = HapticStyle.light

            /// Sleep goal achieved
            public static let sleepGoalAchieved = HapticStyle.success

            /// Wake up time
            public static let wakeUp = HapticStyle.medium

            /// Deep sleep milestone
            public static let deepSleepMilestone = HapticStyle.light

            /// Recovery score update
            public static let recoveryScore = HapticStyle.medium

            /// Sleep quality alert
            public static let sleepQualityAlert = HapticStyle.warning
        }
    }

    // MARK: - Enhanced Haptic Manager with Workout Patterns

    #if os(iOS)
        extension HapticManager {
            /// Trigger a sequence of haptic feedback for complex interactions
            public func triggerSequence(_ patterns: [(HapticStyle, TimeInterval)]) {
                for (index, pattern) in patterns.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + pattern.1) {
                        self.trigger(pattern.0)
                    }
                }
            }

            /// Workout completion celebration sequence
            public func triggerWorkoutCompletion() {
                self.triggerSequence([
                    (.success, 0.0),
                    (.medium, 0.3),
                    (.success, 0.6)
                ])
            }

            /// Personal record celebration sequence
            public func triggerPersonalRecord() {
                self.triggerSequence([
                    (.success, 0.0),
                    (.heavy, 0.2),
                    (.success, 0.4),
                    (.medium, 0.7)
                ])
            }

            /// Rep counting pattern (rhythmic light taps)
            public func triggerRepCountPattern(reps: Int) {
                for rep in 0..<reps {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(rep) * 0.6) {
                        self.trigger(.light)
                    }
                }

                // Final confirmation
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(reps) * 0.6 + 0.3) {
                    self.trigger(.medium)
                }
            }

            /// Rest timer countdown pattern (last 3 seconds)
            public func triggerRestCountdown() {
                self.triggerSequence([
                    (.medium, 0.0), // 3
                    (.medium, 1.0), // 2
                    (.heavy, 2.0) // 1 - GO!
                ])
            }

            /// Progress milestone pattern (ascending intensity)
            public func triggerProgressMilestone(progress: Double) {
                let intensity: HapticStyle =
                    switch progress {
                    case 0.0..<0.25:
                        .light
                    case 0.25..<0.5:
                        .medium
                    case 0.5..<0.75:
                        .heavy
                    case 0.75..<1.0:
                        .success
                    default:
                        .success
                    }

                self.trigger(intensity)

                // Double tap for major milestones
                if progress >= 0.5 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.trigger(intensity)
                    }
                }
            }

            /// Heart rate zone transition pattern
            public func triggerZoneTransition(fromZone: Int, toZone: Int) {
                let pattern: HapticStyle =
                    if toZone > fromZone {
                        // Increasing intensity
                        toZone >= 4 ? .heavy : .medium
                    } else {
                        // Decreasing intensity
                        .light
                    }

                self.trigger(pattern)

                // Additional feedback for extreme zones
                if toZone == 5 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.trigger(.warning)
                    }
                }
            }
        }

    #else

        // MARK: - Workout Haptic Extensions for non-iOS platforms

        extension HapticManager {
            public func triggerSequence(_ patterns: [(HapticStyle, TimeInterval)]) {
                // No-op on non-iOS platforms
            }

            public func triggerWorkoutCompletion() {
                // No-op on non-iOS platforms
            }

            public func triggerPersonalRecord() {
                // No-op on non-iOS platforms
            }

            public func triggerRepCountPattern(reps: Int) {
                // No-op on non-iOS platforms
            }

            public func triggerRestCountdown() {
                // No-op on non-iOS platforms
            }

            public func triggerProgressMilestone(progress: Double) {
                // No-op on non-iOS platforms
            }

            public func triggerZoneTransition(fromZone: Int, toZone: Int) {
                // No-op on non-iOS platforms
            }
        }

    #endif

    /// View modifier for haptic feedback
    public struct HapticFeedbackModifier: ViewModifier {
        // MARK: Lifecycle

        public func body(content: Content) -> some View {
            content
                .onChange(of: self.trigger) { _, newValue in
                    if newValue {
                        HapticManager.shared.trigger(self.style)
                    }
                }
        }

        // MARK: Internal

        let style: HapticStyle
        let trigger: Bool
    }

    /// View modifier for tap haptic feedback
    public struct TapHapticModifier: ViewModifier {
        // MARK: Lifecycle

        public func body(content: Content) -> some View {
            content
                .onTapGesture {
                    HapticManager.shared.trigger(self.style)
                }
        }

        // MARK: Internal

        let style: HapticStyle
    }

    extension View {
        /// Add haptic feedback when a value changes
        public func hapticFeedback(_ style: HapticStyle, trigger: Bool) -> some View {
            modifier(HapticFeedbackModifier(style: style, trigger: trigger))
        }

        /// Add haptic feedback on tap
        public func hapticOnTap(_ style: HapticStyle = .light) -> some View {
            modifier(TapHapticModifier(style: style))
        }
    }

#else

    // MARK: - Haptic Stubs for non-iOS platforms

    /// Haptic style stub for non-iOS platforms
    public enum HapticStyle {
        case light, medium, heavy, soft, rigid, selection, success, warning, error
    }

    /// Haptic manager stub for non-iOS platforms
    public class HapticManager {
        // MARK: Lifecycle

        private init() { }

        // MARK: Public

        public static let shared = HapticManager()

        /// No-op haptic trigger for non-iOS platforms
        public func trigger(_ style: HapticStyle) {
            // No-op on non-iOS platforms
        }

        /// No-op haptic trigger with intensity for non-iOS platforms
        public func trigger(_ style: HapticStyle, intensity: CGFloat) {
            // No-op on non-iOS platforms
        }
    }

    /// Haptic presets stub for non-iOS platforms
    public enum HapticPresets {
        public enum Button {
            public static let tap = HapticStyle.light
            public static let press = HapticStyle.medium
            public static let release = HapticStyle.light
            public static let toggle = HapticStyle.selection
        }

        public enum Navigation {
            public static let tabChange = HapticStyle.selection
            public static let pageSwipe = HapticStyle.light
            public static let pullToRefresh = HapticStyle.medium
            public static let reachEnd = HapticStyle.light
        }
    }

    extension View {
        /// Add haptic feedback when a value changes (no-op on non-iOS)
        public func hapticFeedback(_ style: HapticStyle, trigger: Bool) -> some View {
            self // No-op
        }

        /// Add haptic feedback on tap (no-op on non-iOS)
        public func hapticOnTap(_ style: HapticStyle = .light) -> some View {
            self // No-op
        }
    }

#endif
