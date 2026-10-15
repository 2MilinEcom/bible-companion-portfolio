import SwiftUI


// =========================================================
// MARK: - Tutorial Targets
// =========================================================

enum HomeTutorialTarget:
    Hashable {

    case home
    case foundation
    case personalized
    case scripture
    case companion


    var scrollID:
        String {

        switch self {

        case .home:
            return "tutorial-home"

        case .foundation:
            return "tutorial-foundation"

        case .personalized:
            return "tutorial-personalized"

        case .scripture:
            return "tutorial-scripture"

        case .companion:
            return "tutorial-companion"
        }
    }
}


// =========================================================
// MARK: - Tutorial Step
// =========================================================

enum HomeTutorialStep:
    Int,
    CaseIterable,
    Equatable {

    case welcome
    case foundation
    case personalized
    case scripture
    case companion
    case ready


    var target:
        HomeTutorialTarget? {

        switch self {

        case .welcome,
             .ready:
            return nil

        case .foundation:
            return .foundation

        case .personalized:
            return .personalized

        case .scripture:
            return .scripture

        case .companion:
            return .companion
        }
    }


    var previous:
        HomeTutorialStep? {

        HomeTutorialStep(
            rawValue:
                rawValue - 1
        )
    }


    var next:
        HomeTutorialStep? {

        HomeTutorialStep(
            rawValue:
                rawValue + 1
        )
    }


    var stepNumber:
        Int {

        rawValue + 1
    }


    var title:
        String {

        switch self {

        case .welcome:
            return "Welcome home"

        case .foundation:
            return "Start with Jesus"

        case .personalized:
            return "Your personal path"

        case .scripture:
            return "Read any passage"

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
            return "I'll point out the few places you'll use most."

        case .foundation:
            return "Meet Jesus is your permanent foundation journey. Come back anytime and keep moving through the Gospel."

        case .personalized:
            return "Recommended for You is shaped around what you're working through right now. Your progress stays saved."

        case .scripture:
            return "Search for any passage and begin reading or studying whenever you want."

        case .companion:
            return "Ask me questions, study a passage, or talk through what you're learning."

        case .ready:
            return "That's the core of the app. I'll be here as you explore."
        }
    }


    var primaryButtonTitle:
        String {

        switch self {

        case .welcome:
            return "Show Me Around"

        case .ready:
            return "Start Exploring"

        default:
            return "Next"
        }
    }
}


// =========================================================
// MARK: - Target Preference
// =========================================================

struct HomeTutorialTargetPreferenceKey:
    PreferenceKey {

    static var defaultValue:
        [HomeTutorialTarget: Anchor<CGRect>] =
        [:]


    static func reduce(
        value:
            inout [HomeTutorialTarget: Anchor<CGRect>],
        nextValue:
            () -> [HomeTutorialTarget: Anchor<CGRect>]
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

    func homeTutorialTarget(
        _ target:
            HomeTutorialTarget
    ) -> some View {

        self
            .id(
                target.scrollID
            )
            .anchorPreference(
                key:
                    HomeTutorialTargetPreferenceKey.self,
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
// MARK: - Tutorial Overlay
// =========================================================

struct HomeTutorialOverlay:
    View {

    let step:
        HomeTutorialStep

    let anchors:
        [HomeTutorialTarget: Anchor<CGRect>]

    let onBack:
        () -> Void

    let onNext:
        () -> Void

    let onSkip:
        () -> Void


    @State
    private var isFloating =
        false


    @State
    private var isPulsing =
        false


    var body:
        some View {

        GeometryReader { proxy in

            let targetRect =
                resolvedTargetRect(
                    in:
                        proxy
                )


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
            .contentShape(
                Rectangle()
            )
        }
        .ignoresSafeArea()
        .onAppear {

            isFloating =
                true

            isPulsing =
                true
        }
    }


    // =====================================================
    // MARK: - Spotlight
    // =====================================================

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
                    ? 0.42
                    : 0.58
                ),
            style:
                FillStyle(
                    eoFill:
                        true
                )
        )
        .allowsHitTesting(
            true
        )
    }


    // =====================================================
    // MARK: - Highlight
    // =====================================================

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
                .opacity(0.95),
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
                        ? 0.65
                        : 0.28
                    ),
            radius:
                isPulsing
                ? 10
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


    // =====================================================
    // MARK: - Companion Dialogue
    // =====================================================

    private var companionDialogue:
        some View {

        HStack(
            alignment: .bottom,
            spacing: -18
        ) {

            Image(
                "CompanionEgg"
            )
            .resizable()
            .scaledToFit()
            .frame(
                width: 96,
                height: 96
            )
            .offset(
                y:
                    isFloating
                    ? -4
                    : 4
            )
            .shadow(
                color:
                    .black
                    .opacity(0.24),
                radius: 10,
                y: 6
            )
            .animation(
                .easeInOut(
                    duration: 1.7
                )
                .repeatForever(
                    autoreverses: true
                ),
                value:
                    isFloating
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


                HStack(
                    spacing: 4
                ) {

                    ForEach(
                        HomeTutorialStep.allCases,
                        id: \.rawValue
                    ) { item in

                        Circle()
                            .fill(
                                item == step
                                ? AppTheme.accent
                                : Color.black
                                    .opacity(0.14)
                            )
                            .frame(
                                width: 6,
                                height: 6
                            )
                    }
                }
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

                if step.previous != nil {

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
                        .opacity(0.45)
                )


                Spacer()


                Button {

                    onNext()

                } label: {

                    HStack(
                        spacing: 6
                    ) {

                        Text(
                            step.primaryButtonTitle
                        )


                        Image(
                            systemName:
                                step.next == nil
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

            CompanionSpeechBubbleShape()
                .fill(
                    Color(
                        red: 0.985,
                        green: 0.972,
                        blue: 0.935
                    )
                )
                .overlay(
                    CompanionSpeechBubbleShape()
                        .stroke(
                            Color.white
                                .opacity(0.9),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color:
                        .black
                        .opacity(0.24),
                    radius: 16,
                    y: 8
                )
        )
    }


    // =====================================================
    // MARK: - Layout
    // =====================================================

    private func resolvedTargetRect(
        in proxy:
            GeometryProxy
    ) -> CGRect? {

        guard
            let target =
                step.target,
            let anchor =
                anchors[
                    target
                ]
        else {

            return nil
        }


        return proxy[
            anchor
        ]
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

private struct CompanionSpeechBubbleShape:
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
