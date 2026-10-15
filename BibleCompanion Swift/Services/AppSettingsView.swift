import SwiftUI

// This release intentionally adds no account, cloud-sync, memory-management,
// or backup UI. There are no disabled placeholders for those later features.
@MainActor
struct AppSettingsView: View {
  let onReplayTutorial: () -> Void
  let showsDone: Bool
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @ObservedObject private var settings = AppSettingsStore.shared
  @State private var currentPathTitle = ""
  @State private var confirmReset = false

  init(showsDone: Bool = true, onReplayTutorial: @escaping () -> Void) {
    self.showsDone = showsDone
    self.onReplayTutorial = onReplayTutorial
  }

  var body: some View {
    Form {
      Section {
        HStack(spacing: 16) {
          CompanionAvatar(size: 64, behavior: reduceMotion ? .still : .floating)
            .accessibilityHidden(true)
          VStack(alignment: .leading, spacing: 5) {
            Text("Make this space yours").font(.headline)
            Text("Choose how you read, learn, and explore together.")
              .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
          }
        }
        .padding(.vertical, 8)
      }

      Section("Make it yours") {
        NavigationLink {
          SettingsProfileEditor()
        } label: {
          SettingsNavigationRow(
            title: "Your profile", subtitle: "Update your starting point and goals",
            icon: "person.crop.circle")
        }
        NavigationLink {
          CompanionSettingsView()
        } label: {
          SettingsNavigationRow(
            title: "Companion preferences",
            subtitle: "\(settings.replyLength.title) replies, at your pace",
            icon: "bubble.left.and.bubble.right")
        }
        NavigationLink {
          ReadingAppearanceSettingsView()
        } label: {
          SettingsNavigationRow(
            title: "Reading & appearance",
            subtitle: "Text size, spacing, typeface, and theme",
            icon: "textformat.size")
        }
      }

      Section {
        NavigationLink {
          ChangePathView(onPathChanged: refreshPath)
        } label: {
          SettingsNavigationRow(
            title: currentPathTitle.isEmpty ? "Choose a path" : "Your current path",
            subtitle: currentPathTitle.isEmpty ? "Find something to explore" : currentPathTitle,
            icon: "map")
        }
      } header: {
        Text("Your journey")
      } footer: {
        Text(
          "Editing your profile does not replace your path or reset progress. Use this option when you want to change focus."
        )
      }

      Section("Help") {
        NavigationLink {
          SettingsHelpView(onReplayTutorial: onReplayTutorial)
        } label: {
          SettingsNavigationRow(
            title: "Help & app tour", subtitle: "Find your way around or replay the tutorial",
            icon: "questionmark.circle")
        }
        NavigationLink {
          SettingsProblemReportView()
        } label: {
          SettingsNavigationRow(
            title: "Report a problem", subtitle: "Prepare a report you can review and share",
            icon: "exclamationmark.bubble")
        }
      }

      if let message = settings.storageMessage {
        Section {
          Label(message, systemImage: "exclamationmark.triangle")
            .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
        }
      }

      Section {
        Button("Reset app preferences", role: .destructive) { confirmReset = true }
      } footer: {
        Text(
          "Resets reply length, explanation depth, reading style, and theme only. Your profile, conversation approach, notes, reflections, bookmarks, chats, and journeys stay as they are."
        )
      }

      Section {
        LabeledContent("App version", value: SettingsAppInformation.version)
        Text("Preferences are saved on this device.")
          .font(.footnote).foregroundStyle(AppTheme.textSecondary)
      }
    }
    .scrollContentBackground(.hidden)
    .cloudScreen()
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        if showsDone { Button("Done") { dismiss() } }
      }
    }
    .preferredColorScheme(settings.appearance.preferredColorScheme)
    .onAppear(perform: refreshPath)
    .confirmationDialog(
      "Reset app preferences?", isPresented: $confirmReset, titleVisibility: .visible
    ) {
      Button("Reset Preferences", role: .destructive) { settings.resetPreferences() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This does not delete your saved work, change your profile, or restart onboarding.")
    }
  }

  private func refreshPath() {
    currentPathTitle = StorageService.shared.loadActivePersonalizedPath()?.title ?? ""
  }
}

