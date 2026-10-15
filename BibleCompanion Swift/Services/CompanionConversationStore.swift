import Foundation

struct StoredCompanionMessage: Codable {

    let text: String
    let isUser: Bool
}


struct StoredCompanionConversation: Codable {

    var messages: [StoredCompanionMessage]

    var previousResponseID: String?

    var updatedAt: Date
}


struct StoredCompanionConversationSnapshot {

    let key: String
    let messages: [StoredCompanionMessage]
    let updatedAt: Date
}


final class CompanionConversationStore {

    static let shared =
        CompanionConversationStore()


    private let storageKey =
        "bibleCompanionConversations"


    private var conversations:
        [String: StoredCompanionConversation] = [:]


    private init() {

        load()
    }


    // MARK: - Conversation

    func conversation(
        for key: String
    ) -> StoredCompanionConversation? {

        conversations[key]
    }


    // MARK: - Recent Conversations

    /// Returns the most recently updated saved conversations.
    ///
    /// The active conversation can be excluded so the personalization
    /// context does not duplicate the thread already being continued by
    /// `previousResponseID`.
    func recentConversations(
        limit: Int,
        excludingKey: String? = nil
    ) -> [StoredCompanionConversationSnapshot] {

        guard limit > 0 else {
            return []
        }

        return conversations
            .compactMap { key, conversation in

                if let excludingKey,
                   key == excludingKey {

                    return nil
                }

                guard !conversation.messages.isEmpty else {
                    return nil
                }

                return StoredCompanionConversationSnapshot(
                    key: key,
                    messages: conversation.messages,
                    updatedAt: conversation.updatedAt
                )
            }
            .sorted {
                $0.updatedAt > $1.updatedAt
            }
            .prefix(limit)
            .map { $0 }
    }


    // MARK: - Save

    func saveConversation(
        messages: [Message],
        previousResponseID: String?,
        for key: String
    ) {

        let storedMessages =
            messages.map {

                StoredCompanionMessage(
                    text:
                        $0.text,
                    isUser:
                        $0.isUser
                )
            }


        conversations[key] =
            StoredCompanionConversation(
                messages:
                    storedMessages,
                previousResponseID:
                    previousResponseID,
                updatedAt:
                    Date()
            )


        save()
    }


    // MARK: - Delete

    func deleteConversation(
        for key: String
    ) {

        conversations.removeValue(
            forKey: key
        )

        save()
    }


    // MARK: - Storage

    private func save() {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        conversations
                    )


            UserDefaults.standard.set(
                data,
                forKey:
                    storageKey
            )

        } catch {

            print(
                "Conversation save error:",
                error
            )
        }
    }


    private func load() {

        guard let data =
                UserDefaults.standard.data(
                    forKey:
                        storageKey
                )
        else {
            return
        }


        do {

            conversations =
                try JSONDecoder()
                    .decode(
                        [String: StoredCompanionConversation].self,
                        from:
                            data
                    )

        } catch {

            print(
                "Conversation load error:",
                error
            )
        }
    }
}
