import SwiftUI

struct QuickStartView: View {
  @ObservedObject private var settings = AppSettingsStore.shared
  @EnvironmentObject private var onboarding: OnboardingViewModel
  @EnvironmentObject private var tutorial: AppTutorialCoordinator
  @AppStorage("onboardingComplete") private var complete = false
  @State private var familiarity = ""
  @State private var goal = ""
  @State private var approach = ""
  @State private var showingPreview = false
  @State private var showingMoreSetup = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        Text(showingPreview ? "A little space for you" : "Start where you are")
          .font(.largeTitle.bold())
        Text(showingPreview
          ? "Your daily study is ready to begin. You can change these choices whenever you like."
          : "A few optional choices help Companion meet you where you are. You can add more later.")
          .foregroundStyle(AppTheme.textSecondary)
        if showingPreview {
          Label("A short study for today", systemImage: "sun.max")
          Label("Scripture you can read offline", systemImage: "book")
          Label("A place to ask honest questions", systemImage: "bubble.left.and.bubble.right")
          if !goal.isEmpty { Text("Your focus: \(goal)").font(.headline) }
          Button("Begin my first day") {
            saveChoices()
            tutorial.finish()
            complete = true
          }.buttonStyle(CloudPrimaryButtonStyle())
        } else {
          VStack(alignment: .leading, spacing: 8) {
            Text("Make it feel like you").font(.headline)
            Picker("Your colors", selection: $settings.visualTheme) {
              ForEach(VisualTheme.allCases) { theme in
                Text(theme.title).tag(theme)
              }
            }.pickerStyle(.menu)
            Text("Choose Baby Pink for a soft pastel space, or keep the calm blue sky.")
              .font(.footnote).foregroundStyle(AppTheme.textSecondary)
          }.padding(20).cloudCard()
          VStack(spacing: 18) {
            choice("Bible familiarity", selection: $familiarity, options: onboarding.bibleFamiliarityOptions)
            choice("What brings you here?", selection: $goal, options: onboarding.primaryGoals)
            choice("How should Companion respond?", selection: $approach, options: onboarding.challengePreferences)
          }.padding(20).cloudCard()
          Text("Your profile is stored on this device. When you request AI content, your profile and eligible personalization context are sent to the Companion service.")
            .font(.footnote).foregroundStyle(AppTheme.textSecondary)
          Button("Make my space") { showingPreview = true }
            .buttonStyle(CloudPrimaryButtonStyle())
          Button("I'd like to personalize more first") {
            saveChoices()
            showingMoreSetup = true
          }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
        }
      }.padding(24)
    }
    .cloudScreen()
    .navigationTitle("Your starting point")
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(isPresented: $showingMoreSetup) { SpiritualCheckInView() }
    .onAppear {
      familiarity = onboarding.profile.bibleFamiliarity
      goal = onboarding.profile.primaryGoal
      approach = onboarding.profile.challengePreference
    }
  }

  private func choice(_ title: String, selection: Binding<String>, options: [String]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.headline)
      Picker(title, selection: selection) {
        Text("Choose later").tag("")
        ForEach(options, id: \.self) { Text($0).tag($0) }
      }.pickerStyle(.menu).labelsHidden()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func saveChoices() {
    onboarding.profile.bibleFamiliarity = familiarity
    onboarding.profile.primaryGoal = goal
    onboarding.profile.challengePreference = approach
    onboarding.saveProfile()
  }
}