@MainActor
private struct SettingsNavigationRow: View {
  let title: String
  let subtitle: String
  let icon: String
  var body: some View {
    HStack(spacing: 13) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundStyle(AppTheme.accent)
        .frame(width: 38, height: 38)
        .background(AppTheme.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 11))
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 4) {
        Text(title).foregroundStyle(AppTheme.textPrimary)
        Text(subtitle).font(.caption).foregroundStyle(AppTheme.textSecondary)
      }
      .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 5)
  }
}

// Uses the original options from OnboardingViewModel, not newly invented labels.
@MainActor
private struct SettingsProfileEditor: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var onboarding: OnboardingViewModel
  @State private var original = SettingsProfileDraft()
  @State private var draft = SettingsProfileDraft()
  @State private var didLoad = false
  @State private var confirmDiscard = false
  @State private var saveError: String?

  private var isDirty: Bool { didLoad && draft != original }

  var body: some View {
    Form {
      Section {
        Text("Where you are can change. Update these answers without starting over.")
          .foregroundStyle(AppTheme.textSecondary)
      }
      Section("What I call you") {
        TextField("Preferred name", text: $draft.name)
          .textContentType(.name)
          .textInputAutocapitalization(.words)
          .autocorrectionDisabled()

        Text("This is the name your Companion may use naturally in conversation.")
          .font(.footnote)
          .foregroundStyle(AppTheme.textSecondary)
      }
      Section("Your starting point") {
        SettingsAnswerPicker(
          title: "Spiritual starting point", value: $draft.spiritualPosition,
          options: onboarding.spiritualPositions)
        SettingsAnswerPicker(
          title: "Bible familiarity", value: $draft.bibleFamiliarity,
          options: onboarding.bibleFamiliarityOptions)
      }
      Section("What you need now") {
        SettingsAnswerPicker(
          title: "Main goal", value: $draft.primaryGoal, options: onboarding.primaryGoals)
        SettingsAnswerPicker(
          title: "Current season", value: $draft.currentSeason, options: onboarding.currentSeasons)
        SettingsAnswerPicker(
          title: "How I challenge you", value: $draft.challengePreference,
          options: onboarding.challengePreferences)
      }
      Section {
        Text(
          "Your current path and its saved focus are unchanged by this form. To update what you are working through, use Your current path on the Settings screen."
        )
        .font(.footnote).foregroundStyle(AppTheme.textSecondary)
      }
      if let saveError {
        Section { Text(saveError).font(.subheadline).foregroundStyle(.red) }
      }
    }
    .navigationTitle("Your Profile")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .interactiveDismissDisabled(isDirty)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          if isDirty { confirmDiscard = true } else { dismiss() }
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save", action: save).fontWeight(.semibold).disabled(!isDirty)
      }
    }
    .onAppear {
      guard !didLoad else { return }
      original = SettingsProfileDraft(profile: onboarding.profile)
      draft = original
      didLoad = true
    }
    .confirmationDialog(
      "Discard profile changes?", isPresented: $confirmDiscard, titleVisibility: .visible
    ) {
      Button("Discard Changes", role: .destructive) { dismiss() }
      Button("Keep Editing", role: .cancel) {}
    } message: {
      Text("Your saved profile will stay unchanged.")
    }
  }

  private func save() {
    let updated = draft.applyingChanges(since: original, to: onboarding.profile)
    if SettingsProfilePersistence.save(updated, to: onboarding) {
      original = draft
      dismiss()
    } else {
      saveError = "Your profile could not be saved. Your edits are still here; please try again."
    }
  }
}

@MainActor
private struct SettingsAnswerPicker: View {
  let title: String
  @Binding var value: String
  let options: [String]
  var body: some View {
    Picker(title, selection: $value) {
      Text("Not specified").tag("")
      ForEach(SettingsProfileDraft.options(options, including: value), id: \.self) { option in
        Text(option).tag(option)
      }
    }
    .pickerStyle(.navigationLink)
  }
}

