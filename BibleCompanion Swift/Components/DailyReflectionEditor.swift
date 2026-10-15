import SwiftUI

struct DailyReflectionEditor: View {
  let model: DailyStudyViewModel
  @State private var draft: String

  init(model: DailyStudyViewModel) {
    self.model = model
    _draft = State(initialValue: model.reflection)
  }

  var body: some View {
    TextEditor(text: $draft)
      .accessibilityLabel("Your daily reflection")
      .onChange(of: draft) { _, text in
        model.reflection = text
        model.reflectionChanged()
      }
  }
}
