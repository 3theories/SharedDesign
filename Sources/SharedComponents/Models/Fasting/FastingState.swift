import Foundation

public enum FastingState: String, Codable, CaseIterable, Hashable, Sendable {
    case fasting
    case feasting
    case completed
    case waiting

    // MARK: Public

    public var displayName: String {
        switch self {
        case .fasting:
            "Fasting"
        case .feasting:
            "Eating Window"
        case .completed:
            "Completed"
        case .waiting:
            "Ready"
        }
    }

    public var title: String {
        switch self {
        case .fasting:
            "Fasting"
        case .feasting:
            "Eating"
        case .completed:
            "Completed"
        case .waiting:
            "Ready to Fast"
        }
    }

    public var isActive: Bool {
        switch self {
        case .fasting, .feasting:
            true
        case .completed, .waiting:
            false
        }
    }
}
