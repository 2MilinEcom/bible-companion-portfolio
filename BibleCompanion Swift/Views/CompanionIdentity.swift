import SwiftUI

#if canImport(UIKit)
import UIKit
#endif


// =========================================================
// MARK: - Companion Identity
// =========================================================

/// The single visual source of truth for the Companion.
///
/// Growth is intentionally framed as the Companion growing alongside the
/// person, not as a spiritual rank for the person using the app.
enum CompanionStage:
    Int,
    CaseIterable,
    Codable {

    case egg = 0
    case hatchling = 1
    case young = 2
    case mature = 3


    // =====================================================
    // MARK: Growth Thresholds
    // =====================================================

    /// One complete 6-7 checkpoint journey with reflections should generally
    /// hatch the Companion, but later stages require sustained engagement.
    var minimumGrowthPoints:
        Int {

        switch self {

        case .egg:
            return 0

        case .hatchling:
            return 18

        case .young:
            return 60

        case .mature:
            return 140
        }
    }


    static func stage(
        forGrowthPoints points:
            Int
    ) -> CompanionStage {

        allCases
            .filter {
                points >=
                $0.minimumGrowthPoints
            }
            .max {
                $0.rawValue <
                $1.rawValue
            }
        ?? .egg
    }


    var nextStage:
        CompanionStage? {

        CompanionStage(
            rawValue:
                rawValue + 1
        )
    }


    // =====================================================
    // MARK: Copy
    // =====================================================

    var displayName:
        String {

        switch self {

        case .egg:
            return "Egg"

        case .hatchling:
            return "Hatchling"

        case .young:
            return "Young Companion"

        case .mature:
            return "Mature Companion"
        }
    }


    var growthDescription:
        String {

        switch self {

        case .egg:
            return "Your Companion is just beginning its journey with you."

        case .hatchling:
            return "Your Companion has started growing alongside your study and reflection."

        case .young:
            return "Your Companion is becoming a familiar presence as you keep returning to Scripture."

        case .mature:
            return "Your Companion has grown through a long pattern of studying, reflecting, and returning."
        }
    }


    // =====================================================
    // MARK: Artwork
    // =====================================================

    /// Add these assets to Assets.xcassets when the artwork is ready.
    /// Until then, missing stages safely fall back to CompanionEgg.
    private var intendedAssetName:
        String {

        switch self {

        case .egg:
            return "CompanionEgg"

        case .hatchling:
            return "CompanionHatchling"

        case .young:
            return "CompanionYoung"

        case .mature:
            return "CompanionMature"
        }
    }


    var assetName:
        String {

        #if canImport(UIKit)

        if UIImage(
            named:
                intendedAssetName
        ) != nil {

            return intendedAssetName
        }

        #endif


        return "CompanionEgg"
    }
}


// =========================================================
// MARK: - Companion Behavior
// =========================================================

enum CompanionBehavior:
    Equatable {

    case still
    case floating
    case thinking
    case celebrating
}


// =========================================================
// MARK: - Companion Avatar
// =========================================================

