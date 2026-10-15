import SwiftUI
import Combine


// =========================================================
// MARK: - Tutorial Coordinator
// =========================================================

@MainActor
final class AppTutorialCoordinator:
    ObservableObject {

    static let completionKey =
        "guidedAppTourV2Complete"


    @Published
    var step:
        GuidedAppTutorialStep =
        .welcome


    @Published
    var isActive:
        Bool


    init() {

        isActive =
            !UserDefaults.standard.bool(
                forKey:
                    Self.completionKey
            )
    }


    func move(
        to step:
            GuidedAppTutorialStep
    ) {

        guard isActive else {
            return
        }

        withAnimation(
            .spring(
                response: 0.42,
                dampingFraction: 0.84
            )
        ) {

            self.step =
                step
        }
    }


    func finish() {

        UserDefaults.standard.set(
            true,
            forKey:
                Self.completionKey
        )


        withAnimation(
            .easeInOut(
                duration: 0.30
            )
        ) {

            isActive =
                false
        }
    }


    func reset() {

        UserDefaults.standard.set(
            false,
            forKey:
                Self.completionKey
        )

        step =
            .welcome

        isActive =
            true
    }
}


// =========================================================
// MARK: - Tutorial Steps
// =========================================================

enum GuidedAppTutorialStep:
    Int,
    CaseIterable,
    Equatable {

    case welcome
    case foundation
    case personalized
    case beginPath
    case checkpointOverview
    case checkpointBegin
    case changePath
    case changeMethods
    case pastPaths
    case scripture
    case companion
    case ready


    var sectionLabel:
        String {

        switch self {

        case .welcome,
             .foundation,
             .personalized,
             .beginPath,
             .changePath,
             .scripture,
             .companion,
             .ready:

            return "HOME"


        case .checkpointOverview,
             .checkpointBegin:

            return "YOUR PATH"


        case .changeMethods,
             .pastPaths:

            return "CHANGE PATH"
        }
    }


    var title:
        String {

        switch self {

        case .welcome:
            return "Welcome home"

        case .foundation:
            return "Meet Jesus"

        case .personalized:
            return "Your personal path"

        case .beginPath:
            return "Start with your next checkpoint"

        case .checkpointOverview:
            return "One checkpoint at a time"

        case .checkpointBegin:
            return "Begin with Scripture"

        case .changePath:
            return "You can change direction"

        case .changeMethods:
            return "Choose the way that fits you"

        case .pastPaths:
            return "Nothing gets erased"

        case .scripture:
            return "Read Scripture directly"

        case .companion:
            return "Come talk with me"

        case .ready:
            return "You're ready"
        }
    }


    var message:
        String {

        switch self {

        case .welcome:
            return "I'll show you the important parts of the app, then we'll open a real path together."

        case .foundation:
            return "Meet Jesus is your permanent foundation journey. You can keep returning to it as you grow through Scripture."

        case .personalized:
            return "Recommended for You is the path built around what you're working through right now. Your progress stays saved."

        case .beginPath:
            return "Begin Path opens your next checkpoint. I'll take you inside so you can see how a checkpoint works before you start using it on your own."

        case .checkpointOverview:
            return "Every checkpoint moves through Intro, Read, Discuss, and Reflect. The bar at the top shows where you are, and your place is saved as you go."

        case .checkpointBegin:
            return "Begin Reading moves you into the passage. From there you can discuss what you noticed with me, reflect in your own words, and complete the checkpoint when you're ready. This tour won't mark anything complete for you."

        case .changePath:
            return "Your current path isn't permanent. Change Path lets you choose a new focus without deleting the work you've already done."

        case .changeMethods:
            return "Use Guided Questionnaire when you already know the topic. Use Talk It Through when you want me to help you figure out what your next focus should be."

        case .pastPaths:
            return "When you change focus, your earlier paths stay here with their progress saved. You can review or resume them later."

        case .scripture:
            return "You never have to start with a journey. Search for any passage and read or study it directly."

        case .companion:
            return "Ask me questions about Scripture, study a passage with me, or talk through something you're wrestling with."

        case .ready:
            return "That's the core of Bible Companion. Start wherever you need today, and I'll stay with you as you go."
        }
    }


    var primaryButtonTitle:
        String {

        switch self {

        case .welcome:
            return "Show Me Around"

        case .beginPath:
            return "Open Path"

        case .checkpointOverview:
            return "Show Me the Start"

        case .checkpointBegin:
            return "Back Home"

        case .changePath:
            return "Open Change Path"

        case .changeMethods:
            return "Show Past Paths"

        case .pastPaths:
            return "Back Home"

        case .ready:
            return "Start Exploring"

        default:
            return "Next"
        }
    }
}