@MainActor
private enum SettingsProfilePersistence {
  static func save(_ profile: SpiritualProfile, to onboarding: OnboardingViewModel) -> Bool {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = .sortedKeys
      let expected = try encoder.encode(profile)
      // Do not call resetProfile() or saveProfile(): the latter also clears
      // a legacy recommendation. Settings should only save the profile.
      StorageService.shared.saveSpiritualProfile(profile)
      guard let restored = StorageService.shared.loadSpiritualProfile(),
        try encoder.encode(restored) == expected
      else { return false }
      onboarding.profile = profile
      return true
    } catch {
      return false
    }
  }
}

@MainActor
private struct CompanionSettingsView: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @EnvironmentObject private var onboarding: OnboardingViewModel
  @ObservedObject private var settings = AppSettingsStore.shared
  @ObservedObject private var existingPreferences = CompanionPreferencesStore.shared
  @State private var profileSaveError: String?

  var body: some View {
    Form {
      Section {
        if dynamicTypeSize.isAccessibilitySize {
          Picker("Reply length", selection: $settings.replyLength) {
            ForEach(CompanionReplyLength.allCases) { length in Text(length.title).tag(length) }
          }
          .pickerStyle(.navigationLink)
        } else {
          Picker("Reply length", selection: $settings.replyLength) {
            ForEach(CompanionReplyLength.allCases) { length in Text(length.title).tag(length) }
          }
          .pickerStyle(.segmented)
        }
        Text(settings.replyLength.explanation).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
      } header: {
        Text("How much to say")
      } footer: {
        Text(
          "Applies to new Companion replies. Asking for something shorter or deeper still overrides your default. Existing replies and structured Study Mode guides are not rewritten."
        )
      }

      Section {
        Picker("Explanation depth", selection: $settings.explanationDepth) {
          ForEach(CompanionExplanationDepth.allCases) { depth in
            Text(depth.title).tag(depth)
          }
        }
        .pickerStyle(.navigationLink)
        Text(settings.explanationDepth.explanation).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
      } header: {
        Text("How to explain")
      } footer: {
        Text(
          "Depth changes the kind of explanation, not the meaning of Scripture or your theological position."
        )
      }

      Section {
        Menu {
          ForEach(CompanionLens.allCases) { lens in
            Button {
              existingPreferences.selectedLens = lens
            } label: {
              if existingPreferences.selectedLens.id == lens.id {
                Label(lens.title, systemImage: "checkmark")
              } else {
                Label(lens.title, systemImage: lens.icon)
              }
            }
          }
        } label: {
          LabeledContent("Conversation approach") {
            Text(existingPreferences.selectedLens.title).foregroundStyle(AppTheme.textSecondary)
          }
          .foregroundStyle(AppTheme.textPrimary)
        }
        SettingsAnswerPicker(
          title: "How I challenge you",
          value: Binding(
            get: { onboarding.profile.challengePreference },
            set: saveChallengePreference),
          options: onboarding.challengePreferences)
      } header: {
        Text("How we talk")
      } footer: {
        Text(
          "Conversation approach is the same control already available in chat. Your challenge preference is shared with your profile. Challenge means examining an idea, not criticizing you."
        )
      }

      if let profileSaveError {
        Section { Text(profileSaveError).foregroundStyle(.red).font(.subheadline) }
      }
      if let message = settings.storageMessage {
        Section { Text(message).foregroundStyle(AppTheme.textSecondary).font(.subheadline) }
      }
    }
    .navigationTitle("Companion Preferences")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func saveChallengePreference(_ value: String) {
    var updated = onboarding.profile
    updated.challengePreference = value
    if SettingsProfilePersistence.save(updated, to: onboarding) {
      profileSaveError = nil
    } else {
      profileSaveError = "That preference could not be saved. Please try again."
    }
  }
}

// Also opened by the Aa control in BibleReaderView.
@MainActor
struct ReadingAppearanceSettingsView: View {
  @ObservedObject private var settings = AppSettingsStore.shared
  @State private var previewReference: String?
  @State private var previewText =
    "Choose a comfortable text size and give each line room to breathe. Your reading preferences will be used in the Bible reader and Scripture previews."
  @State private var didLoadPreview = false
  @State private var confirmReset = false

