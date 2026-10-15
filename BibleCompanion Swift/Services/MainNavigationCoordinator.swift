import Combine

@MainActor
final class MainNavigationCoordinator: ObservableObject {
  static let shared = MainNavigationCoordinator()
  @Published var dailyStudyRequested = false
  private init() {}
}
