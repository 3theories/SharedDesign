import Foundation

// MARK: - FastingDefaults

public enum FastingDefaults {
    public static let preferredStartHour: Int = 20
    public static let preferredStartMinute: Int = 0

    /// App group UserDefaults keys for sharing preferred start time with the widget extension
    public static let preferredStartHourKey = "fasting_preferred_start_hour"
    public static let preferredStartMinuteKey = "fasting_preferred_start_minute"

    /// Computes the eating window end time aligned to a preferred fasting start time.
    ///
    /// The eating window always ends at the next occurrence of the preferred fasting
    /// start time after `endTime` (when eating began). This ensures the feasting end
    /// time matches the planned start of the next fasting cycle, regardless of whether
    /// the user started fasting early or late relative to their preferred schedule.
    ///
    /// - Parameters:
    ///   - startTime: When the fasting period started.
    ///   - endTime: When the fasting period ended (eating began).
    ///   - preferredStartHour: Hour component of the preferred fasting start time.
    ///   - preferredStartMinute: Minute component of the preferred fasting start time.
    ///   - windowHours: Total fasting hours in the window (e.g. 16 for 16:8).
    /// - Returns: The aligned eating window end date, or nil if inputs are invalid.
    public static func eatingWindowEndTime(
        startTime: Date,
        endTime: Date,
        preferredStartHour: Int,
        preferredStartMinute: Int,
        windowHours: Int,
        calendar: Calendar = .current
    ) -> Date? {
        guard windowHours < 24 else { return nil }

        let targetOnEatingDay = calendar.date(
            bySettingHour: preferredStartHour,
            minute: preferredStartMinute,
            second: 0,
            of: endTime
        ) ?? endTime

        let target: Date = if targetOnEatingDay > endTime {
            targetOnEatingDay
        } else {
            calendar.date(byAdding: .day, value: 1, to: targetOnEatingDay) ?? targetOnEatingDay
        }

        return target
    }
}
