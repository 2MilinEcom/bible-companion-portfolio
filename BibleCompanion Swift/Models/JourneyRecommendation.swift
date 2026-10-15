import Foundation

enum JourneyType: String, Codable {
    case guidedStudy
    case passageStudy
    case question
}

struct JourneyRecommendation: Codable {
    let title: String
    let reason: String
    let actionTitle: String
    let type: JourneyType
    let passage: String
    let suggestedQuestion: String
}
