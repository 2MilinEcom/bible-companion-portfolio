import Foundation

struct Perspective: Codable, Identifiable {

    let id: String
    let name: String
    let summary: String
    let coreArgument: String
    let supportingPassages: [String]
    let strongestObjection: String
}


struct PerspectivesResponse: Codable {

    let passageSummary: String
    let areasOfAgreement: [String]
    let perspectives: [Perspective]
}