// =========================================================
// MARK: - Home Targets
// =========================================================

enum AppTutorialHomeTarget:
    Hashable {

    case home
    case foundation
    case personalized
    case beginPath
    case changePath
    case scripture
    case companion


    var scrollID:
        String {

        switch self {

        case .home:
            return "guided-tour-home"

        case .foundation:
            return "guided-tour-foundation"

        case .personalized:
            return "guided-tour-personalized"

        case .beginPath:
            return "guided-tour-begin-path"

        case .changePath:
            return "guided-tour-change-path"

        case .scripture:
            return "guided-tour-scripture"

        case .companion:
            return "guided-tour-companion"
        }
    }
}


struct AppTutorialHomeTargetPreferenceKey:
    PreferenceKey {

    static var defaultValue:
        [AppTutorialHomeTarget: Anchor<CGRect>] =
        [:]


    static func reduce(
        value:
            inout [AppTutorialHomeTarget: Anchor<CGRect>],
        nextValue:
            () -> [AppTutorialHomeTarget: Anchor<CGRect>]
    ) {

        value.merge(
            nextValue(),
            uniquingKeysWith: {
                _, new in
                new
            }
        )
    }
}


extension View {

    func appTutorialHomeTarget(
        _ target:
            AppTutorialHomeTarget
    ) -> some View {

        self
            .id(
                target.scrollID
            )
            .anchorPreference(
                key:
                    AppTutorialHomeTargetPreferenceKey.self,
                value:
                    .bounds
            ) { anchor in

                [
                    target:
                        anchor
                ]
            }
    }
}


// =========================================================
// MARK: - Checkpoint Targets
// =========================================================

enum AppTutorialCheckpointTarget:
    Hashable {

    case progress
    case beginReading
}


struct AppTutorialCheckpointTargetPreferenceKey:
    PreferenceKey {

    static var defaultValue:
        [AppTutorialCheckpointTarget: Anchor<CGRect>] =
        [:]


    static func reduce(
        value:
            inout [AppTutorialCheckpointTarget: Anchor<CGRect>],
        nextValue:
            () -> [AppTutorialCheckpointTarget: Anchor<CGRect>]
    ) {

        value.merge(
            nextValue(),
            uniquingKeysWith: {
                _, new in
                new
            }
        )
    }
}


extension View {

    func appTutorialCheckpointTarget(
        _ target:
            AppTutorialCheckpointTarget
    ) -> some View {

        anchorPreference(
            key:
                AppTutorialCheckpointTargetPreferenceKey.self,
            value:
                .bounds
        ) { anchor in

            [
                target:
                    anchor
            ]
        }
    }
}


// =========================================================
// MARK: - Change Path Targets
// =========================================================

enum AppTutorialChangePathTarget:
    Hashable {

    case methods
    case pastPaths


    var scrollID:
        String {

        switch self {

        case .methods:
            return "guided-tour-change-methods"

        case .pastPaths:
            return "guided-tour-past-paths"
        }
    }
}


struct AppTutorialChangePathTargetPreferenceKey:
    PreferenceKey {

    static var defaultValue:
        [AppTutorialChangePathTarget: Anchor<CGRect>] =
        [:]


    static func reduce(
        value:
            inout [AppTutorialChangePathTarget: Anchor<CGRect>],
        nextValue:
            () -> [AppTutorialChangePathTarget: Anchor<CGRect>]
    ) {

        value.merge(
            nextValue(),
            uniquingKeysWith: {
                _, new in
                new
            }
        )
    }
}


