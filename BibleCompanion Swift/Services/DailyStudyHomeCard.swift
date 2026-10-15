import SwiftUI

// =========================================================
// MARK: - Daily Study Home Card
// =========================================================

struct DailyStudyHomeCard: View {

  let plan: DailyStudyPlan
  let isComplete: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .center, spacing: 12) {
        CompanionAvatar(
          size: 50,
          behavior: isComplete ? .still : .floating
        )

        VStack(alignment: .leading, spacing: 3) {
          Text("DAILY WITH COMPANION")
            .font(.caption)
            .fontWeight(.bold)
            .tracking(0.7)
            .foregroundStyle(AppTheme.textSecondary)

          Text(plan.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
        }

        Spacer()

        if isComplete {
          Image(systemName: "checkmark.circle.fill")
            .font(.title2)
            .foregroundStyle(AppTheme.accent)
            .accessibilityLabel("Today's Daily Study is complete")
        }
      }

      VStack(alignment: .leading, spacing: 6) {
        Text(plan.title)
          .font(.title3)
          .fontWeight(.bold)
          .foregroundStyle(AppTheme.textPrimary)

        Text(plan.reference)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(AppTheme.accent)
      }

      Text(plan.reason)
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .lineSpacing(2)
        .lineLimit(3)

      HStack(spacing: 8) {
        Text(isComplete ? "Revisit Today's Study" : "Begin Today's Study")
          .fontWeight(.semibold)

        Spacer()

        Image(systemName: "arrow.right")
          .font(.caption.weight(.bold))
      }
      .foregroundStyle(AppTheme.accent)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(AppTheme.cardGradient)
        .shadow(color: AppTheme.shadow, radius: 14, y: 6)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(Color.white.opacity(0.76), lineWidth: 1)
    )
    .accessibilityElement(children: .combine)
  }
}
