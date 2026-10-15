import SwiftUI

struct CompanionView: View {
  @State private var draftIsEmpty = true
  @ObservedObject private var settings = AppSettingsStore.shared

  let passage: String

  let mode: StudyMode

  let initialPrompt: String?

  let autoStartPrompt: String?

  let conversationKey: String?

  // MARK: - Conversation Persistence

  /// Normal Companion chats use one stable conversation key so

  /// leaving the screen and reopening it restores the same thread.

  ///

  /// Journey/checkpoint conversations can still provide their own

  /// unique key and remain completely separate.

  private var resolvedConversationKey:

    String?
  {

    if let conversationKey {

      return conversationKey

    }

    // Guided sessions should normally provide their own explicit

    // Journey/checkpoint key. If one is missing, keep that session

    // temporary instead of mixing it into the main Companion chat.

    if autoStartPrompt != nil {

      return nil

    }

    return "general-companion"

  }

  @EnvironmentObject

  private var onboardingViewModel:

    OnboardingViewModel

  @StateObject

  private var viewModel =

    CompanionViewModel()

  @ObservedObject

  private var preferences =

    CompanionPreferencesStore.shared

  // MARK: - Init

  init(

    passage: String = "",

    mode: StudyMode = .explain,

    initialPrompt: String? = nil,

    autoStartPrompt: String? = nil,

    conversationKey: String? = nil

  ) {

    self.passage =

      passage

    self.mode =

      mode

    self.initialPrompt =

      initialPrompt

    self.autoStartPrompt =

      autoStartPrompt

    self.conversationKey =

      conversationKey

  }

  // MARK: - Body

  var body: some View {

    VStack(

      spacing: 0

    ) {

      companionHeader

      Divider()

      conversation

      Divider()

      if let error = viewModel.errorMessage {
        VStack(alignment: .leading, spacing: 8) {
          Text(error).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
          Button("Try again") {
            Task {
              await viewModel.retryMessage(
                passage: passage, mode: mode, lens: preferences.selectedLens,
                profile: onboardingViewModel.profile)
            }
          }.disabled(viewModel.isLoading)
        }.frame(maxWidth: .infinity, alignment: .leading).padding()
      }
      inputArea

    }
    .cloudScreen(showsSparkles: false)

    .navigationTitle(

      "Companion"

    )

    .navigationBarTitleDisplayMode(

      .inline

    )

    .toolbar {

      ToolbarItem(

        placement:

          .topBarTrailing

      ) {

        lensMenu

      }

    }

    .onAppear {

      if let resolvedConversationKey {

        ResumeActivityStore.shared
          .recordCompanion(
            conversationKey:
              resolvedConversationKey,
            passage:
              passage
          )
      }

      handleInitialStartup()

    }

  }

  // MARK: - Companion Identity

  private var companionHeader:

    some View
  {

    HStack(

      spacing: 12

    ) {

      CompanionAvatar(
        size: 52
      )

      VStack(

        alignment: .leading,

        spacing: 2

      ) {

        Text(

          "Companion"

        )

        .font(.headline)

        HStack(

          spacing: 5

        ) {

          Image(

            systemName:

              preferences

              .selectedLens

              .icon

          )

          Text(

            preferences

              .selectedLens

              .title

          )

        }

        .font(.caption)

        .foregroundStyle(AppTheme.textSecondary)

      }

      Spacer()

      Text(

        preferences

          .selectedLens

          .title

      )

      .font(.caption)

      .fontWeight(

        .semibold

      )

      .padding(

        .horizontal,

        10

      )

      .padding(

        .vertical,

        6

      )

      .background(

        Capsule()

          .fill(

            AppTheme.accent

              .opacity(0.10)

          )

      )

      .foregroundStyle(

        AppTheme.accent

      )

    }

    .padding(

      .horizontal

    )

    .padding(

      .vertical,

      10

    )
    .background(AppTheme.surface.opacity(0.76))

  }

  // MARK: - Lens Menu

  private var lensMenu:

    some View
  {

    Menu {

      ForEach(

        CompanionLens.allCases

      ) { lens in

        Button {

          preferences

            .selectedLens =

            lens

        } label: {

          Label(

            lens.title,

            systemImage:

              lens.icon

          )

        }

      }

    } label: {

      Image(

        systemName:

          "slider.horizontal.3"

      )

    }

  }

  // MARK: - Conversation

  private var conversation:

