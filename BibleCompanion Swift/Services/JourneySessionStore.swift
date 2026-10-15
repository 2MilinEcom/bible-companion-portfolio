import Foundation
import Combine

final class JourneySessionStore: ObservableObject {

    static let shared =
        JourneySessionStore()


    @Published
    private(set) var stages:
        [String: JourneySessionStage] = [:]


    private let storageKey =
        "bibleCompanionJourneySessions"


    private init() {
        load()
    }


    // MARK: - Key

    private func key(
        journeyID: String,
        checkpointID: String
    ) -> String {

        "\(journeyID)::\(checkpointID)"
    }


    // MARK: - Current Stage

    func stage(
        journeyID: String,
        checkpointID: String
    ) -> JourneySessionStage {

        let sessionKey =
            key(
                journeyID: journeyID,
                checkpointID: checkpointID
            )

        return stages[sessionKey]
            ?? .introduction
    }


    // MARK: - Set Stage

    func setStage(
        _ stage: JourneySessionStage,
        journeyID: String,
        checkpointID: String
    ) {

        let sessionKey =
            key(
                journeyID: journeyID,
                checkpointID: checkpointID
            )

        stages[sessionKey] =
            stage

        save()
    }


    // MARK: - Convenience

    func setStage(
        _ stage: JourneySessionStage,
        journey: JourneyPath,
        checkpoint: JourneyCheckpoint
    ) {

        setStage(
            stage,
            journeyID: journey.id,
            checkpointID: checkpoint.id
        )
    }


    func stage(
        journey: JourneyPath,
        checkpoint: JourneyCheckpoint
    ) -> JourneySessionStage {

        stage(
            journeyID: journey.id,
            checkpointID: checkpoint.id
        )
    }


    // MARK: - Reset Session

    func reset(
        journey: JourneyPath,
        checkpoint: JourneyCheckpoint
    ) {

        let sessionKey =
            key(
                journeyID: journey.id,
                checkpointID: checkpoint.id
            )

        stages.removeValue(
            forKey: sessionKey
        )

        save()
    }


    // MARK: - Storage

    private func save() {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        stages
                    )

            UserDefaults.standard.set(
                data,
                forKey: storageKey
            )

        } catch {

            print(
                "Journey session save error:",
                error
            )
        }
    }


    private func load() {

        guard let data =
                UserDefaults.standard.data(
                    forKey: storageKey
                )
        else {
            return
        }


        do {

            stages =
                try JSONDecoder()
                    .decode(
                        [String: JourneySessionStage].self,
                        from: data
                    )

        } catch {

            print(
                "Journey session load error:",
                error
            )
        }
    }
}
