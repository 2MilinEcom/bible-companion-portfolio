import SwiftUI

struct WelcomeView: View {
  @EnvironmentObject private var onboarding: OnboardingViewModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var nameDraft = ""
  @State private var askingName = false
  @State private var continuing = false
  @FocusState private var nameFocused: Bool

  private var name: String { nameDraft.trimmingCharacters(in: .whitespacesAndNewlines) }

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 24) {
          ZStack {
            Circle().fill(
              RadialGradient(colors: [AppTheme.goldSoft, .clear], center: .center,
                             startRadius: 10, endRadius: 110))
              .frame(width: 220, height: 220)
            CompanionAvatar(size: askingName ? 140 : 190, behavior: .floating)
              .accessibilityHidden(true)
          }
          VStack(spacing: 14) {
            Text(askingName ? "What should I call you?" : "Meet Your\nBible Companion")
              .font(.largeTitle.bold())
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
            Text(askingName
              ? "Choose the name you feel at home with. You can change it anytime."
              : "Read Scripture. Understand it. Bring it into your everyday life.")
              .font(.title3)
              .foregroundStyle(AppTheme.textSecondary)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
            if askingName {
              TextField("Your name", text: $nameDraft)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .focused($nameFocused)
                .padding(16)
                .background(AppTheme.surfaceStrong, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.divider))
                .accessibilityLabel("Your preferred name")
                .onSubmit(continueWithName)
                .task { nameFocused = true }
            } else {
              Text("Start with a short daily study, explore at your own pace, and talk things through with your Companion.")
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - 110))
      }
      .scrollDismissesKeyboard(.interactively)
      .safeAreaInset(edge: .bottom) {
        Button(askingName ? "Continue" : "Get Started") {
          if askingName { continueWithName() }
          else { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { askingName = true } }
        }
        .buttonStyle(CloudPrimaryButtonStyle())
        .disabled(askingName && name.isEmpty)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
      }
    }
    .cloudScreen()
    .onAppear { nameDraft = onboarding.profile.name }
    .navigationDestination(isPresented: $continuing) { QuickStartView() }
  }

  private func continueWithName() {
    guard !name.isEmpty else { return }
    onboarding.profile.name = name
    StorageService.shared.saveSpiritualProfile(onboarding.profile)
    nameFocused = false
    continuing = true
  }
}