    some View
  {

    ScrollViewReader { proxy in

      ScrollView {

        LazyVStack(

          alignment: .leading,

          spacing: 14

        ) {

          if viewModel.messages.isEmpty
            &&

            !viewModel.isLoading
          {

            emptyState

          }

          ForEach(

            viewModel.messages

          ) { message in

            messageBubble(

              message,

              showsActions:
                latestCompanionMessageID
                == message.id

            )

            .id(

              message.id

            )

          }

          if viewModel.isLoading {

            loadingBubble

              .id(

                "loading"

              )

          }

          Color.clear

            .frame(

              height: 1

            )

            .id(

              "bottom"

            )

        }

        .padding()

      }

      .scrollDismissesKeyboard(.interactively)
      .onChange(

        of:

          viewModel.messages.count

      ) { _, _ in

        scrollToBottom(

          proxy

        )

      }

      .onChange(

        of:

          viewModel.isLoading

      ) { _, _ in

        scrollToBottom(

          proxy

        )

      }

    }

  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("What's on your mind?").font(.title2.bold())
      Text("Ask about a passage, explore a question about faith, or talk through your day.")
        .foregroundStyle(AppTheme.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(22)
    .cloudCard()
  }

  // MARK: - Message Bubble

  @ViewBuilder
  private func messageBubble(
    _ message: Message,
    showsActions: Bool
  ) -> some View {

    if message.isUser {

      HStack {

        Spacer(
          minLength: 50
        )

        MessageText(
          text:
            message.text
        )
        .padding(
          .horizontal,
          14
        )
        .padding(
          .vertical,
          11
        )
        .background(
          CompanionCloudBubbleBackground(isUser: true)
        )
        .foregroundStyle(
          .white
        )
      }

    } else {

      CompanionResponseCard(
        text:
          message.text,
        showsActions:
          showsActions,
        actionsDisabled:
          viewModel.isLoading
          || !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        contextualSuggestions: CompanionFollowUpSuggestions.make(
          answer: message.text, passage: passage),
        onQuickFollowUp: { prompt in

          sendQuickFollowUp(
            prompt
          )
        }
      )
    }
  }

  // MARK: - Loading

  private var loadingBubble:

    some View
  {

    HStack(

      alignment: .center,

      spacing: 10

    ) {

      CompanionAvatar(
        size: 36,
        behavior: .thinking
      )

      HStack(

        spacing: 8

      ) {

        ProgressView()

        Text(

          "Thinking..."

        )

        .font(

          .subheadline

        )

        .foregroundStyle(AppTheme.textSecondary)

      }

      .padding(

        .horizontal,

        14

      )

      .padding(

        .vertical,

        11

      )

      .background(
        CompanionCloudBubbleBackground(isUser: false)
      )

      Spacer()

    }

  }

  // MARK: - Input

  private var inputArea: some View {
    CompanionComposer(
      model: viewModel,
      placeholder: inputPlaceholder,
      initialPrompt: initialPrompt,
      onDraftChanged: { draftIsEmpty = $0 },
      onSend: sendCurrentMessage
    )
  }

  // MARK: - Startup

  private func handleInitialStartup() {

    // Restore the appropriate persistent conversation.

    // Normal Companion uses "general-companion".

    // Journey/checkpoint discussions keep their own key.

    viewModel.configureConversation(

      key:

        resolvedConversationKey

    )

    // Guided Journey discussion.

    // Companion speaks first.

    if let autoStartPrompt {

      Task {

        await viewModel

          .startGuidedSession(

            prompt:

              autoStartPrompt,

            passage:

              passage,

            mode:

              mode,

            lens:

              preferences

              .selectedLens,

            profile:

              onboardingViewModel

              .profile

          )

      }

      return

    }

    // Normal Companion usage:

    // place supplied prompt

    // into the input field.

    if let initialPrompt,

      viewModel.inputText.isEmpty,

      viewModel.messages.isEmpty
    {

      viewModel.inputText =

        initialPrompt

    }

  }

  // MARK: - Send

  private func sendCurrentMessage() {

    guard canSend else {

      return

    }

    Task {

      await viewModel

        .sendMessage(

          passage:

            passage,

          mode:

            mode,

          lens:

            preferences

            .selectedLens,

          profile:

            onboardingViewModel

            .profile

        )

    }

  }

  // MARK: - Quick Follow-Up

  private func sendQuickFollowUp(
    _ prompt: String
  ) {
    guard !viewModel.isLoading, draftIsEmpty,
      viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return
    }

    viewModel.inputText =
      prompt

    sendCurrentMessage()
  }

