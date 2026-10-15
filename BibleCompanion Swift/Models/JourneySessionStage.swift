import Foundation

enum JourneySessionStage: String, Codable, CaseIterable {
    case introduction
    case reading
    case discussion
    case reflection
    case completed

    var title: String {
        switch self {
        case .introduction:
            return "Introduction"

        case .reading:
            return "Read"

        case .discussion:
            return "Discuss"

        case .reflection:
            return "Reflect"

        case .completed:
            return "Complete"
        }
    }

    var order: Int {
        switch self {
        case .introduction:
            return 0

        case .reading:
            return 1

        case .discussion:
            return 2

        case .reflection:
            return 3

        case .completed:
            return 4
        }
    }
}