  var body: some View {
    Form {
      Section {
        VStack(alignment: .leading, spacing: 12) {
          Text(previewReference ?? "Reading preview").font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
          Text(verbatim: previewText)
            .bibleReadingStyle()
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
      } header: {
        Text("Live preview")
      }
      Section("Reading") {
        VStack(alignment: .leading, spacing: 8) {
          LabeledContent("Text size", value: "\(Int(settings.readingTextSize)) pt")
          Slider(value: $settings.readingTextSize, in: AppSettingsValues.textSizeRange, step: 1)
            .accessibilityLabel("Bible text size")
            .accessibilityValue("\(Int(settings.readingTextSize)) points")
        }.padding(.vertical, 5)
        VStack(alignment: .leading, spacing: 8) {
          LabeledContent("Line spacing", value: "\(Int(settings.readingLineSpacing)) pt")
          Slider(
            value: $settings.readingLineSpacing, in: AppSettingsValues.lineSpacingRange, step: 1
          )
          .accessibilityLabel("Bible line spacing")
          .accessibilityValue("\(Int(settings.readingLineSpacing)) points")
        }.padding(.vertical, 5)
        Picker("Typeface", selection: $settings.readingFont) {
          ForEach(BibleReadingFont.allCases) { font in Text(font.title).tag(font) }
        }
      }
      Section("Your atmosphere") {
        Picker("Color palette", selection: $settings.visualTheme) {
          ForEach(VisualTheme.allCases) { theme in Text(theme.title).tag(theme) }
        }
        Toggle("Animate Companion", isOn: $settings.animateCompanion)
        Text("Reduced Motion on your device always takes priority.")
          .font(.footnote).foregroundStyle(AppTheme.textSecondary)
      }
      Section("Your Today screen") {
        Toggle("Companion growth", isOn: $settings.showGrowthOnHome)
        Toggle("Saved Scripture & suggestions", isOn: $settings.showLibraryOnHome)
      }
      Section {
        Picker("Appearance", selection: $settings.appearance) {
          ForEach(AppAppearance.allCases) { appearance in Text(appearance.title).tag(appearance) }
        }
      } header: {
        Text("App theme")
      } footer: {
        Text(
          "Appearance applies across the app. Reading size and spacing apply to Scripture text, with your device's accessibility text sizing added on top."
        )
      }
      Section {
        Button("Restore reading defaults") { confirmReset = true }
      } footer: {
        Text(
          "Restores typeface, text size, and line spacing. Your theme and saved Bible markings are not changed."
        )
      }
      if let message = settings.storageMessage {
        Section { Text(message).font(.footnote).foregroundStyle(AppTheme.textSecondary) }
      }
    }
    .navigationTitle("Reading & Appearance")
    .navigationBarTitleDisplayMode(.inline)
    .preferredColorScheme(settings.appearance.preferredColorScheme)
    .task { await loadPreview() }
    .confirmationDialog(
      "Restore reading defaults?", isPresented: $confirmReset, titleVisibility: .visible
    ) {
      Button("Restore Defaults") { settings.resetReadingPreferences() }
      Button("Cancel", role: .cancel) {}
    }
  }

  private func loadPreview() async {
    guard !didLoadPreview else { return }
    didLoadPreview = true
    // Uses the app's bundled text, not an invented translation or an AI quote.
    guard let verses = try? await BibleService.shared.preload(),
      let verse = verses.first(where: { $0.book == "John" && $0.chapter == 15 && $0.verse == 5 })
        ?? verses.first
    else { return }
    previewReference = "\(verse.book) \(verse.chapter):\(verse.verse)"
    previewText = verse.text
  }
}

@MainActor
private struct SettingsHelpView: View {
  let onReplayTutorial: () -> Void
  @State private var confirmReplay = false

