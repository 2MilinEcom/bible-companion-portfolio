//

//  PathConversationService.swift

//  BibleCompanion Swift

//

//  Created by Shopify on 10/2/26.

//



import Foundation





// =========================================================

// MARK: - Path Conversation Request

// =========================================================



struct PathConversationRequest: Codable {



    let message:

        String



    let previousResponseID:

        String?



    let profile:

        SpiritualProfile



    /// Shared structured personalization context.
    ///
    /// This remains separate from the user's current message so
    /// the backend can distinguish current intent from stored
    /// profile/history/reflection information.
    let personalizationContext:

        PersonalizationContext?





    enum CodingKeys:

        String,

        CodingKey {



        case message



        case previousResponseID =

            "previous_response_id"



        case profile



        case personalizationContext =

            "personalization_context"

    }

}





// =========================================================

// MARK: - Path Conversation Focus Payload

// =========================================================



struct PathConversationFocusPayload:

    Codable,

    Hashable {



    let category:

        String



    let label:

        String



    let originalText:

        String



    let trigger:

        String



    let goal:

        String





    // =====================================================

    // MARK: - Cleaned Values

    // =====================================================



    private var cleanedCategory:

        String {



        category

            .trimmingCharacters(

                in:

                    .whitespacesAndNewlines

            )

    }





    private var cleanedLabel:

        String {



        label

            .trimmingCharacters(

                in:

                    .whitespacesAndNewlines

            )

    }





    private var cleanedOriginalText:

        String {



        originalText

            .trimmingCharacters(

                in:

                    .whitespacesAndNewlines

            )

    }





    private var cleanedTrigger:

        String {



        trigger

            .trimmingCharacters(

                in:

                    .whitespacesAndNewlines

            )

    }





    private var cleanedGoal:

        String {



        goal

            .trimmingCharacters(

                in:

                    .whitespacesAndNewlines

            )

    }





    // =====================================================

    // MARK: - Convert to JourneyFocus

    // =====================================================



    var journeyFocus:

        JourneyFocus? {



        guard

            !cleanedCategory.isEmpty,

            !cleanedLabel.isEmpty

        else {



            return nil

        }





        return JourneyFocus(



            category:

                cleanedCategory,



            label:

                cleanedLabel,



            originalText:

                cleanedOriginalText

                    .isEmpty

                ? nil

                : cleanedOriginalText,



            trigger:

                cleanedTrigger

                    .isEmpty

                ? nil

                : cleanedTrigger,



            goal:

                cleanedGoal

                    .isEmpty

                ? nil

                : cleanedGoal

        )

    }





    // =====================================================

    // MARK: - Proposal Validation

    // =====================================================



    var hasUsableProposal:

        Bool {



        journeyFocus

        !=

        nil

    }

}





// =========================================================

// MARK: - Path Conversation Response

// =========================================================



struct PathConversationResponse:

    Codable,

    Hashable {



    let reply:

        String



    let readyToPropose:

        Bool



    let focus:

        PathConversationFocusPayload



    let responseID:

        String





    enum CodingKeys:

        String,

        CodingKey {



        case reply



        case readyToPropose



        case focus



        case responseID =

            "response_id"

    }





    // =====================================================

    // MARK: - Helpers

    // =====================================================



    var cleanedReply:

        String {



        reply

            .trimmingCharacters(

                in:

                    .whitespacesAndNewlines

            )

    }





    var proposedFocus:

        JourneyFocus? {



        guard

            readyToPropose

        else {



            return nil

        }





        return focus

            .journeyFocus

    }





    var hasValidProposal:

        Bool {



        readyToPropose

        &&

        proposedFocus

        !=

        nil

    }

}





// =========================================================

// MARK: - Path Conversation Service Error

// =========================================================



enum PathConversationServiceError:

    LocalizedError {



    case invalidURL



    case emptyMessage



    case invalidResponse



    case emptyReply



    case malformedProposal



    case serverError(

        statusCode:

            Int,

        message:

            String

    )





    var errorDescription:

        String? {



        switch self {



        case .invalidURL:



            return

                "The Talk It Through service URL is invalid."





        case .emptyMessage:



            return

                "Type something before sending your message."





        case .invalidResponse:



            return

                "Talk It Through returned an invalid response."





        case .emptyReply:



            return

                "Companion returned an empty response."





        case .malformedProposal:



            return

                "Companion proposed a path, but the focus information was incomplete."





        case let .serverError(

            _,

            message

        ):



            return

                message

        }

    }

}





