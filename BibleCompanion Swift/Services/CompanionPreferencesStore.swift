import Foundation
import Combine

final class CompanionPreferencesStore: ObservableObject {

    static let shared =
        CompanionPreferencesStore()


    @Published
    var selectedLens: CompanionLens {
        didSet {
            save()
        }
    }


    private let lensKey =
        "bibleCompanionSelectedLens"


    private init() {

        if let rawValue =
            UserDefaults.standard.string(
                forKey: lensKey
            ),
           let savedLens =
            CompanionLens(
                rawValue: rawValue
            ) {

            selectedLens =
                savedLens

        } else {

            selectedLens =
                .guide
        }
    }


    private func save() {

        UserDefaults.standard.set(
            selectedLens.rawValue,
            forKey: lensKey
        )
    }
}