extension View {

    func appTutorialChangePathTarget(
        _ target:
            AppTutorialChangePathTarget
    ) -> some View {

        self
            .id(
                target.scrollID
            )
            .anchorPreference(
                key:
                    AppTutorialChangePathTargetPreferenceKey.self,
                value:
                    .bounds
            ) { anchor in

                [
                    target:
                        anchor
                ]
            }
    }
}


// =========================================================
// MARK: - Shared Coach Mark Overlay
// =========================================================

struct AppCoachMarkOverlay:
    View {

    let step:
        GuidedAppTutorialStep

    let targetAnchor:
        Anchor<CGRect>?

    let onBack:
        (() -> Void)?

    let onPrimary:
        () -> Void

    let onSkip:
        () -> Void




    @State
    private var isPulsing =
        false


    var body:
        some View {

        GeometryReader { proxy in

            let targetRect =
                targetAnchor.map {
                    proxy[$0]
                }


            ZStack {

                spotlightLayer(
                    proxy:
                        proxy,
                    targetRect:
                        targetRect
                )


                if let targetRect {

                    highlightBorder(
                        targetRect
                    )
                }


                VStack {

                    Spacer()


                    companionDialogue
                        .padding(
                            .horizontal,
                            14
                        )
                        .padding(
                            .bottom,
                            max(
                                proxy.safeAreaInsets.bottom,
                                14
                            )
                        )
                }
            }
            .frame(
                maxWidth:
                    .infinity,
                maxHeight:
                    .infinity
            )
        }
        // Keep the dialogue inside the tab content safe area so navigation cannot cover its controls.
        .onAppear {

            isPulsing =
                true
        }
    }


    private func spotlightLayer(
        proxy:
            GeometryProxy,
        targetRect:
            CGRect?
    ) -> some View {

        let fullRect =
            CGRect(
                origin:
                    .zero,
                size:
                    proxy.size
            )


        return Path { path in

            path.addRect(
                fullRect
            )


            if let targetRect {

                path.addRoundedRect(
                    in:
                        expanded(
                            targetRect,
                            horizontal: 10,
                            vertical: 8
                        ),
                    cornerSize:
                        CGSize(
                            width: 20,
                            height: 20
                        )
                )
            }
        }
        .fill(
            Color.black
                .opacity(
                    targetRect == nil
                    ? 0.40
                    : 0.56
                ),
            style:
                FillStyle(
                    eoFill:
                        true
                )
        )
    }


    private func highlightBorder(
        _ targetRect:
            CGRect
    ) -> some View {

        let rect =
            expanded(
                targetRect,
                horizontal: 10,
                vertical: 8
            )


        return RoundedRectangle(
            cornerRadius: 20
        )
        .strokeBorder(
            AppTheme.accent
                .opacity(0.96),
            lineWidth: 2
        )
        .frame(
            width:
                rect.width,
            height:
                rect.height
        )
        .position(
            x:
                rect.midX,
            y:
                rect.midY
        )
        .shadow(
            color:
                AppTheme.accent
                .opacity(
                    isPulsing
                    ? 0.62
                    : 0.24
                ),
            radius:
                isPulsing
                ? 11
                : 4
        )
        .animation(
            .easeInOut(
                duration: 1.05
            )
            .repeatForever(
                autoreverses: true
            ),
            value:
                isPulsing
        )
        .allowsHitTesting(
            false
        )
    }


    private var companionDialogue:
        some View {

        HStack(
            alignment: .bottom,
            spacing: -18
        ) {

            CompanionAvatar(
                size: 92,
                behavior: .floating
            )
            .zIndex(2)


            tutorialBubble
                .zIndex(1)
        }
        .frame(
            maxWidth: 390,
            alignment: .center
        )
        .transition(
            .move(
                edge: .bottom
            )
            .combined(
                with: .opacity
            )
        )
        .animation(
            .spring(
                response: 0.42,
                dampingFraction: 0.84
            ),
            value:
                step
        )
    }


    private var tutorialBubble:
        some View {

        VStack(
            alignment: .leading,
            spacing: 9
        ) {

            HStack(
                alignment:
                    .firstTextBaseline,
                spacing: 8
            ) {

                Text(
                    step.title
                )
                .font(
                    .system(
                        size: 18,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    Color.black
                )


                Spacer(
                    minLength: 8
                )


                Text(
                    step.sectionLabel
                )
                .font(
                    .system(
                        size: 10,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .tracking(0.7)
                .foregroundStyle(
                    Color.black
                        .opacity(0.38)
                )
            }


            Text(
                step.message
            )
            .font(
                .system(
                    size: 15,
                    weight: .regular,
                    design: .rounded
                )
            )
            .foregroundStyle(
                Color.black
                    .opacity(0.72)
            )
            .lineSpacing(2)
            .fixedSize(
                horizontal: false,
                vertical: true
            )


            HStack(
                spacing: 10
            ) {

                if let onBack {

                    Button(
                        "Back"
                    ) {

                        onBack()
                    }
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        Color.black
                            .opacity(0.62)
                    )
                }


                Button(
                    "Skip"
                ) {

                    onSkip()
                }
                .font(
                    .system(
                        size: 14,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    Color.black
                        .opacity(0.42)
                )


                Spacer()


                Button {

                    onPrimary()

                } label: {

                    HStack(
                        spacing: 6
                    ) {

                        Text(
                            step.primaryButtonTitle
                        )


                        Image(
                            systemName:
                                step == .ready
                                ? "checkmark"
                                : "arrow.right"
                        )
                        .font(
                            .caption
                        )
                    }
                    .font(
                        .system(
                            size: 14,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        Color.white
                    )
                    .padding(
                        .horizontal,
                        14
                    )
                    .padding(
                        .vertical,
                        9
                    )
                    .background(
                        Capsule()
                            .fill(
                                AppTheme.accent
                            )
                    )
                }
                .buttonStyle(
                    .plain
                )
            }
        }
        .padding(
            .leading,
            28
        )
        .padding(
            .trailing,
            16
        )
        .padding(
            .vertical,
            15
        )
        .frame(
            maxWidth: 292,
            alignment: .leading
        )
        .background(
            AppCompanionSpeechBubbleShape()
                .fill(
                    Color(
                        red: 0.985,
                        green: 0.972,
                        blue: 0.935
                    )
                )
                .overlay(
                    AppCompanionSpeechBubbleShape()
                        .stroke(
                            Color.white
                                .opacity(0.9),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color:
                        .black
                        .opacity(0.22),
                    radius: 16,
                    y: 8
                )
        )
    }


    private func expanded(
        _ rect:
            CGRect,
        horizontal:
            CGFloat,
        vertical:
            CGFloat
    ) -> CGRect {

        rect.insetBy(
            dx:
                -horizontal,
            dy:
                -vertical
        )
    }
}


// =========================================================
// MARK: - Speech Bubble Shape
// =========================================================

private struct AppCompanionSpeechBubbleShape:
    Shape {

    func path(
        in rect:
            CGRect
    ) -> Path {

        var path =
            Path()


        let tailWidth:
            CGFloat = 18

        let bodyRect =
            CGRect(
                x:
                    tailWidth,
                y:
                    0,
                width:
                    rect.width - tailWidth,
                height:
                    rect.height
            )


        path.addRoundedRect(
            in:
                bodyRect,
            cornerSize:
                CGSize(
                    width: 22,
                    height: 22
                )
        )


        let tailY =
            rect.height * 0.62


        path.move(
            to:
                CGPoint(
                    x: tailWidth,
                    y: tailY - 12
                )
        )

        path.addQuadCurve(
            to:
                CGPoint(
                    x: 0,
                    y: tailY
                ),
            control:
                CGPoint(
                    x: 8,
                    y: tailY - 8
                )
        )

        path.addQuadCurve(
            to:
                CGPoint(
                    x: tailWidth,
                    y: tailY + 14
                ),
            control:
                CGPoint(
                    x: 8,
                    y: tailY + 8
                )
        )

        path.closeSubpath()


        return path
    }
}

