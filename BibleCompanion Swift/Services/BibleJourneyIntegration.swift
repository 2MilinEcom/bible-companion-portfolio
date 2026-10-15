import SwiftUI

struct BibleLibraryJourneyMatch: Identifiable {
  let journey: JourneyPath
  let checkpoint: JourneyCheckpoint
  let isOrigin: Bool
  var id: String { journey.id + "::" + checkpoint.id }
}

@MainActor
enum BibleLibraryJourneyResolver {
  static func matches(
    location: BibleLibraryLocation, originJourneyID: String? = nil,
    originCheckpointID: String? = nil
  ) -> [BibleLibraryJourneyMatch] {
    var journeys: [JourneyPath] = []
    if let originJourneyID,
      let origin = StorageService.shared.loadPersonalizedJourney(journeyID: originJourneyID)?
        .journey
    {
      journeys.append(origin)
    }
    if let active = StorageService.shared.loadActivePersonalizedPath(),
      !journeys.contains(where: { $0.id == active.id })
    {
      journeys.append(active)
    }
    let foundation = JourneyLibrary.meetJesus
    if !journeys.contains(where: { $0.id == foundation.id }) { journeys.append(foundation) }
    return journeys.flatMap { journey in
      journey.checkpoints.sorted { $0.order < $1.order }.compactMap {
        checkpoint -> BibleLibraryJourneyMatch? in
        guard let checkpointLocation = BibleLibraryReference.parse(checkpoint.passage),
          location.overlaps(checkpointLocation)
        else { return nil }
        return .init(
          journey: journey, checkpoint: checkpoint,
          isOrigin: journey.id == originJourneyID && checkpoint.id == originCheckpointID)
      }
    }.sorted { $0.isOrigin && !$1.isOrigin }
  }
}

@MainActor
struct BibleJourneyReaderBanner: View {
  let match: BibleLibraryJourneyMatch
  let onReturn: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(
        match.isOrigin ? "READING FOR YOUR CHECKPOINT" : "PART OF YOUR PATH", systemImage: "map"
      )
      .font(.caption.weight(.bold)).foregroundStyle(AppTheme.accent)
      Text(match.journey.title).font(.headline)
      Text("Checkpoint \(match.checkpoint.order): \(match.checkpoint.title)")
        .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
      if match.isOrigin {
        Button(action: onReturn) {
          Label("Back to checkpoint", systemImage: "arrow.uturn.backward")
        }
        .buttonStyle(.bordered)
      } else {
        NavigationLink {
          JourneyMapView(journey: match.journey)
        } label: {
          Label("Open this path", systemImage: "arrow.right")
        }
        .buttonStyle(.bordered)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(RoundedRectangle(cornerRadius: 18).fill(AppTheme.accent.opacity(0.07)))
  }
}
