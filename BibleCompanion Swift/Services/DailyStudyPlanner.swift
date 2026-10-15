import Foundation

// =========================================================
// MARK: - Daily Study Planner
// =========================================================

/// Selects one short passage for the day without making a network request.
///
/// Selection can gently follow the user's explicit current focus or goal, but
/// it never infers a spiritual label. Recent passages are avoided when there
/// are other suitable choices.
enum DailyStudyPlanner {

  private struct CatalogItem {
    let title: String
    let reference: String
    let categories: Set<String>
  }

  static func makePlan(
    for date: Date = Date(),
    focusText: String,
    goalText: String,
    recentReferences: [String] = [],
    previousPlans: [DailyStudyPlan] = []
  ) -> DailyStudyPlan {

    let dateKey = DailyStudyDay.key(for: date)
    let cleanFocus = cleaned(focusText)
    let cleanGoal = cleaned(goalText)
    let category = detectedCategory(in: [cleanFocus, cleanGoal].joined(separator: " "))

    let matching = catalog.filter { item in
      item.categories.contains(category)
        || (category == "general" && item.categories.contains("general"))
    }

    let candidates = matching.isEmpty
      ? catalog.filter { $0.categories.contains("general") }
      : matching

    let avoided = Set(
      (recentReferences + previousPlans.prefix(10).map(\.reference))
        .map { normalizedReference($0) }
    )

    let fresh = candidates.filter { !avoided.contains(normalizedReference($0.reference)) }
    let pool = fresh.isEmpty ? candidates : fresh

    let seed = stableHash("\(dateKey)|\(category)|\(cleanFocus)|\(cleanGoal)")
    let item = pool[Int(seed % UInt64(max(pool.count, 1)))]

    let reasonTitle: String
    let reason: String
    let focusLabel: String

    if !cleanFocus.isEmpty, category != "general" {
      focusLabel = shortened(cleanFocus, limit: 72)
      reasonTitle = "Connected to your current focus"
      reason = "This passage connects with what you're already working through: \(focusLabel)."
    } else if !cleanGoal.isEmpty {
      focusLabel = shortened(cleanGoal, limit: 72)
      reasonTitle = "Chosen with your goal in mind"
      reason = "A short passage chosen with this goal in mind: \(focusLabel)."
    } else {
      focusLabel = "Return to Scripture"
      reasonTitle = "A daily place to begin"
      reason = "A short passage to help you slow down, read carefully, and return to Scripture today."
    }

    return DailyStudyPlan(
      dateKey: dateKey,
      date: DailyStudyDay.startOfDay(for: date),
      title: item.title,
      reference: item.reference,
      focusLabel: focusLabel,
      reasonTitle: reasonTitle,
      reason: reason,
      category: category
    )
  }

  // =====================================================
  // MARK: - Category Detection
  // =====================================================

  private static func detectedCategory(in text: String) -> String {
    let value = text.lowercased()

    let groups: [(String, [String])] = [
      ("anger", ["anger", "angry", "rage", "temper", "resent"]),
      ("fear", ["fear", "worry", "anxiety", "anxious", "afraid", "uncertain"]),
      ("grief", ["grief", "loss", "mourning", "died", "death"]),
      ("doubt", ["doubt", "questioning", "uncertain about god", "faith feels uncertain"]),
      ("forgiveness", ["forgive", "forgiveness", "bitterness", "betray"]),
      ("temptation", ["temptation", "tempted", "lust", "resist"]),
      ("relationships", ["relationship", "conflict", "boundary", "trust", "marriage", "friendship"]),
      ("prayer", ["prayer", "pray", "consistency", "distant from god"]),
      ("purpose", ["purpose", "direction", "calling", "next step", "behind"]),
      ("loneliness", ["lonely", "loneliness", "alone", "disconnected", "belong"]),
      ("self-control", ["self-control", "self control", "discipline", "repeating the same", "habit"]),
      ("jesus", ["jesus", "gospel", "know christ", "meet jesus"]),
    ]

    for (category, words) in groups where words.contains(where: { value.contains($0) }) {
      return category
    }

    return "general"
  }

  // =====================================================
  // MARK: - Helpers
  // =====================================================

