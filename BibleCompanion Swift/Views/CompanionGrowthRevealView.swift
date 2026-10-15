//
//  CompanionGrowthRevealView.swift
//  BibleCompanion Swift
//
//  Created by Shopify on 10/3/26.
//

import SwiftUI


// =========================================================
// MARK: - Companion Growth Reveal
// =========================================================

/// A one-time celebration shown when the Companion reaches a new stage.
///
/// The language deliberately describes the Companion growing alongside the
/// user. It does not rank the user's faith, maturity, or spiritual worth.
struct CompanionGrowthRevealView:
    View {

    let stage:
        CompanionStage

    let onContinue:
        () -> Void


    @State
    private var hasAppeared =
        false


    @State
    private var sparklesExpanded =
        false


    var body: some View {

        ZStack {

            Color.black
                .opacity(0.48)
                .ignoresSafeArea()


            VStack(
                spacing: 0
            ) {

                Spacer(
                    minLength: 30
                )


                revealCard
                    .padding(
                        .horizontal,
                        22
                    )
                    .scaleEffect(
                        hasAppeared
                        ? 1
                        : 0.92
                    )
                    .opacity(
                        hasAppeared
                        ? 1
                        : 0
                    )


                Spacer(
                    minLength: 30
                )
            }
        }
        .onAppear {

            withAnimation(
                .spring(
                    response: 0.52,
                    dampingFraction: 0.78
                )
            ) {

                hasAppeared =
                    true
            }


            withAnimation(
                .easeOut(
                    duration: 0.75
                )
                .delay(0.12)
            ) {

                sparklesExpanded =
                    true
            }
        }
    }


    // =====================================================
    // MARK: - Card
    // =====================================================

    private var revealCard:
        some View {

        VStack(
            spacing: 22
        ) {

            Text(
                "YOUR COMPANION"
            )
            .font(
                .caption
            )
            .fontWeight(
                .bold
            )
            .tracking(1.2)
            .foregroundStyle(AppTheme.textSecondary)


            companionCelebration


            VStack(
                spacing: 10
            ) {

                Text(
                    revealTitle
                )
                .font(
                    .largeTitle
                )
                .fontWeight(
                    .bold
                )
                .multilineTextAlignment(
                    .center
                )


                Text(
                    revealMessage
                )
                .font(
                    .body
                )
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(
                    .center
                )
                .lineSpacing(3)
                .frame(
                    maxWidth: 330
                )
            }


            Divider()


            Text(
                "Your Companion grows as you study, reflect, and keep returning to Scripture. It isn't a measure of your faith or spiritual worth."
            )
            .font(
                .caption
            )
            .foregroundStyle(AppTheme.textSecondary)
            .multilineTextAlignment(
                .center
            )
            .lineSpacing(2)
            .frame(
                maxWidth: 330
            )


            Button {

                withAnimation(
                    .easeInOut(
                        duration: 0.22
                    )
                ) {

                    onContinue()
                }

            } label: {

                HStack(
                    spacing: 8
                ) {

                    Text(
                        "Continue Together"
                    )


                    Image(
                        systemName:
                            "arrow.right"
                    )
                    .font(
                        .caption
                    )
                }
                .fontWeight(
                    .semibold
                )
                .frame(
                    maxWidth:
                        .infinity
                )
                .padding(
                    .vertical,
                    15
                )
            }
            .buttonStyle(
                .borderedProminent
            )
        }
        .padding(
            .horizontal,
            24
        )
        .padding(
            .top,
            24
        )
        .padding(
            .bottom,
            22
        )
        .frame(
            maxWidth: 420
        )
        .background(
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
            .fill(
                AppTheme.surfaceStrong
            )
            .shadow(
                color:
                    .black
                    .opacity(0.22),
                radius: 30,
                y: 16
            )
        )
    }


    // =====================================================
    // MARK: - Companion Celebration
    // =====================================================

    private var companionCelebration:
        some View {

        ZStack {

            Circle()
                .fill(
                    AppTheme.accent
                        .opacity(0.09)
                )
                .frame(
                    width: 220,
                    height: 220
                )
                .scaleEffect(
                    sparklesExpanded
                    ? 1
                    : 0.75
                )


            decorativeSparkle(
                size: 23,
                x: -92,
                y: -66,
                delayScale: 1.0
            )


            decorativeSparkle(
                size: 15,
                x: 92,
                y: -42,
                delayScale: 0.84
            )


            decorativeSparkle(
                size: 18,
                x: 84,
                y: 66,
                delayScale: 0.92
            )


            decorativeSparkle(
                size: 13,
                x: -86,
                y: 72,
                delayScale: 0.76
            )


            CompanionAvatar(
                size: 184,
                behavior: .celebrating,
                showsShadow: true,
                stageOverride: stage
            )
        }
        .frame(
            height: 225
        )
    }


    private func decorativeSparkle(
        size:
            CGFloat,
        x:
            CGFloat,
        y:
            CGFloat,
        delayScale:
            CGFloat
    ) -> some View {

        Image(
            systemName:
                "sparkles"
        )
        .font(
            .system(
                size:
                    size,
                weight:
                    .semibold
            )
        )
        .foregroundStyle(
            AppTheme.accent
        )
        .scaleEffect(
            sparklesExpanded
            ? delayScale
            : 0.2
        )
        .opacity(
            sparklesExpanded
            ? 0.78
            : 0
        )
        .offset(
            x:
                x,
            y:
                y
        )
    }


    // =====================================================
    // MARK: - Copy
    // =====================================================

    private var revealTitle:
        String {

        switch stage {

        case .egg:
            return
                "Your journey together is beginning"

        case .hatchling:
            return
                "Your Companion hatched!"

        case .young:
            return
                "Your Companion is growing"

        case .mature:
            return
                "Look how far your Companion has come"
        }
    }


    private var revealMessage:
        String {

        switch stage {

        case .egg:
            return
                "This is the beginning of a Companion that will grow alongside you."

        case .hatchling:
            return
                "The time you've spent studying and reflecting has brought your Companion out of its shell."

        case .young:
            return
                "As you've kept returning to Scripture, your Companion has become a more familiar presence beside you."

        case .mature:
            return
                "Through a long pattern of studying, reflecting, and returning, your Companion has grown with you."
        }
    }
}


#Preview {

    CompanionGrowthRevealView(
        stage:
            .hatchling,
        onContinue: {}
    )
}
