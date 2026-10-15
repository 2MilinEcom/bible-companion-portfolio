//
//  CompanionGrowthView.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/3/26.
//

import SwiftUI
import Foundation


// =========================================================
// MARK: - Companion Growth Home Card
// =========================================================

struct CompanionGrowthHomeCard:
    View {

    @ObservedObject
    private var growthStore =
        CompanionGrowthStore.shared


    var body: some View {

        NavigationLink {

            CompanionGrowthView()

        } label: {

            HStack(
                spacing: 16
            ) {

                CompanionAvatar(
                    size: 82,
                    behavior: .floating
                )


                VStack(
                    alignment: .leading,
                    spacing: 7
                ) {

                    Text(
                        "YOUR COMPANION"
                    )
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(0.8)
                    .foregroundStyle(AppTheme.textSecondary)


                    Text(
                        growthStore
                            .stage
                            .displayName
                    )
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.textPrimary)


                    if let nextStage =
                        growthStore.nextStage {

                        ProgressView(
                            value:
                                growthStore
                                    .progressToNextStage
                        )
                        .tint(AppTheme.accent)


                        Text(
                            "Growing toward \(nextStage.displayName)"
                        )
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    } else {

                        Text(
                            "Your Companion has reached its mature form."
                        )
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }


                Spacer(
                    minLength: 6
                )


                Image(
                    systemName:
                        "chevron.right"
                )
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(18)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
                .fill(AppTheme.cardGradient)
                .shadow(color: AppTheme.shadow, radius: 14, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.74), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {

            growthStore.refresh()
        }
    }
}


// =========================================================
// MARK: - Companion Growth Detail
// =========================================================

struct CompanionGrowthView:
    View {

    @ObservedObject
    private var growthStore =
        CompanionGrowthStore.shared


    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 26
            ) {

                hero


                growthProgress


                stageTimeline


                whatHelpsGrowth


                milestoneHistory


                meaningNote
            }
            .padding()
        }
        .cloudScreen()
        .navigationTitle(
            "Your Companion"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .onAppear {

            growthStore.refresh()
        }
    }


    // =====================================================
    // MARK: - Hero
    // =====================================================

    private var hero:
        some View {

        VStack(
            spacing: 16
        ) {

            ZStack {

                Circle()
                    .fill(
                        AppTheme.accent
                            .opacity(0.08)
                    )
                    .frame(
                        width: 220,
                        height: 220
                    )


                CompanionAvatar(
                    size: 184,
                    behavior: .floating
                )
            }


            VStack(
                spacing: 7
            ) {

                Text(
                    growthStore
                        .stage
                        .displayName
                )
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)


                Text(
                    growthStore
                        .stage
                        .growthDescription
                )
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(
                    maxWidth: 360
                )
            }
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            10
        )
    }


    // =====================================================
    // MARK: - Progress
    // =====================================================

    @ViewBuilder
    private var growthProgress:
        some View {

        if let nextStage =
            growthStore.nextStage {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                HStack {

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(
                            "GROWING TOGETHER"
                        )
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(0.8)
                        .foregroundStyle(AppTheme.textSecondary)


                        Text(
                            "Toward \(nextStage.displayName)"
                        )
                        .font(.headline)
                    }


                    Spacer()
                }


                ProgressView(
                    value:
                        growthStore
                            .progressToNextStage
                )
                .tint(AppTheme.accent)


                Text(
                    "Keep spending meaningful time in Scripture, completing checkpoints, and reflecting. Your Companion will grow naturally alongside that pattern."
                )
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(2)
            }
            .padding(18)
            .background(
                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
                .fill(
                    AppTheme.surface
                )
            )

        } else {

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text(
                    "MATURE COMPANION"
                )
                .font(.caption2)
                .fontWeight(.bold)
                .tracking(0.8)
                .foregroundStyle(AppTheme.textSecondary)


                Text(
                    "Your Companion has reached its current mature form."
                )
                .font(.headline)


                Text(
                    "The journey still continues. Growth here is about the Companion changing alongside your long-term engagement, not reaching an endpoint in faith."
                )
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(2)
            }
            .padding(18)
            .background(
                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
                .fill(
                    AppTheme.surface
                )
            )
        }
    }


    // =====================================================
    // MARK: - Stage Timeline
    // =====================================================

    private var stageTimeline:
        some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "COMPANION JOURNEY"
            )
            .font(.caption)
            .fontWeight(.bold)
            .tracking(0.9)
            .foregroundStyle(AppTheme.textSecondary)


            ForEach(
                CompanionStage.allCases,
                id: \.rawValue
            ) { stage in

                stageRow(
                    stage
                )
            }
        }
    }


    private func stageRow(
        _ stage:
            CompanionStage
    ) -> some View {

        let isCurrent =
            stage == growthStore.stage

        let hasReached =
            stage.rawValue <=
                growthStore.stage.rawValue


        return HStack(
            spacing: 14
        ) {

            ZStack {

                Circle()
                    .fill(
                        hasReached
                        ? AppTheme.accent
                            .opacity(0.12)
                        : AppTheme.surface
                    )
                    .frame(
                        width: 54,
                        height: 54
                    )


                Image(
                    stage.assetName
                )
                .resizable()
                .scaledToFit()
                .frame(
                    width: 46,
                    height: 46
                )
                .opacity(
                    hasReached
                    ? 1
                    : 0.42
                )
            }


            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    stage.displayName
                )
                .font(.headline)


                Text(
                    stageStatusText(
                        stage
                    )
                )
                .font(.caption)
                .foregroundStyle(
                    isCurrent
                    ? AppTheme.accent
                    : AppTheme.textSecondary
                )
            }


            Spacer()


            if isCurrent {

                Text(
                    "YOU'RE HERE"
                )
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(
                    AppTheme.accent
                )

            } else if hasReached {

                Image(
                    systemName:
                        "checkmark.circle.fill"
                )
                .foregroundStyle(
                    AppTheme.accent
                )
            }
        }
        .padding(
            .vertical,
            2
        )
    }


    private func stageStatusText(
        _ stage:
            CompanionStage
    ) -> String {

        if stage == growthStore.stage {
            return "Your Companion's current form"
        }


        if stage.rawValue <
            growthStore.stage.rawValue {

            return "Reached along the way"
        }


        return "Still ahead"
    }


    // =====================================================
    // MARK: - What Helps Growth
    // =====================================================

    private var whatHelpsGrowth:
        some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "WHAT HELPS YOUR COMPANION GROW"
            )
            .font(.caption)
            .fontWeight(.bold)
            .tracking(0.9)
            .foregroundStyle(AppTheme.textSecondary)


            growthReason(
                icon: "checkmark.circle.fill",
                title: "Complete Scripture checkpoints",
                subtitle: "Move thoughtfully through the journeys you're studying."
            )


            growthReason(
                icon: "square.and.pencil",
                title: "Reflect in your own words",
                subtitle: "Save what stood out, changed, or still feels unresolved."
            )


            growthReason(
                icon: "map.fill",
                title: "Finish a journey",
                subtitle: "Follow a topic or foundation path through to its conclusion."
            )


            growthReason(
                icon: "arrow.uturn.backward.circle.fill",
                title: "Look back on what you've learned",
                subtitle: "Use journey reflections and summaries to connect the pieces."
            )
        }
    }


    private func growthReason(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Image(
                systemName:
                    icon
            )
            .font(.headline)
            .foregroundStyle(
                AppTheme.accent
            )
            .frame(
                width: 24
            )


            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    title
                )
                .font(.subheadline)
                .fontWeight(.semibold)


                Text(
                    subtitle
                )
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }


    // =====================================================
    // MARK: - Milestones
    // =====================================================

    @ViewBuilder
    private var milestoneHistory:
        some View {

        if !growthStore
            .sortedMilestones
            .isEmpty {

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                Text(
                    "GROWTH MILESTONES"
                )
                .font(.caption)
                .fontWeight(.bold)
                .tracking(0.9)
                .foregroundStyle(AppTheme.textSecondary)


                ForEach(
                    growthStore
                        .sortedMilestones
                ) { milestone in

                    HStack(
                        alignment: .top,
                        spacing: 12
                    ) {

                        CompanionStageMilestoneIcon(
                            stage:
                                milestone.stage
                        )


                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text(
                                milestoneTitle(
                                    milestone.stage
                                )
                            )
                            .font(.subheadline)
                            .fontWeight(.semibold)


                            Text(
                                milestone.reachedAt,
                                format:
                                    .dateTime
                                        .month(.abbreviated)
                                        .day()
                                        .year()
                            )
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)


                            if milestone.isBackfilled {

                                Text(
                                    "Recognized from progress you had already made before milestone history was added."
                                )
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(
                                    .top,
                                    1
                                )
                            }
                        }
                    }
                }
            }
        }
    }


    private func milestoneTitle(
        _ stage:
            CompanionStage
    ) -> String {

        switch stage {

        case .egg:
            return "Your journey together began"

        case .hatchling:
            return "Your Companion hatched"

        case .young:
            return "Your Companion became a Young Companion"

        case .mature:
            return "Your Companion reached its Mature form"
        }
    }


    // =====================================================
    // MARK: - Meaning Note
    // =====================================================

    private var meaningNote:
        some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Label(
                "What this means",
                systemImage:
                    "heart.text.square"
            )
            .font(.headline)


            Text(
                "Companion growth reflects the time you've spent engaging with the app's study and reflection tools. It is not a score for your faith, maturity, closeness to God, or spiritual worth."
            )
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
            .lineSpacing(2)
        }
        .padding(18)
        .background(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(
                AppTheme.accent
                    .opacity(0.07)
            )
        )
    }
}


private struct CompanionStageMilestoneIcon:
    View {

    let stage:
        CompanionStage


    var body: some View {

        ZStack {

            Circle()
                .fill(
                    AppTheme.accent
                        .opacity(0.10)
                )
                .frame(
                    width: 44,
                    height: 44
                )


            Image(
                stage.assetName
            )
            .resizable()
            .scaledToFit()
            .frame(
                width: 38,
                height: 38
            )
        }
    }
}


#Preview {

    NavigationStack {

        CompanionGrowthView()
    }
}