  // MARK: - Scroll

  private func scrollToBottom(

    _ proxy:

      ScrollViewProxy

  ) {

    withAnimation {

      proxy.scrollTo(

        "bottom",

        anchor:

          .bottom

      )

    }

  }

  // MARK: - Computed

  private var latestCompanionMessageID: Message.ID? {
    guard let latest = viewModel.messages.last, !latest.isUser else { return nil }
    return latest.id
  }

  private var canSend: Bool {

    !viewModel.inputText

      .trimmingCharacters(

        in:

          .whitespacesAndNewlines

      )

      .isEmpty

      &&

      !viewModel.isLoading

  }

  private var inputPlaceholder:

    String
  {

    switch preferences

      .selectedLens
    {

    case .guide:

      return

        "Ask or share what you noticed..."

    case .scholar:

      return

        "Ask a deeper question..."

    case .challenger:

      return

        "Share your reasoning..."

    }

  }

  private var emptyStateText:

    String
  {

    switch preferences

      .selectedLens
    {

    case .guide:

      return

        "We'll work through Scripture together one step at a time."

    case .scholar:

      return

        "Explore context, connections, and major interpretations in greater depth."

    case .challenger:

      return

        "Share your interpretation and I'll help you test how well it fits the text."

    }

  }

}

// MARK: - Markdown Text

private struct MessageText:
  View
{

  let text: String

  var body: some View {

    InlineMarkdownText(
      text: text
    )
    .textSelection(
      .enabled
    )
  }
}

// =========================================================
// MARK: - Companion Response Card
// =========================================================

private struct CompanionResponseCard:
  View
{

  let text: String
  let showsActions: Bool
  let actionsDisabled: Bool
  let contextualSuggestions: [CompanionFollowUpSuggestion]
  let onQuickFollowUp: (String) -> Void

  @State
  private var isExpanded =
    false

  private var blocks: [CompanionResponseBlock] {

    CompanionResponseParser
      .parse(
        text
      )
  }

  private var shouldCollapse: Bool {

    text.count > 700
      || blocks.count > 6
  }

  private var visibleBlocks: [CompanionResponseBlock] {

    guard
      shouldCollapse,
      !isExpanded
    else {
      return blocks
    }

    return Array(
      blocks.prefix(4)
    )
  }

  var body: some View {

    HStack(
      alignment: .top,
      spacing: 10
    ) {

      CompanionAvatar(
        size: 36
      )

      VStack(
        alignment: .leading,
        spacing: 12
      ) {

        HStack(
          spacing: 6
        ) {

          Text(
            "Companion"
          )
          .font(
            .caption
          )
          .fontWeight(
            .semibold
          )

          Image(
            systemName:
              "sparkles"
          )
          .font(
            .caption2
          )
          .foregroundStyle(
            AppTheme.accent
          )
        }

        VStack(
          alignment: .leading,
          spacing: 12
        ) {

          ForEach(
            visibleBlocks
          ) { block in

            CompanionResponseBlockView(
              block:
                block
            )
          }
        }
        .textSelection(
          .enabled
        )

        if shouldCollapse {

          Button {

            withAnimation(
              .easeInOut(
                duration: 0.20
              )
            ) {

              isExpanded.toggle()
            }

          } label: {

            HStack(
              spacing: 5
            ) {

              Text(
                isExpanded
                  ? "Show less"
                  : "Show full answer"
              )

              Image(
                systemName:
                  isExpanded
                  ? "chevron.up"
                  : "chevron.down"
              )
            }
            .font(
              .caption
            )
            .fontWeight(
              .semibold
            )
          }
          .buttonStyle(
            .plain
          )
          .foregroundStyle(
            AppTheme.accent
          )
        }

        if showsActions {
          Divider()
          if !contextualSuggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
              Text("KEEP EXPLORING").font(.caption2.weight(.bold)).foregroundStyle(AppTheme.textSecondary)
              ForEach(contextualSuggestions) { suggestion in
                Button {
                  onQuickFollowUp(suggestion.prompt)
                } label: {
                  Label(suggestion.title, systemImage: suggestion.icon)
                    .font(.subheadline).multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)
                .disabled(actionsDisabled)
              }
            }
          }
          quickActions
        }
      }
      .padding(
        .horizontal,
        15
      )
      .padding(
        .vertical,
        13
      )
      .frame(
        maxWidth:
          .infinity,
        alignment:
          .leading
      )
      .background(
        CompanionCloudBubbleBackground(isUser: false)
      )

      Spacer(
        minLength: 8
      )
    }
  }

  private var quickActions: some View {

    ScrollView(
      .horizontal,
      showsIndicators:
        false
    ) {

      HStack(
        spacing: 8
      ) {

        CompanionQuickActionButton(
          title:
            "Simpler",
          icon:
            "text.badge.minus",
          isDisabled:
            actionsDisabled
        ) {

          onQuickFollowUp(
            "Can you explain that more simply?"
          )
        }

        CompanionQuickActionButton(
          title:
            "Go deeper",
          icon:
            "arrow.down.forward.and.arrow.up.backward",
          isDisabled:
            actionsDisabled
        ) {

          onQuickFollowUp(
            "Go a little deeper on that."
          )
        }

        CompanionQuickActionButton(
          title:
            "Show verses",
          icon:
            "book.closed",
          isDisabled:
            actionsDisabled
        ) {

          onQuickFollowUp(
            "What Bible verses best support that?"
          )
        }
      }
    }
  }
}

