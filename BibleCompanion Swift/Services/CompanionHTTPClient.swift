import Foundation

/// A bounded, cancellable transport shared by all Companion endpoints.
/// POSTs are never retried automatically: generation may already have started.
enum CompanionHTTPClient {
  static func data(for original: URLRequest) async throws -> (Data, URLResponse) {
    #if DEBUG
    if ProcessInfo.processInfo.environment["BIBLECOMPANION_OFFLINE_PREVIEW"] == "1" {
      throw CompanionConnectionError.offline
    }
    #endif
    var request = original
    request.timeoutInterval = 90
    do {
      let result = try await URLSession.shared.data(for: request)
      guard let response = result.1 as? HTTPURLResponse else {
        throw CompanionConnectionError.invalidResponse
      }
      guard (200..<300).contains(response.statusCode) else {
        switch response.statusCode {
        case 429: throw CompanionConnectionError.busy
        case 500...599: throw CompanionConnectionError.unavailable
        default: throw CompanionConnectionError.rejected
        }
      }
      return result
    } catch let error as URLError {
      switch error.code {
      case .cancelled: throw CancellationError()
      case .notConnectedToInternet, .networkConnectionLost:
        throw CompanionConnectionError.offline
      case .timedOut: throw CompanionConnectionError.timeout
      default: throw CompanionConnectionError.unavailable
      }
    }
  }
}

enum CompanionConnectionError: LocalizedError {
  case offline, timeout, busy, unavailable, rejected, invalidResponse
  var errorDescription: String? {
    switch self {
    case .offline:
      return "You're offline. You can still read saved Scripture and reflections. Reconnect to talk with Companion."
    case .timeout:
      return "Companion took longer than expected. Please try again in a moment."
    case .busy:
      return "Companion is busy right now. Give it a moment, then try again."
    case .unavailable:
      return "Couldn't reach Companion. Please try again in a moment."
    case .rejected:
      return "Companion couldn't complete that request. Please try again."
    case .invalidResponse:
      return "Companion's reply couldn't be opened. Please try again."
    }
  }
}
