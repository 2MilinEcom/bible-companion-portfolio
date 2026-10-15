import Foundation


// =========================================================
// MARK: - AI Response
// =========================================================

struct AIResponse: Codable {

    let answer: String

    let responseID: String


    enum CodingKeys: String, CodingKey {

        case answer

        case responseID = "response_id"
    }
}


// =========================================================
// MARK: - AI Request
// =========================================================

struct AIRequest: Codable {

    let question: String

    let passage: String

    let mode: String

    let previousResponseID: String?

    let profile: SpiritualProfile


    /// Structured personalization context built locally by
    /// PersonalizationContextService.
    ///
    /// Kept separate from `question` so the backend can
    /// distinguish:
    ///
    /// - the user's current message
    /// - saved profile information
    /// - observed study history
    /// - user-written reflections
    /// - AI-generated summaries
    ///
    /// Optional for backwards compatibility with any screens
    /// that have not been migrated yet.
    let personalizationContext: PersonalizationContext?


    enum CodingKeys: String, CodingKey {

        case question

        case passage

        case mode

        case profile

        case previousResponseID = "previous_response_id"

        case personalizationContext = "personalization_context"
    }
}


// =========================================================
// MARK: - AI Service
// =========================================================

final class AIService {
    static let shared = AIService()
    private init() {}

    func ask(
        question: String,
        passage: String,
        mode: StudyMode,
        previousResponseID: String?,
        profile: SpiritualProfile,
        personalizationContext: PersonalizationContext? = nil
    ) async throws -> AIResponse {
        guard let url = URL(string: "\(APIConfig.baseURL)/ask") else {
            throw CompanionConnectionError.unavailable
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let body = AIRequest(
            question: question, passage: passage, mode: mode.rawValue,
            previousResponseID: previousResponseID, profile: profile,
            personalizationContext: personalizationContext)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        let (data, _) = try await CompanionHTTPClient.data(for: request)
        do {
            let result = try JSONDecoder().decode(AIResponse.self, from: data)
            guard !result.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CompanionConnectionError.invalidResponse
            }
            return result
        } catch {
            throw CompanionConnectionError.invalidResponse
        }
    }
}