// =========================================================

// MARK: - Path Conversation Service

// =========================================================



final class PathConversationService {



    static let shared =

        PathConversationService()





    private init() {}





    // =====================================================

    // MARK: - Send Message

    // =====================================================



    func send(

        message: String,

        profile: SpiritualProfile,

        previousResponseID: String? = nil,

        personalizationContext:

            PersonalizationContext? = nil

    ) async throws

        -> PathConversationResponse {



        let cleanedMessage =

            message

                .trimmingCharacters(

                    in:

                        .whitespacesAndNewlines

                )





        guard

            !cleanedMessage.isEmpty

        else {



            throw PathConversationServiceError

                .emptyMessage

        }





        guard

            let url =

                URL(

                    string:

                        "\(APIConfig.baseURL)/path-conversation"

                )

        else {



            throw PathConversationServiceError

                .invalidURL

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





        let cleanedPreviousID:

            String? = {



            guard

                let previousResponseID

            else {



                return nil

            }





            let cleaned =

                previousResponseID

                    .trimmingCharacters(

                        in:

                            .whitespacesAndNewlines

                    )





            return cleaned.isEmpty

            ? nil

            : cleaned

        }()





        let body =

            PathConversationRequest(



                message:

                    cleanedMessage,



                previousResponseID:

                    cleanedPreviousID,



                profile:

                    profile,



                personalizationContext:

                    personalizationContext

            )





        let encoder =

            JSONEncoder()





        encoder.dateEncodingStrategy =

            .iso8601





        request.httpBody =

            try encoder

                .encode(

                    body

                )





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

                response

                as?

                HTTPURLResponse

        else {



            throw PathConversationServiceError

                .invalidResponse

        }





        guard

            (200...299)

                .contains(

                    httpResponse

                        .statusCode

                )

        else {



            let message =

                extractServerError(

                    from:

                        data

                )





            throw PathConversationServiceError

                .serverError(



                    statusCode:

                        httpResponse

                            .statusCode,



                    message:

                        message

                )

        }





        let decoded:

            PathConversationResponse





        do {



            decoded =

                try JSONDecoder()

                    .decode(

                        PathConversationResponse.self,

                        from:

                            data

                    )



        } catch {



            throw PathConversationServiceError

                .invalidResponse

        }





        guard

            !decoded

                .cleanedReply

                .isEmpty

        else {



            throw PathConversationServiceError

                .emptyReply

        }





        // -------------------------------------------------

        // If the backend says it is ready to propose,

        // make sure the structured focus is actually usable.

        // -------------------------------------------------



        if

            decoded

                .readyToPropose,

            decoded

                .proposedFocus

            ==

            nil {



            throw PathConversationServiceError

                .malformedProposal

        }





        return decoded

    }





    // =====================================================

    // MARK: - Start Conversation

    // =====================================================



    /// Convenience method for the first user message.

    ///

    /// Using this makes it obvious that the first turn

    /// should not carry an old response ID.

    func start(

        message: String,

        profile: SpiritualProfile,

        personalizationContext:

            PersonalizationContext? = nil

    ) async throws

        -> PathConversationResponse {



        try await send(



            message:

                message,



            profile:

                profile,



            previousResponseID:

                nil,



            personalizationContext:

                personalizationContext

        )

    }





    // =====================================================

    // MARK: - Continue Conversation

    // =====================================================



    /// Convenience method for all later turns.

    func continueConversation(

        message: String,

        profile: SpiritualProfile,

        previousResponseID: String,

        personalizationContext:

            PersonalizationContext? = nil

    ) async throws

        -> PathConversationResponse {



        try await send(



            message:

                message,



            profile:

                profile,



            previousResponseID:

                previousResponseID,



            personalizationContext:

                personalizationContext

        )

    }





    // =====================================================

    // MARK: - Server Error Parsing

    // =====================================================



    private func extractServerError(

        from data: Data

    ) -> String {



        // -------------------------------------------------

        // Prefer:

        //

        // {

        //     "error": "..."

        // }

        // -------------------------------------------------



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

                object[

                    "error"

                ]

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





        // -------------------------------------------------

        // Fall back to raw server text.

        // -------------------------------------------------



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





        return

            "Talk It Through returned an unknown server error."

    }

}