// =========================================================
// MARK: - Quick Action Button
// =========================================================

private struct CompanionQuickActionButton:
  View
{

  let title: String
  let icon: String
  let isDisabled: Bool
  let action: () -> Void

  var body: some View {

    Button(
      action:
        action
    ) {

      HStack(
        spacing: 6
      ) {

        Image(
          systemName:
            icon
        )

        Text(
          title
        )
      }
      .font(
        .caption
      )
      .fontWeight(
        .semibold
      )
      .padding(
        .horizontal,
        11
      )
      .padding(
        .vertical,
        8
      )
      .background(
        Capsule()
          .fill(
            AppTheme.accent
              .opacity(
                isDisabled
                  ? 0.05
                  : 0.10
              )
          )
      )
      .foregroundStyle(
        isDisabled
          ? AppTheme.textSecondary
          : AppTheme.accent
      )
    }
    .buttonStyle(
      .plain
    )
    .disabled(
      isDisabled
    )
  }
}

// =========================================================
// MARK: - Formatted Response Blocks
// =========================================================

private struct CompanionResponseBlock:
  Identifiable
{

  enum Kind {
    case heading(String)
    case paragraph(String)
    case bullets([String])
    case numbered([String])
  }

  let id =
    UUID()

  let kind: Kind
}

private enum CompanionResponseParser {

  static func parse(
    _ text: String
  ) -> [CompanionResponseBlock] {

    let normalized =
      text
      .replacingOccurrences(
        of: "\r\n",
        with: "\n"
      )
      .replacingOccurrences(
        of: "\r",
        with: "\n"
      )

    let lines =
      normalized
      .components(
        separatedBy:
          "\n"
      )

    var blocks: [CompanionResponseBlock] = []

    var paragraphLines: [String] = []

    var bulletItems: [String] = []

    var numberedItems: [String] = []

    func flushParagraph() {

      let paragraph =
        paragraphLines
        .joined(
          separator: " "
        )
        .trimmingCharacters(
          in:
            .whitespacesAndNewlines
        )

      if !paragraph.isEmpty {

        blocks.append(
          CompanionResponseBlock(
            kind:
              .paragraph(
                paragraph
              )
          )
        )
      }

      paragraphLines.removeAll()
    }

    func flushBullets() {

      guard !bulletItems.isEmpty else {
        return
      }

      blocks.append(
        CompanionResponseBlock(
          kind:
            .bullets(
              bulletItems
            )
        )
      )

      bulletItems.removeAll()
    }

    func flushNumbered() {

      guard !numberedItems.isEmpty else {
        return
      }

      blocks.append(
        CompanionResponseBlock(
          kind:
            .numbered(
              numberedItems
            )
        )
      )

      numberedItems.removeAll()
    }

    func flushLists() {
      flushBullets()
      flushNumbered()
    }

    for rawLine in lines {

      let line =
        rawLine
        .trimmingCharacters(
          in:
            .whitespacesAndNewlines
        )

      if line.isEmpty {

        flushParagraph()
        flushLists()
        continue
      }

      if let heading =
        headingText(
          from:
            line
        )
      {

        flushParagraph()
        flushLists()

        blocks.append(
          CompanionResponseBlock(
            kind:
              .heading(
                heading
              )
          )
        )

        continue
      }

      if let bullet =
        bulletText(
          from:
            line
        )
      {

        flushParagraph()
        flushNumbered()

        bulletItems.append(
          bullet
        )

        continue
      }

      if let numbered =
        numberedText(
          from:
            line
        )
      {

        flushParagraph()
        flushBullets()

        numberedItems.append(
          numbered
        )

        continue
      }

      flushLists()
      paragraphLines.append(
        line
      )
    }

    flushParagraph()
    flushLists()

    if blocks.isEmpty {

      return [
        CompanionResponseBlock(
          kind:
            .paragraph(
              text
            )
        )
      ]
    }

    return blocks
  }

