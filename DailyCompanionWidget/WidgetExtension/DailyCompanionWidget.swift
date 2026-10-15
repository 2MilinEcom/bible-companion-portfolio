import SwiftUI
import WidgetKit

// =========================================================
// MARK: - Timeline Entry
// =========================================================

struct DailyCompanionEntry: TimelineEntry {
  let date: Date
  let snapshot: DailyWidgetSnapshot?
}

// =========================================================
// MARK: - Timeline Provider
// =========================================================

struct DailyCompanionProvider: TimelineProvider {

  func placeholder(in context: Context) -> DailyCompanionEntry {
    DailyCompanionEntry(
      date: Date(),
      snapshot: DailyWidgetSnapshot(
        dateKey: DailyWidgetShared.dateKey(for: Date()),
        date: Calendar.autoupdatingCurrent.startOfDay(for: Date()),
        title: "Remain connected",
        reference: "John 15:4-5",
        verseText: "Remain in me, as I also remain in you.",
        isCompleted: false
      )
    )
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (DailyCompanionEntry) -> Void
  ) {
    // The widget gallery gets a useful visual preview even before the app has
    // published real data. Once installed, real App Group data is preferred.
    if context.isPreview {
      completion(placeholder(in: context))
      return
    }

    completion(entry(for: Date()))
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<DailyCompanionEntry>) -> Void
  ) {
    let now = Date()
    let payload = DailyWidgetShared.loadPayload()
    let snapshots = payload?.snapshots.sorted { $0.date < $1.date } ?? []

    guard !snapshots.isEmpty else {
      let retry = Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 20, to: now)
        ?? now.addingTimeInterval(1_200)

      completion(
        Timeline(
          entries: [DailyCompanionEntry(date: now, snapshot: nil)],
          policy: .after(retry)
        )
      )
      return
    }

    var entries: [DailyCompanionEntry] = []

    // Prefer the exact current day. If a stale timeline slips through during a
    // date transition, use the nearest available snapshot rather than showing
    // a blank widget.
    let current = bestSnapshot(for: now, snapshots: snapshots)

    entries.append(
      DailyCompanionEntry(
        date: now,
        snapshot: current
      )
    )

    for snapshot in snapshots where snapshot.date > now {
      entries.append(
        DailyCompanionEntry(
          date: snapshot.date,
          snapshot: snapshot
        )
      )
    }

    let nextDay = Calendar.autoupdatingCurrent.startOfDay(
      for: Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: now)
        ?? now.addingTimeInterval(86_400)
    )

    completion(
      Timeline(
        entries: entries,
        policy: .after(nextDay)
      )
    )
  }

  private func entry(for date: Date) -> DailyCompanionEntry {
    let snapshots = DailyWidgetShared.loadPayload()?.snapshots ?? []
    return DailyCompanionEntry(
      date: date,
      snapshot: bestSnapshot(for: date, snapshots: snapshots)
    )
  }

  private func bestSnapshot(
    for date: Date,
    snapshots: [DailyWidgetSnapshot]
  ) -> DailyWidgetSnapshot? {
    guard !snapshots.isEmpty else { return nil }

    let key = DailyWidgetShared.dateKey(for: date)
    if let exact = snapshots.first(where: { $0.dateKey == key }) {
      return exact
    }

    return snapshots.min {
      abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
    }
  }
}

// =========================================================
// MARK: - Widget View
// =========================================================

struct DailyCompanionWidgetView: View {

  @Environment(\.widgetFamily)
  private var family

  let entry: DailyCompanionEntry

