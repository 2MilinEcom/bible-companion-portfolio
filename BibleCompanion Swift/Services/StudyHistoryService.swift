import Foundation

final class StudyHistoryService {

    static let shared = StudyHistoryService()

    private let defaults = UserDefaults.standard

    private let historyKey = "studyHistory"

    private init() {}


    func loadActivities() -> [StudyActivity] {

        guard let data = defaults.data(
            forKey: historyKey
        ) else {
            return []
        }

        do {

            return try JSONDecoder().decode(
                [StudyActivity].self,
                from: data
            )

        } catch {

            print(
                "Failed to load study history: \(error)"
            )

            return []
        }
    }


    func saveActivities(
        _ activities: [StudyActivity]
    ) {

        do {

            let data = try JSONEncoder().encode(
                activities
            )

            defaults.set(
                data,
                forKey: historyKey
            )

        } catch {

            print(
                "Failed to save study history: \(error)"
            )
        }
    }


    func record(
        _ activity: StudyActivity
    ) {

        var activities = loadActivities()

        activities.insert(
            activity,
            at: 0
        )

        // Keep local history from growing forever.
        if activities.count > 50 {
            activities = Array(
                activities.prefix(50)
            )
        }

        saveActivities(
            activities
        )
    }


    func recordCompletedJourney(
        _ recommendation: JourneyRecommendation
    ) {

        let activity = StudyActivity.from(
            recommendation: recommendation
        )

        record(activity)
    }


    func clearHistory() {

        defaults.removeObject(
            forKey: historyKey
        )
    }
}
