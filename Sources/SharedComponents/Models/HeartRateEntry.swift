import Foundation

public struct HeartRateEntry: Codable {
    // MARK: Lifecycle

    public init(timestamp: Date, heartRate: Double) {
        self.timestamp = timestamp
        self.heartRate = heartRate
    }

    // MARK: Public

    public let timestamp: Date
    public let heartRate: Double
}
