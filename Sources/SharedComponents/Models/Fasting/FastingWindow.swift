import Foundation

public enum FastingWindow: Int, Codable, CaseIterable, Hashable, Sendable {
    case eightHr = 8
    case twelve = 12
    case fourteen = 14
    case sixteen = 16
    case eighteen = 18
    case twenty = 20
    case twentyFour = 24

    // MARK: Public

    public var totalHrs: Int {
        self.rawValue
    }
    
    public static var schedulableWindows: [FastingWindow] {
        // Preventing users from having recurring 24 hrs fasting windows
        [.eightHr, .twelve, .fourteen, .sixteen, .eighteen, .twenty]
    }

    public var duration: TimeInterval {
        TimeInterval(self.totalHrs * 3600)
    }

    public var displayName: String {
        switch self {
        case .eightHr:
            "8:16"
        case .twelve:
            "12:12"
        case .fourteen:
            "14:10"
        case .sixteen:
            "16:8"
        case .eighteen:
            "18:6"
        case .twenty:
            "20:4"
        case .twentyFour:
            "24:0"
        }
    }

    public var eatingHours: Int {
        24 - self.totalHrs
    }

    public var fastingFraction: Double {
        Double(self.totalHrs) / 24.0
    }

    public var eatingFraction: Double {
        1.0 - self.fastingFraction
    }

    public var eatingDuration: TimeInterval {
        TimeInterval(self.eatingHours * 3600)
    }
}
