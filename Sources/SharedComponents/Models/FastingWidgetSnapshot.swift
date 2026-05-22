import Foundation

public struct FastingWidgetSnapshot: Codable {
    // MARK: Lifecycle

    public init(
        id: String?,
        stateRawValue: String, // Changed to String to match FastingState enum
        windowHours: Int,
        startTimeEpoch: TimeInterval?,
        endTimeEpoch: TimeInterval?,
        updatedAtEpoch: TimeInterval,
        preferredStartHour: Int = FastingDefaults.preferredStartHour,
        preferredStartMinute: Int = FastingDefaults.preferredStartMinute
    ) {
        self.id = id
        self.stateRawValue = stateRawValue
        self.windowHours = windowHours
        self.startTimeEpoch = startTimeEpoch
        self.endTimeEpoch = endTimeEpoch
        self.updatedAtEpoch = updatedAtEpoch
        self.preferredStartHour = preferredStartHour
        self.preferredStartMinute = preferredStartMinute
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.stateRawValue = try container.decode(String.self, forKey: .stateRawValue)
        self.windowHours = try container.decode(Int.self, forKey: .windowHours)
        self.startTimeEpoch = try container.decodeIfPresent(TimeInterval.self, forKey: .startTimeEpoch)
        self.endTimeEpoch = try container.decodeIfPresent(TimeInterval.self, forKey: .endTimeEpoch)
        self.updatedAtEpoch = try container.decode(TimeInterval.self, forKey: .updatedAtEpoch)
        self.preferredStartHour = (try? container.decode(Int.self, forKey: .preferredStartHour)) ?? FastingDefaults.preferredStartHour
        self.preferredStartMinute = (try? container.decode(Int.self, forKey: .preferredStartMinute)) ?? FastingDefaults.preferredStartMinute
    }

    // MARK: Public

    public let id: String?
    public let stateRawValue: String // Changed to String to match FastingState enum
    public let windowHours: Int
    public let startTimeEpoch: TimeInterval?
    public let endTimeEpoch: TimeInterval?
    public let updatedAtEpoch: TimeInterval
    public let preferredStartHour: Int
    public let preferredStartMinute: Int

    /// Eating window end time aligned to the user's preferred fasting start time.
    /// Delegates to `FastingDefaults.eatingWindowEndTime` for the core calculation.
    public var eatingWindowEndTime: Date? {
        guard let startEpoch = startTimeEpoch,
              let endEpoch = endTimeEpoch else {
            return nil
        }

        return FastingDefaults.eatingWindowEndTime(
            startTime: Date(timeIntervalSince1970: startEpoch),
            endTime: Date(timeIntervalSince1970: endEpoch),
            preferredStartHour: preferredStartHour,
            preferredStartMinute: preferredStartMinute,
            windowHours: windowHours
        )
    }
}