  var body: some View {
    Form {
      Section {
        Button {
          confirmReplay = true
        } label: {
          Label("Replay the app tour", systemImage: "play.circle")
        }
      } footer: {
        Text(
          "Returns you to Home and replays the guided tour. It does not repeat the questionnaire or erase progress."
        )
      }
      Section("A quick guide") {
        DisclosureGroup("Read and save Scripture") {
          Text(
            "Open Read Scripture from Home. Tap verses to select them, then choose Highlight, Note, Bookmark, or Study with Companion. The reader's top-right menu also has chapter options."
          )
        }
        DisclosureGroup("Find saved notes and reflections") {
          Text(
            "Open Your Bible on Home. Notes contains passage notes; Reflections contains your Study Mode reflections. Search by reference or words you remember."
          )
        }
        DisclosureGroup("Continue where you left off") {
          Text(
            "Home's Continue card returns you to your recent passage, study, conversation, or checkpoint. Opening a passage does not complete a checkpoint for you."
          )
        }
        DisclosureGroup("Shorter or deeper answers") {
          Text(
            "Choose a default in Companion Preferences, or use the follow-up buttons below a reply. Those buttons continue the same conversation. Changing your default only affects future replies."
          )
        }
        DisclosureGroup("When AI content cannot load") {
          Text(
            "Try the request again after checking your connection. Bundled Scripture and saved Library items are separate from the AI service. In the current development setup, the backend must also be running. Do not delete the app to troubleshoot: that can remove local saved work."
          )
        }
      }
      Section {
        Text(
          "The Companion's explanations are AI-generated study aids. Read the biblical text in context, examine supporting passages, and distinguish interpretation from what the passage explicitly says."
        )
        .font(.footnote).foregroundStyle(AppTheme.textSecondary)
      }
    }
    .navigationTitle("Help & App Tour")
    .navigationBarTitleDisplayMode(.inline)
    .confirmationDialog(
      "Replay the guided tour?", isPresented: $confirmReplay, titleVisibility: .visible
    ) {
      Button("Replay Tour") { onReplayTutorial() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Settings will close first. Your saved work stays intact.")
    }
  }
}

@MainActor
private struct SettingsProblemReportView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var summary = ""
  @State private var details = ""
  @State private var includeAppDetails = true
  @State private var confirmDiscard = false
  private var isDirty: Bool { !summary.isEmpty || !details.isEmpty }
  private var canShare: Bool {
    !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  private var report: String {
    var text =
      "BIBLE COMPANION - PROBLEM REPORT\n\nSummary:\n\(summary)\n\nWhat happened / steps to reproduce:\n\(details)"
    if includeAppDetails {
      text +=
        "\n\nApp: \(SettingsAppInformation.version)\nSystem: \(ProcessInfo.processInfo.operatingSystemVersionString)"
    }
    return text
  }

  var body: some View {
    Form {
      Section {
        Text(
          "Describe the issue, review the report, then choose where to share it. Nothing is sent automatically, and your notes, profile, and chats are not attached."
        )
        .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
      }
      Section("What went wrong?") {
        TextField("A short summary", text: $summary)
        TextEditor(text: $details)
          .frame(minHeight: 150)
          .accessibilityLabel("Steps to reproduce and what you expected to happen")
      }
      Section {
        Toggle("Include app and OS versions", isOn: $includeAppDetails)
      } footer: {
        Text(
          "Avoid personal information in your description. You can add a screenshot yourself when sharing."
        )
      }
      Section {
        DisclosureGroup("Review report") {
          Text(verbatim: report).font(.subheadline).textSelection(.enabled)
        }
        ShareLink(item: report, subject: Text("Bible Companion problem report")) {
          Label("Share report", systemImage: "square.and.arrow.up")
        }
        .disabled(!canShare)
      } footer: {
        Text(
          "This opens the system share sheet; it is not an automatic support-ticket submission. Your draft stays here until you leave this screen."
        )
      }
    }
    .navigationTitle("Report a Problem")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .interactiveDismissDisabled(isDirty)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Back") {
          if isDirty { confirmDiscard = true } else { dismiss() }
        }
      }
    }
    .confirmationDialog(
      "Leave this report?", isPresented: $confirmDiscard, titleVisibility: .visible
    ) {
      Button("Leave Report", role: .destructive) { dismiss() }
      Button("Keep Editing", role: .cancel) {}
    } message: {
      Text("The draft is not saved in the app. A copy you already shared will not be affected.")
    }
  }
}

private enum SettingsAppInformation {
  static var version: String {
    let version =
      Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
      ?? "Development"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    return build.isEmpty ? version : "\(version) (\(build))"
  }
}
