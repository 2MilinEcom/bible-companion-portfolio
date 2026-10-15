import SwiftUI

@MainActor
struct ContentView: View {

  @ObservedObject
  private var appSettings = AppSettingsStore.shared

  @AppStorage("onboardingComplete")
  private var onboardingComplete = false

  @StateObject
  private var onboardingViewModel =
    OnboardingViewModel()

  @StateObject
  private var appTutorial =
    AppTutorialCoordinator()

  @StateObject
  private var companionGrowth =
    CompanionGrowthStore.shared

  var body: some View {

    ZStack {

      CloudScreenBackground()
        .ignoresSafeArea()

      if onboardingComplete {

        MainTabView()
        .transition(
          .opacity
        )

      } else {

        NavigationStack {
          WelcomeView()
        }
        .transition(
          .opacity
        )
      }
    }
    .animation(
      .easeInOut(
        duration: 0.55
      ),
      value:
        onboardingComplete
    )
    .foregroundStyle(AppTheme.textPrimary)
    .tint(AppTheme.accent)
    .environmentObject(
      onboardingViewModel
    )
    .environmentObject(
      appTutorial
    )
    .overlay {

      if onboardingComplete,
        !appTutorial.isActive,
        let stage =
          companionGrowth
          .pendingStageReveal
      {

        CompanionGrowthRevealView(
          stage:
            stage,
          onContinue: {

            companionGrowth
              .acknowledgePendingStageReveal()
          }
        )
        .transition(
          .opacity
        )
        .zIndex(1000)
      }
    }
    .animation(
      .easeInOut(
        duration: 0.30
      ),
      value:
        companionGrowth
        .pendingStageReveal
    )
    .preferredColorScheme(appSettings.appearance.preferredColorScheme)
    .task {
      _ = try? await BibleService.shared.preload()
    }
    .onAppear {

      companionGrowth
        .refresh()
    }
  }
}

#Preview {
  ContentView()
}