struct CompanionAvatar:
    View {

    let size:
        CGFloat

    var behavior:
        CompanionBehavior = .still

    var showsShadow =
        true


    /// Used by stage-specific surfaces such as the one-time growth reveal.
    /// Normal app usage leaves this nil and follows the real growth store.
    var stageOverride:
        CompanionStage? = nil


    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var settings = AppSettingsStore.shared

    @ObservedObject
    private var growthStore =
        CompanionGrowthStore.shared


    @State
    private var isAnimating =
        false


    #if DEBUG
    @AppStorage(
        "companionDebugStageOverride"
    )
    private var debugStageOverrideRaw =
        -1
    #endif


    private var stage:
        CompanionStage {

        if let stageOverride {
            return stageOverride
        }


        #if DEBUG
        if let debugStage =
            CompanionStage(
                rawValue:
                    debugStageOverrideRaw
            ) {

            return debugStage
        }
        #endif


        return growthStore.stage
    }


    var body: some View {

        ZStack {

            Image(
                stage.assetName
            )
            .resizable()
            .scaledToFit()
            .id(
                stage.rawValue
            )
            .transition(
                .scale(
                    scale: 0.92
                )
                .combined(
                    with:
                        .opacity
                )
            )
        }
        .frame(
            width:
                size,
            height:
                size
        )
        .offset(
            y:
                verticalOffset
        )
        .scaleEffect(
            scale
        )
        .rotationEffect(
            rotation
        )
        .shadow(
            color:
                showsShadow
                ? Color.black.opacity(0.10)
                : Color.clear,
            radius:
                showsShadow
                ? max(4, size * 0.055)
                : 0,
            y:
                showsShadow
                ? max(2, size * 0.03)
                : 0
        )
        .animation(
            .spring(
                response: 0.45,
                dampingFraction: 0.80
            ),
            value:
                stage
        )
        .animation(
            companionAnimation,
            value:
                isAnimating
        )
        .onAppear {

            growthStore.refresh()
            updateAnimationState()
        }
        .onChange(
            of:
                behavior
        ) { _, _ in

            updateAnimationState()
        }
        .onChange(of: reduceMotion) { _, _ in updateAnimationState() }
        .onChange(of: settings.animateCompanion) { _, _ in updateAnimationState() }
        .accessibilityLabel(
            "Bible Companion"
        )
        #if DEBUG
        .contextMenu {

            Button(
                "Use Real Growth"
            ) {

                debugStageOverrideRaw =
                    -1
            }


            Divider()


            ForEach(
                CompanionStage.allCases,
                id: \.rawValue
            ) { testStage in

                Button(
                    "Test \(testStage.displayName)"
                ) {

                    debugStageOverrideRaw =
                        testStage.rawValue
                }
            }


            Divider()


            ForEach(
                Array(
                    CompanionStage
                        .allCases
                        .dropFirst()
                ),
                id: \.rawValue
            ) { testStage in

                Button(
                    "Preview \(testStage.displayName) Growth Moment"
                ) {

                    growthStore
                        .previewStageReveal(
                            testStage
                        )
                }
            }
        }
        #endif
    }


    private var verticalOffset:
        CGFloat {

        guard !reduceMotion, settings.animateCompanion else { return 0 }
        switch behavior {

        case .still:
            return 0

        case .floating:
            return isAnimating
            ? -5
            : 5

        case .thinking:
            return isAnimating
            ? -3
            : 3

        case .celebrating:
            return isAnimating
            ? -7
            : 2
        }
    }


    private var scale:
        CGFloat {

        guard behavior == .celebrating else {
            return 1
        }

        return isAnimating
        ? 1.045
        : 0.985
    }


    private var rotation:
        Angle {

        guard behavior == .celebrating else {
            return .zero
        }

        return .degrees(
            isAnimating
            ? 2
            : -2
        )
    }


    private var companionAnimation:
        Animation? {

        guard !reduceMotion, settings.animateCompanion else { return nil }
        switch behavior {

        case .still:
            return nil

        case .floating:
            return .easeInOut(
                duration: 1.75
            )
            .repeatForever(
                autoreverses: true
            )

        case .thinking:
            return .easeInOut(
                duration: 0.75
            )
            .repeatForever(
                autoreverses: true
            )

        case .celebrating:
            return .easeInOut(
                duration: 0.62
            )
            .repeatForever(
                autoreverses: true
            )
        }
    }


    private func updateAnimationState() {

        if behavior == .still || reduceMotion || !settings.animateCompanion {

            isAnimating =
                false

        } else {

            isAnimating =
                false


            DispatchQueue.main.async {

                isAnimating =
                    true
            }
        }
    }
}


// =========================================================
// MARK: - Optional Growth Progress UI
// =========================================================

/// Ready for a future Settings/Home growth screen. It is intentionally not
/// inserted into the app automatically yet.
struct CompanionGrowthProgressView:
    View {

    @ObservedObject
    private var growthStore =
        CompanionGrowthStore.shared


    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack(
                spacing: 14
            ) {

                CompanionAvatar(
                    size: 64,
                    behavior: .floating
                )


                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(
                        growthStore
                            .stage
                            .displayName
                    )
                    .font(.headline)


                    Text(
                        growthStore
                            .stage
                            .growthDescription
                    )
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }


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
                    "Your Companion has reached its current mature stage."
                )
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(
                cornerRadius: 20
            )
            .fill(
                AppTheme.surface
            )
        )
        .onAppear {

            growthStore.refresh()
        }
    }
}


#Preview {

    VStack(
        spacing: 28
    ) {

        HStack(
            spacing: 28
        ) {

            CompanionAvatar(
                size: 64
            )

            CompanionAvatar(
                size: 84,
                behavior: .floating
            )

            CompanionAvatar(
                size: 64,
                behavior: .thinking
            )
        }


        CompanionGrowthProgressView()
    }
    .padding()
}