  private static func cleaned(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func shortened(_ value: String, limit: Int) -> String {
    guard value.count > limit else { return value }
    return String(value.prefix(max(1, limit - 1))) + "…"
  }

  private static func normalizedReference(_ value: String) -> String {
    BibleLibraryReference.normalizedText(value)
  }

  /// Stable FNV-1a hash. Swift's `hashValue` changes between launches, so it
  /// must not be used for a deterministic daily choice.
  private static func stableHash(_ value: String) -> UInt64 {
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in value.utf8 {
      hash ^= UInt64(byte)
      hash = hash &* 1_099_511_628_211
    }
    return hash
  }

  // =====================================================
  // MARK: - Curated Passage Pool
  // =====================================================

  private static let catalog: [CatalogItem] = [
    .init(title: "Rest when you're carrying too much", reference: "Matthew 11:28-30", categories: ["general", "fear"]),
    .init(title: "Remain connected", reference: "John 15:4-5", categories: ["general", "jesus"]),
    .init(title: "Nothing can separate you", reference: "Romans 8:38-39", categories: ["general", "loneliness", "fear"]),
    .init(title: "Bring your needs to God", reference: "Philippians 4:6-7", categories: ["general", "prayer", "fear"]),
    .init(title: "Ask for wisdom", reference: "James 1:5", categories: ["general", "purpose", "doubt"]),
    .init(title: "Walk humbly today", reference: "Micah 6:8", categories: ["general", "purpose"]),
    .init(title: "Come honestly for help", reference: "Hebrews 4:14-16", categories: ["general", "temptation", "prayer"]),
    .init(title: "God is present in trouble", reference: "Psalms 46:1-3", categories: ["general", "fear", "grief"]),
    .init(title: "Put on compassion and love", reference: "Colossians 3:12-14", categories: ["general", "relationships", "forgiveness"]),
    .init(title: "Let your mind be renewed", reference: "Romans 12:1-2", categories: ["general", "purpose", "self-control"]),

    .init(title: "Be quick to listen", reference: "James 1:19-20", categories: ["anger", "relationships"]),
    .init(title: "Do something faithful with anger", reference: "Ephesians 4:26-27", categories: ["anger"]),
    .init(title: "A gentle answer", reference: "Proverbs 15:1", categories: ["anger", "relationships"]),
    .init(title: "Refuse revenge", reference: "Romans 12:17-21", categories: ["anger", "forgiveness", "relationships"]),

    .init(title: "You are not facing fear alone", reference: "Isaiah 41:10", categories: ["fear", "loneliness"]),
    .init(title: "When you're afraid", reference: "Psalms 56:3-4", categories: ["fear"]),
    .init(title: "Cast your anxieties on God", reference: "1 Peter 5:6-7", categories: ["fear", "prayer"]),
    .init(title: "Peace that is different", reference: "John 14:27", categories: ["fear", "jesus"]),
    .init(title: "Today's trouble is enough", reference: "Matthew 6:31-34", categories: ["fear"]),

    .init(title: "God is near the brokenhearted", reference: "Psalms 34:17-18", categories: ["grief", "loneliness"]),
    .init(title: "Jesus meets grief with tears", reference: "John 11:32-36", categories: ["grief", "jesus"]),
    .init(title: "Comfort received and shared", reference: "2 Corinthians 1:3-4", categories: ["grief"]),
    .init(title: "A future without mourning", reference: "Revelation 21:3-4", categories: ["grief"]),

    .init(title: "Bring belief and doubt together", reference: "Mark 9:23-24", categories: ["doubt", "jesus"]),
    .init(title: "Thomas gets room to see", reference: "John 20:26-29", categories: ["doubt", "jesus"]),
    .init(title: "Hold on when understanding is hard", reference: "Psalms 73:23-26", categories: ["doubt"]),
    .init(title: "Have mercy on those who doubt", reference: "Jude 1:20-22", categories: ["doubt", "relationships"]),

    .init(title: "Forgive as you were forgiven", reference: "Colossians 3:12-13", categories: ["forgiveness", "relationships"]),
    .init(title: "Put bitterness away", reference: "Ephesians 4:31-32", categories: ["forgiveness", "anger"]),
    .init(title: "Take forgiveness seriously", reference: "Matthew 6:14-15", categories: ["forgiveness"]),

    .init(title: "Temptation is not the end of the story", reference: "1 Corinthians 10:13", categories: ["temptation", "self-control"]),
    .init(title: "Notice how desire grows", reference: "James 1:12-15", categories: ["temptation", "self-control"]),
    .init(title: "Answer temptation with truth", reference: "Matthew 4:1-4", categories: ["temptation", "jesus"]),
    .init(title: "Store God's word close", reference: "Psalms 119:9-11", categories: ["temptation", "self-control"]),

    .init(title: "Choose humility in relationships", reference: "Philippians 2:3-4", categories: ["relationships"]),
    .init(title: "What patient love looks like", reference: "1 Corinthians 13:4-7", categories: ["relationships"]),
    .init(title: "Protect unity with humility", reference: "Ephesians 4:2-3", categories: ["relationships"]),
    .init(title: "People can sharpen people", reference: "Proverbs 27:17", categories: ["relationships"]),

    .init(title: "A pattern for prayer", reference: "Matthew 6:9-13", categories: ["prayer", "jesus"]),
    .init(title: "Keep asking and seeking", reference: "Luke 11:9-13", categories: ["prayer", "jesus"]),
    .init(title: "Pour out your heart", reference: "Psalms 62:8", categories: ["prayer", "fear"]),

    .init(title: "Created for good work", reference: "Ephesians 2:10", categories: ["purpose"]),
    .init(title: "Trust before you can see the whole path", reference: "Proverbs 3:5-6", categories: ["purpose", "fear"]),
    .init(title: "Do it in Jesus' name", reference: "Colossians 3:17", categories: ["purpose", "jesus"]),

    .init(title: "God does not abandon you", reference: "Hebrews 13:5-6", categories: ["loneliness", "fear"]),
    .init(title: "There is nowhere God cannot meet you", reference: "Psalms 139:7-10", categories: ["loneliness"]),
    .init(title: "Jesus does not leave his people orphaned", reference: "John 14:18", categories: ["loneliness", "jesus"]),

    .init(title: "The Spirit forms self-control", reference: "Galatians 5:22-23", categories: ["self-control"]),
    .init(title: "Power, love, and self-control", reference: "2 Timothy 1:7", categories: ["self-control", "fear"]),
    .init(title: "A life without self-control is exposed", reference: "Proverbs 25:28", categories: ["self-control"]),
    .init(title: "Grace trains us", reference: "Titus 2:11-12", categories: ["self-control", "temptation"]),

    .init(title: "God loved the world", reference: "John 3:16-17", categories: ["jesus"]),
    .init(title: "Jesus announces good news", reference: "Mark 1:14-15", categories: ["jesus"]),
    .init(title: "Jesus came to seek and save", reference: "Luke 19:9-10", categories: ["jesus"]),
    .init(title: "The good shepherd gives himself", reference: "John 10:10-11", categories: ["jesus"]),
    .init(title: "Following Jesus costs something", reference: "Matthew 16:24-25", categories: ["jesus"]),
  ]
}
