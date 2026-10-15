import Foundation

enum StudyNoteType: String, Codable {
    case reflection
    case note
    case highlight
}


struct StudyNote: Identifiable, Codable, Hashable {

    let id: UUID

    let createdAt: Date
    var updatedAt: Date

    let journeyID: String?
    let checkpointID: String?

    let passage: String
    let title: String

    var text: String

    let type: StudyNoteType
}