  var body: some View {
    Group {
      switch family {
      case .systemMedium:
        mediumView

      case .accessoryInline:
        accessoryInlineView

      case .accessoryRectangular:
        accessoryRectangularView

      default:
        smallView
      }
    }
    .widgetURL(DailyWidgetShared.todayDeepLinkURL)
    .containerBackground(for: .widget) {
      LinearGradient(
        colors: [
          Color.orange.opacity(0.13),
          Color.yellow.opacity(0.045),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  // =====================================================
  // MARK: Home Screen Small
  // =====================================================

  private var smallView: some View {
    VStack(alignment: .leading, spacing: 7) {
      topLabel

      if let snapshot = entry.snapshot {
        Text(snapshot.reference)
          .font(.headline)
          .fontWeight(.bold)
          .minimumScaleFactor(0.76)
          .lineLimit(1)

        Text("“\(snapshot.verseText)”")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
          .lineLimit(5)
          .minimumScaleFactor(0.82)

        Spacer(minLength: 0)

        HStack(alignment: .bottom, spacing: 5) {
          VStack(alignment: .leading, spacing: 2) {
            Text(snapshot.isCompleted ? "Revisit today's study" : snapshot.title)
              .font(.caption2)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)
              .lineLimit(2)

            Text("Tap to open")
              .font(.system(size: 9, weight: .medium))
              .foregroundStyle(.tertiary)
          }

          Spacer(minLength: 0)

          mascot(size: 35)
        }
      } else {
        emptyState(compact: true)
      }
    }
  }

  // =====================================================
  // MARK: Home Screen Medium
  // =====================================================

  private var mediumView: some View {
    HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 6) {
        topLabel

        if let snapshot = entry.snapshot {
          Text(snapshot.title)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(1)

          Text(snapshot.reference)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)

          Text("“\(snapshot.verseText)”")
            .font(.subheadline)
            .fontWeight(.medium)
            .lineLimit(4)
            .minimumScaleFactor(0.82)

          Spacer(minLength: 0)

          HStack(spacing: 5) {
            if snapshot.isCompleted {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            } else {
              Image(systemName: "book.closed.fill")
                .foregroundStyle(.orange)
            }

            Text(snapshot.isCompleted ? "Revisit today's study" : "Tap for today's study")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)
          }
        } else {
          emptyState(compact: false)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      mascot(size: 82)
        .frame(width: 86)
    }
  }

  // =====================================================
  // MARK: Lock Screen
  // =====================================================

  private var accessoryInlineView: some View {
    if let snapshot = entry.snapshot {
      Text("\(snapshot.reference) • \(shortVerse(snapshot.verseText, limit: 54))")
    } else {
      Text("Daily Companion • Open Bible Companion")
    }
  }

  private var accessoryRectangularView: some View {
    VStack(alignment: .leading, spacing: 2) {
      if let snapshot = entry.snapshot {
        HStack(spacing: 4) {
          Image(systemName: snapshot.isCompleted ? "checkmark.circle.fill" : "book.closed.fill")
          Text(snapshot.reference)
            .fontWeight(.semibold)
        }

        Text(snapshot.verseText)
          .font(.caption2)
          .lineLimit(2)
      } else {
        Text("Daily Companion")
          .fontWeight(.semibold)
        Text("Open Bible Companion once to prepare today's Scripture.")
          .font(.caption2)
          .lineLimit(2)
      }
    }
  }

  // =====================================================
  // MARK: Shared Pieces
  // =====================================================

  private var topLabel: some View {
    HStack(spacing: 5) {
      Image(systemName: entry.snapshot?.isCompleted == true ? "checkmark.circle.fill" : "sparkles")
        .foregroundStyle(entry.snapshot?.isCompleted == true ? Color.green : Color.orange)

      Text(entry.snapshot?.isCompleted == true ? "TODAY COMPLETE" : "TODAY'S SCRIPTURE")
        .font(.caption2)
        .fontWeight(.bold)
        .tracking(0.45)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private func emptyState(compact: Bool) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Open Bible Companion")
        .font(compact ? .subheadline : .headline)
        .fontWeight(.semibold)

      Text("Open the app once and visit Home to prepare today's Scripture preview.")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(compact ? 4 : 3)
    }
  }

  private func mascot(size: CGFloat) -> some View {
    Image("CompanionWidgetMascot")
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
      .accessibilityHidden(true)
  }

  private func shortVerse(_ text: String, limit: Int) -> String {
    let cleaned = text
      .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard cleaned.count > limit else { return cleaned }
    return String(cleaned.prefix(max(1, limit - 1))).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
  }
}

// =========================================================
// MARK: - Widget Definition
// =========================================================

@main
struct DailyCompanionWidget: Widget {

  let kind = DailyWidgetShared.widgetKind

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: DailyCompanionProvider()
    ) { entry in
      DailyCompanionWidgetView(entry: entry)
    }
    .configurationDisplayName("Daily Companion")
    .description("Preview today's Scripture and open the full Daily Study.")
    .supportedFamilies([
      .systemSmall,
      .systemMedium,
      .accessoryInline,
      .accessoryRectangular,
    ])
  }
}