  private static func headingText(
    from line: String
  ) -> String? {

    let hashTrimmed =
      line
      .trimmingCharacters(
        in:
          CharacterSet(
            charactersIn: "# "
          )
      )

    if line.hasPrefix("#"),
      !hashTrimmed.isEmpty
    {

      return hashTrimmed
    }

    if line.hasPrefix("**"),
      line.hasSuffix("**"),
      line.count > 4
    {

      return String(
        line
          .dropFirst(2)
          .dropLast(2)
      )
      .trimmingCharacters(
        in:
          .whitespacesAndNewlines
      )
    }

    return nil
  }

  private static func bulletText(
    from line: String
  ) -> String? {

    for prefix in [
      "- ",
      "* ",
      "• ",
    ] {

      if line.hasPrefix(
        prefix
      ) {

        return String(
          line.dropFirst(
            prefix.count
          )
        )
      }
    }

    return nil
  }

  private static func numberedText(
    from line: String
  ) -> String? {

    guard
      let period =
        line.firstIndex(
          of: "."
        )
    else {
      return nil
    }

    let numberPart =
      line[..<period]

    guard
      !numberPart.isEmpty,
      numberPart.allSatisfy(
        { $0.isNumber }
      )
    else {
      return nil
    }

    let contentStart =
      line.index(
        after:
          period
      )

    let content =
      line[contentStart...]
      .trimmingCharacters(
        in:
          .whitespacesAndNewlines
      )

    return content.isEmpty
      ? nil
      : content
  }
}

// =========================================================
// MARK: - Response Block View
// =========================================================

private struct CompanionResponseBlockView:
  View
{

  let block: CompanionResponseBlock

  var body: some View {

    switch block.kind {

    case .heading(
      let text
    ):

      InlineMarkdownText(
        text: text
      )
      .font(
        .subheadline
      )
      .fontWeight(
        .bold
      )
      .padding(
        .top,
        2
      )

    case .paragraph(
      let text
    ):

      InlineMarkdownText(
        text: text
      )
      .font(
        .body
      )
      .lineSpacing(
        4
      )
      .fixedSize(
        horizontal: false,
        vertical: true
      )

    case .bullets(
      let items
    ):

      VStack(
        alignment: .leading,
        spacing: 8
      ) {

        ForEach(
          Array(
            items.enumerated()
          ),
          id: \.offset
        ) { _, item in

          HStack(
            alignment: .top,
            spacing: 9
          ) {

            Circle()
              .fill(
                AppTheme.accent
              )
              .frame(
                width: 5,
                height: 5
              )
              .padding(
                .top,
                8
              )

            InlineMarkdownText(
              text: item
            )
            .font(
              .body
            )
            .lineSpacing(
              3
            )
          }
        }
      }

    case .numbered(
      let items
    ):

      VStack(
        alignment: .leading,
        spacing: 8
      ) {

        ForEach(
          Array(
            items.enumerated()
          ),
          id: \.offset
        ) { index, item in

          HStack(
            alignment: .top,
            spacing: 9
          ) {

            Text(
              "\(index + 1)."
            )
            .font(
              .caption
            )
            .fontWeight(
              .bold
            )
            .foregroundStyle(
              AppTheme.accent
            )
            .frame(
              width: 20,
              alignment:
                .trailing
            )
            .padding(
              .top,
              2
            )

            InlineMarkdownText(
              text: item
            )
            .font(
              .body
            )
            .lineSpacing(
              3
            )
          }
        }
      }
    }
  }
}

// =========================================================
// MARK: - Inline Markdown
// =========================================================

private struct InlineMarkdownText:
  View
{

  let text: String

  var body: some View {

    if let attributedText =
      try? AttributedString(
        markdown:
          text
      )
    {

      Text(
        attributedText
      )

    } else {

      Text(
        text
      )
    }
  }
}
