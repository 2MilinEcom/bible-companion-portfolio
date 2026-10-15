import Foundation


// =========================================================
// MARK: - Perspectives Request
// =========================================================

struct PerspectivesRequest:
    Codable {

    let passage:
        String

    let profile:
        SpiritualProfile

    /// Structured personalization context for this request.
    ///
    /// Kept separate from the passage/profile so the backend
    /// can distinguish:
    ///
    /// - explicit profile information
    /// - observed study history
    /// - user-written reflections
    /// - AI-generated journey summaries
    ///
    /// Optional so existing callers continue to work while
    /// Perspectives is migrated to the shared context system.
    let personalizationContext:
        PersonalizationContext?


    enum CodingKeys:
        String,
        CodingKey {

        case passage

        case profile

        case personalizationContext =
            "personalization_context"
    }
}


// =========================================================
// MARK: - Perspectives Service
// =========================================================

final class PerspectivesService {

    // =====================================================
    // MARK: Singleton
    // =====================================================

    static let shared =
        PerspectivesService()


    // =====================================================
    // MARK: Init
    // =====================================================

    private init() {}


    // =====================================================
    // MARK: - Generate
    // =====================================================

    func generate(
        passage: String,
        profile: SpiritualProfile,
        personalizationContext:
            PersonalizationContext? = nil
    ) async throws
        -> PerspectivesResponse {

        guard
            let url =
                URL(
                    string:
                        "\(APIConfig.baseURL)/perspectives"
                )
        else {

            throw URLError(
                .badURL
            )
        }


        var request =
            URLRequest(
                url:
                    url
            )


        request.httpMethod =
            "POST"


        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )


        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Accept"
        )


        // -------------------------------------------------
        // Request Body
        // -------------------------------------------------

        let body =
            PerspectivesRequest(

                passage:
                    passage,

                profile:
                    profile,

                personalizationContext:
                    personalizationContext
            )


        let encoder =
            JSONEncoder()


        // PersonalizationContext may contain Journey dates.
        // Use the same stable date representation as AIService.
        encoder.dateEncodingStrategy =
            .iso8601


        request.httpBody =
            try encoder
                .encode(
                    body
                )


        // -------------------------------------------------
        // Network Request
        // -------------------------------------------------

        let (
            data,
            response
        ) =
            try await CompanionHTTPClient.data(
                for:
                    request
            )


        guard
            let httpResponse =
                response as?
                HTTPURLResponse
        else {

            throw URLError(
                .badServerResponse
            )
        }


        // -------------------------------------------------
        // Server Error
        // -------------------------------------------------

        guard
            200..<300
                ~= httpResponse
                    .statusCode
        else {

            let message =
                extractServerError(
                    from:
                        data
                )
                ??
                "Unknown server error"


            throw NSError(

                domain:
                    "PerspectivesService",

                code:
                    httpResponse
                        .statusCode,

                userInfo: [

                    NSLocalizedDescriptionKey:
                        message
                ]
            )
        }


        // -------------------------------------------------
        // Decode Response
        // -------------------------------------------------

        return
            try JSONDecoder()
                .decode(
                    PerspectivesResponse.self,
                    from:
                        data
                )
    }


    // =====================================================
    // MARK: - Server Error Helper
    // =====================================================

    private func extractServerError(
        from data:
            Data
    ) -> String? {

        if
            let object =
                try?
                JSONSerialization
                    .jsonObject(
                        with:
                            data
                    )
                as?
                [String: Any],

            let message =
                object["error"]
                as?
                String {

            let cleaned =
                message
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            if !cleaned.isEmpty {

                return cleaned
            }
        }


        if
            let raw =
                String(
                    data:
                        data,
                    encoding:
                        .utf8
                ) {

            let cleaned =
                raw
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )


            if !cleaned.isEmpty {

                return cleaned
            }
        }


        return nil
    }
}
