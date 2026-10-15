//
//  StruggleAnalysisService.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/2/26.
//

import Foundation

struct StruggleAnalysisRequest: Codable {
    let text: String
}

struct StruggleAnalysisResponse: Codable {
    let category: String
    let label: String
    let summary: String
}

final class StruggleAnalysisService {

    static let shared = StruggleAnalysisService()

    private init() {}


    func analyze(
        text: String
    ) async throws -> StruggleAnalysisResponse {

        guard let url = URL(
            string: "\(APIConfig.baseURL)/analyze-struggle"
        ) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = try JSONEncoder().encode(
            StruggleAnalysisRequest(
                text: text
            )
        )

        let (data, response) = try await CompanionHTTPClient.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {

            let message = String(
                data: data,
                encoding: .utf8
            ) ?? "Unknown server error"

            throw NSError(
                domain: "StruggleAnalysisService",
                code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey: message
                ]
            )
        }

        return try JSONDecoder().decode(
            StruggleAnalysisResponse.self,
            from: data
        )
    }
}
