import SwiftUI

/// Typing updates only this small view, never the message list or profile.
struct CompanionComposer: View {
  @ObservedObject var model: CompanionViewModel
  let placeholder: String
  let initialPrompt: String?
  let onDraftChanged: (Bool) -> Void
  let onSend: () -> Void
  @State private var draft = ""
  @State private var initialized = false
  @FocusState private var focused: Bool

  private var isEmpty: Bool {
    draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    HStack(alignment: .bottom, spacing: 10) {
      TextField(placeholder, text: $draft, axis: .vertical)
        .lineLimit(1...6)
        .focused($focused)
        .textFieldStyle(.plain)
        .padding(14)
        .background(AppTheme.surfaceStrong, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.divider))
        .submitLabel(.send)
        .onSubmit(send)
        .accessibilityLabel("Message Companion")
      Button(action: send) {
        Image(systemName: "arrow.up")
          .font(.headline)
          .foregroundStyle(.white)
          .frame(width: 46, height: 46)
          .background(AppTheme.buttonGradient, in: Circle())
      }
      .disabled(isEmpty || model.isLoading)
      .opacity(isEmpty || model.isLoading ? 0.4 : 1)
      .accessibilityLabel("Send message")
    }
    .padding(.horizontal)
    .padding(.vertical, 10)
    .background(AppTheme.surface)
    .onAppear {
      guard !initialized else { return }
      initialized = true
      if model.messages.isEmpty { draft = initialPrompt ?? "" }
      onDraftChanged(isEmpty)
    }
    .onChange(of: isEmpty) { _, empty in onDraftChanged(empty) }
  }

  private func send() {
    guard !isEmpty, !model.isLoading else { return }
    model.inputText = draft
    draft = ""
    onDraftChanged(true)
    onSend()
  }
}
