import Foundation

enum StudyActivityType: String, Codable, Equatable {
    case reading
    case guidedStudy
    case passageStudy
    case question
    case challenge
    case perspectives
}

struct StudyActivity: Codable, Identifiable {

    let id: UUID
    let date: Date

    let type: StudyActivityType
    let title: String
    let passage: String
    let topic: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: StudyActivityType,
        title: String,
        passage: String,
        topic: String
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.title = title
        self.passage = passage
        self.topic = topic
    }



    static func bibleReading(
        reference: String
    ) -> StudyActivity {

        StudyActivity(
            type: .reading,
            title: "Read \(reference)",
            passage: reference,
            topic: "Bible reading"
        )
    }


    static func from(
        recommendation: JourneyRecommendation
    ) -> StudyActivity {

        let activityType: StudyActivityType

        switch recommendation.type {

        case .guidedStudy:
            activityType = .guidedStudy

        case .passageStudy:
            activityType = .passageStudy

        case .question:
            activityType = .question
        }

        return StudyActivity(
            type: activityType,
            title: recommendation.title,
            passage: recommendation.passage,
            topic: recommendation.title
        )
    }
}
