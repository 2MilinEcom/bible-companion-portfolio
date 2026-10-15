import Foundation


enum JourneyLibrary {

    // =====================================================
    // MARK: - Foundation Journey
    // =====================================================

    static let meetJesus = JourneyPath(

        id: "meet_jesus",

        title: "Meet Jesus",

        subtitle:
            "A guided journey through the Gospel of John",

        category: .foundation,

        checkpoints: [

            JourneyCheckpoint(
                id: "meet_jesus_1",
                order: 1,
                title: "Who Is Jesus?",
                subtitle:
                    "Begin with how John introduces Jesus and the claims he makes about Him.",
                passage: "John 1:1-18",
                focusQuestion:
                    "What does John want you to understand about who Jesus is?"
            ),

            JourneyCheckpoint(
                id: "meet_jesus_2",
                order: 2,
                title: "New Life",
                subtitle:
                    "Jesus speaks with Nicodemus about being born again and entering God's kingdom.",
                passage: "John 3:1-21",
                focusQuestion:
                    "What does Jesus mean when He tells Nicodemus that he must be born again?"
            ),

            JourneyCheckpoint(
                id: "meet_jesus_3",
                order: 3,
                title: "Jesus and the Outsider",
                subtitle:
                    "Watch how Jesus speaks with someone others would normally avoid.",
                passage: "John 4:1-30",
                focusQuestion:
                    "How does the woman's understanding of Jesus change during their conversation?"
            ),

            JourneyCheckpoint(
                id: "meet_jesus_4",
                order: 4,
                title: "What Jesus Offers",
                subtitle:
                    "Jesus describes Himself as the bread that gives lasting life.",
                passage: "John 6:25-40",
                focusQuestion:
                    "What does Jesus say people are truly searching for?"
            ),

            JourneyCheckpoint(
                id: "meet_jesus_5",
                order: 5,
                title: "Light in the Darkness",
                subtitle:
                    "Jesus makes another striking claim about who He is.",
                passage: "John 8:12-30",
                focusQuestion:
                    "What does Jesus mean when He calls Himself the light of the world?"
            ),

            JourneyCheckpoint(
                id: "meet_jesus_6",
                order: 6,
                title: "The Good Shepherd",
                subtitle:
                    "Jesus describes His relationship with those who follow Him.",
                passage: "John 10:1-18",
                focusQuestion:
                    "What does the shepherd imagery reveal about Jesus?"
            ),

            JourneyCheckpoint(
                id: "meet_jesus_7",
                order: 7,
                title: "Resurrection and Life",
                subtitle:
                    "Jesus meets grief and makes one of His strongest claims about life and death.",
                passage: "John 11:17-44",
                focusQuestion:
                    "What does Jesus claim about Himself before raising Lazarus?"
            ),

            JourneyCheckpoint(
                id: "meet_jesus_8",
                order: 8,
                title: "The Servant King",
                subtitle:
                    "Jesus washes His disciples' feet and redefines greatness.",
                passage: "John 13:1-17",
                focusQuestion:
                    "What does Jesus' behavior teach about leadership and service?"
            ),

            JourneyCheckpoint(
                id: "meet_jesus_9",
                order: 9,
                title: "The Way to the Father",
                subtitle:
                    "Jesus prepares His disciples for what is coming.",
                passage: "John 14:1-14",
                focusQuestion:
                    "What claims does Jesus make about His relationship with the Father?"
            ),

            JourneyCheckpoint(
                id: "meet_jesus_10",
                order: 10,
                title: "The Cross",
                subtitle:
                    "Read John's account of Jesus' crucifixion.",
                passage: "John 19:16-30",
                focusQuestion:
                    "What does John emphasize about Jesus in His final moments?"
            ),

            JourneyCheckpoint(
                id: "meet_jesus_11",
                order: 11,
                title: "The Resurrection",
                subtitle:
                    "Finish the journey with John's account of the risen Jesus.",
                passage: "John 20:1-31",
                focusQuestion:
                    "Why does John say he recorded these events?"
            )
        ]
    )


    // =====================================================
    // MARK: - Personalized Path Builder
    // =====================================================

    /// Returns a curated personalized journey when we have
    /// a strong biblical curriculum for the user's category.
    ///
    /// If this returns nil, the app can use the AI
    /// custom-path builder instead.
    static func personalizedPath(
        for focus: JourneyFocus
    ) -> JourneyPath? {

        let category =
            focus.category
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .lowercased()


        switch category {

        // MARK: Anger

        case "anger",
             "frustration":

            return angerPath(
                focus: focus
            )


        // MARK: Doubt

        case "doubt",
             "doubts",
             "faith and doubt",
             "questions about faith":

            return doubtPath(
                focus: focus
            )


        // MARK: Forgiveness

        case "forgiveness",
             "bitterness",
             "resentment":

            return forgivenessPath(
                focus: focus
            )


        // MARK: Temptation

        case "temptation",
             "temptations":

            return temptationPath(
                focus: focus
            )


        // MARK: Relationships

        case "relationships",
             "relationship",
             "conflict":

            return relationshipsPath(
                focus: focus
            )


        // MARK: Prayer

        case "prayer",
             "prayer and consistency",
             "prayer & consistency",
             "spiritual consistency":

            return prayerPath(
                focus: focus
            )


        // MARK: Grief

        case "grief",
             "grief or loss",
             "loss":

            return griefPath(
                focus: focus
            )


        // MARK: Fear / Worry

        case "fear",
             "worry",
             "fear / worry",
             "fear and worry",
             "anxiety":

            return fearPath(
                focus: focus
            )


        // MARK: Loneliness

        case "loneliness",
             "lonely",
             "isolation":

            return lonelinessPath(
                focus: focus
            )


        // MARK: Purpose

        case "purpose",
             "direction",
             "calling":

            return purposePath(
                focus: focus
            )


        // MARK: Habits / Self-Control

        case "habits",
             "self-control",
             "self control",
             "habits / self-control",
             "discipline":

            return selfControlPath(
                focus: focus
            )


        // MARK: Custom / Other

        default:

            return nil
        }
    }


    // =====================================================
    // MARK: - Custom AI Path
    // =====================================================

    /// Used later by:
    ///
    /// Change Path
    ///     → Questionnaire
    ///     → Something Else
    ///
    /// or:
    ///
    /// Change Path
    ///     → Talk It Through
    ///     → AI proposes a custom curriculum
    ///
    /// The generated checkpoints are saved exactly like
    /// curated paths.
    static func customPersonalizedPath(
        title: String,
        subtitle: String,
        focus: JourneyFocus,
        checkpoints: [JourneyCheckpoint]
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "custom"
                ),

            title:
                title,

            subtitle:
                subtitle,

            category:
                .personalized,

            checkpoints:
                checkpoints,

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Anger
    // =====================================================

    private static func angerPath(
        focus: JourneyFocus
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "anger"
                ),

            title:
                "Understanding Your Anger",

            subtitle:
                "Explore what Scripture shows about anger, its causes, its consequences, and how to respond wisely.",

            category:
                .personalized,

            checkpoints: [

                JourneyCheckpoint(
                    id: "anger_1",
                    order: 1,
                    title:
                        "When Anger Starts to Rule",
                    subtitle:
                        "Cain's story shows how anger can grow when it is left unchecked.",
                    passage:
                        "Genesis 4:3-8",
                    focusQuestion:
                        "What warning signs appear before Cain acts on his anger?"
                ),

                JourneyCheckpoint(
                    id: "anger_2",
                    order: 2,
                    title:
                        "When Frustration Becomes a Wrong Response",
                    subtitle:
                        "Moses had reasons to be frustrated, but his response still mattered.",
                    passage:
                        "Numbers 20:7-12",
                    focusQuestion:
                        "What is the difference between Moses' frustration and the way he chose to express it?"
                ),

                JourneyCheckpoint(
                    id: "anger_3",
                    order: 3,
                    title:
                        "When You Feel Justified",
                    subtitle:
                        "Jonah believed his anger made sense. God challenged him to examine it.",
                    passage:
                        "Jonah 4:1-11",
                    focusQuestion:
                        "Why does Jonah believe his anger is justified, and what does God ask him to reconsider?"
                ),

                JourneyCheckpoint(
                    id: "anger_4",
                    order: 4,
                    title:
                        "Is Anger Always Sinful?",
                    subtitle:
                        "Jesus becomes angry in response to hardness of heart and suffering.",
                    passage:
                        "Mark 3:1-6",
                    focusQuestion:
                        "What is Jesus angry about, and how is His anger expressed?"
                ),

                JourneyCheckpoint(
                    id: "anger_5",
                    order: 5,
                    title:
                        "What Human Anger Produces",
                    subtitle:
                        "James connects anger with listening, speech, and the kind of life God desires.",
                    passage:
                        "James 1:19-20",
                    focusQuestion:
                        "Why does James connect being slow to anger with being quick to listen?"
                ),

                JourneyCheckpoint(
                    id: "anger_6",
                    order: 6,
                    title:
                        "Be Angry and Do Not Sin",
                    subtitle:
                        "Paul does not pretend anger never happens. He focuses on what we do with it.",
                    passage:
                        "Ephesians 4:25-32",
                    focusQuestion:
                        "What practical instructions does Paul give for handling anger without letting it become destructive?"
                ),

                JourneyCheckpoint(
                    id: "anger_7",
                    order: 7,
                    title:
                        "Recognizing Your Pattern",
                    subtitle:
                        "Bring the journey together by examining how words and responses can either escalate or calm conflict.",
                    passage:
                        "Proverbs 15:1-4",
                    focusQuestion:
                        "Looking back over this path, what pattern in your own anger do you most want to respond to differently?"
                )
            ],

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Doubt
    // =====================================================

    private static func doubtPath(
        focus: JourneyFocus
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "doubt"
                ),

            title:
                "Working Through Doubt",

            subtitle:
                "Explore how Scripture portrays questions, uncertainty, evidence, and faith.",

            category:
                .personalized,

            checkpoints: [

                JourneyCheckpoint(
                    id: "doubt_1",
                    order: 1,
                    title:
                        "When Doubt Asks for Evidence",
                    subtitle:
                        "Thomas wants evidence before he is willing to believe the resurrection.",
                    passage:
                        "John 20:24-29",
                    focusQuestion:
                        "How does Jesus respond to Thomas' request for evidence?"
                ),

                JourneyCheckpoint(
                    id: "doubt_2",
                    order: 2,
                    title:
                        "Faith Mixed With Doubt",
                    subtitle:
                        "A father comes to Jesus with both belief and uncertainty at the same time.",
                    passage:
                        "Mark 9:14-29",
                    focusQuestion:
                        "What does the father's statement reveal about the relationship between faith and doubt?"
                ),

                JourneyCheckpoint(
                    id: "doubt_3",
                    order: 3,
                    title:
                        "When God Seems Silent",
                    subtitle:
                        "Habakkuk openly questions God about what he sees happening around him.",
                    passage:
                        "Habakkuk 1:1-11",
                    focusQuestion:
                        "What questions does Habakkuk bring to God instead of hiding them?"
                ),

                JourneyCheckpoint(
                    id: "doubt_4",
                    order: 4,
                    title:
                        "When What You See Shakes You",
                    subtitle:
                        "The writer of Psalm 73 describes a crisis caused by what seemed unfair.",
                    passage:
                        "Psalm 73:1-17",
                    focusQuestion:
                        "What changes the writer's perspective after his faith begins to slip?"
                ),

                JourneyCheckpoint(
                    id: "doubt_5",
                    order: 5,
                    title:
                        "Why John Gives Evidence",
                    subtitle:
                        "John explains why he recorded the signs and testimony surrounding Jesus.",
                    passage:
                        "John 20:30-31",
                    focusQuestion:
                        "What does John say the evidence in his Gospel is intended to help the reader consider?"
                ),

                JourneyCheckpoint(
                    id: "doubt_6",
                    order: 6,
                    title:
                        "What Has Changed?",
                    subtitle:
                        "Finish by reflecting on which questions became clearer and which questions remain.",
                    passage:
                        "Psalm 42:5-11",
                    focusQuestion:
                        "After working through this path, which doubts have changed and which ones still deserve deeper study?"
                )
            ],

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Forgiveness
    // =====================================================

    private static func forgivenessPath(
        focus: JourneyFocus
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "forgiveness"
                ),

            title:
                "Learning Forgiveness",

            subtitle:
                "Explore forgiveness, justice, reconciliation, and what Scripture asks of us after we have been hurt.",

            category:
                .personalized,

            checkpoints: [

                JourneyCheckpoint(
                    id: "forgiveness_1",
                    order: 1,
                    title:
                        "When the Hurt Is Real",
                    subtitle:
                        "Joseph faces the brothers who betrayed him and changed the course of his life.",
                    passage:
                        "Genesis 50:15-21",
                    focusQuestion:
                        "How does Joseph acknowledge the wrong that was done without allowing it to define his response?"
                ),

                JourneyCheckpoint(
                    id: "forgiveness_2",
                    order: 2,
                    title:
                        "Refusing Revenge",
                    subtitle:
                        "David has an opportunity to harm Saul but chooses not to take revenge.",
                    passage:
                        "1 Samuel 24:1-22",
                    focusQuestion:
                        "What does David's response show about the difference between refusing revenge and pretending no wrong occurred?"
                ),

                JourneyCheckpoint(
                    id: "forgiveness_3",
                    order: 3,
                    title:
                        "How Often Must I Forgive?",
                    subtitle:
                        "Peter asks Jesus for a limit on forgiveness.",
                    passage:
                        "Matthew 18:21-35",
                    focusQuestion:
                        "What does Jesus want Peter to understand about forgiveness?"
                ),

                JourneyCheckpoint(
                    id: "forgiveness_4",
                    order: 4,
                    title:
                        "Forgiveness and Confrontation",
                    subtitle:
                        "Jesus also gives instructions for addressing wrongdoing directly.",
                    passage:
                        "Matthew 18:15-17",
                    focusQuestion:
                        "How does this passage challenge the idea that forgiveness always means ignoring what happened?"
                ),

                JourneyCheckpoint(
                    id: "forgiveness_5",
                    order: 5,
                    title:
                        "Overcoming Evil Without Becoming It",
                    subtitle:
                        "Paul describes how Christians can respond to wrongdoing without revenge.",
                    passage:
                        "Romans 12:17-21",
                    focusQuestion:
                        "What alternatives to revenge does Paul give?"
                ),

                JourneyCheckpoint(
                    id: "forgiveness_6",
                    order: 6,
                    title:
                        "What Are You Ready to Release?",
                    subtitle:
                        "Paul connects forgiveness with compassion, patience, and love.",
                    passage:
                        "Colossians 3:12-15",
                    focusQuestion:
                        "What would forgiveness look like in your situation without pretending the hurt did not matter?"
                )
            ],

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Temptation
    // =====================================================

    private static func temptationPath(
        focus: JourneyFocus
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "temptation"
                ),

            title:
                "Breaking the Cycle of Temptation",

            subtitle:
                "Recognize patterns, understand desire, and practice biblical responses to temptation.",

            category:
                .personalized,

            checkpoints: [

                JourneyCheckpoint(
                    id: "temptation_1",
                    order: 1,
                    title:
                        "Know When to Run",
                    subtitle:
                        "Joseph recognizes a situation he should not remain in.",
                    passage:
                        "Genesis 39:6-12",
                    focusQuestion:
                        "What does Joseph do before temptation has time to become action?"
                ),

                JourneyCheckpoint(
                    id: "temptation_2",
                    order: 2,
                    title:
                        "How Jesus Responded",
                    subtitle:
                        "Jesus faces temptation directly in the wilderness.",
                    passage:
                        "Matthew 4:1-11",
                    focusQuestion:
                        "What patterns do you notice in the way Jesus answers temptation?"
                ),

                JourneyCheckpoint(
                    id: "temptation_3",
                    order: 3,
                    title:
                        "Where Temptation Grows",
                    subtitle:
                        "James traces temptation from desire toward action and consequence.",
                    passage:
                        "James 1:12-18",
                    focusQuestion:
                        "Where in James' sequence do you usually recognize your own struggle beginning?"
                ),

                JourneyCheckpoint(
                    id: "temptation_4",
                    order: 4,
                    title:
                        "Look for the Way Out",
                    subtitle:
                        "Paul teaches that temptation does not remove every possibility of obedience.",
                    passage:
                        "1 Corinthians 10:12-13",
                    focusQuestion:
                        "What might a practical 'way of escape' look like before your temptation becomes strongest?"
                ),

                JourneyCheckpoint(
                    id: "temptation_5",
                    order: 5,
                    title:
                        "Stop Feeding the Pattern",
                    subtitle:
                        "Paul tells believers not to make provision for desires they are trying to resist.",
                    passage:
                        "Romans 13:11-14",
                    focusQuestion:
                        "What are you currently giving easy access to that makes this struggle harder?"
                ),

                JourneyCheckpoint(
                    id: "temptation_6",
                    order: 6,
                    title:
                        "Build a Different Direction",
                    subtitle:
                        "Growth is not only avoiding wrong behavior but learning to walk differently.",
                    passage:
                        "Galatians 5:16-25",
                    focusQuestion:
                        "Which fruit of the Spirit most directly opposes the pattern you are trying to change?"
                )
            ],

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Relationships
    // =====================================================

    private static func relationshipsPath(
        focus: JourneyFocus
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "relationships"
                ),

            title:
                "Growing in Relationships",

            subtitle:
                "Work through communication, conflict, love, humility, and healthy responses with others.",

            category:
                .personalized,

            checkpoints: [

                JourneyCheckpoint(
                    id: "relationships_1",
                    order: 1,
                    title:
                        "Listen Before Reacting",
                    subtitle:
                        "James connects listening, speaking, and anger.",
                    passage:
                        "James 1:19-20",
                    focusQuestion:
                        "Which part is hardest for you: listening, slowing down your words, or slowing down your anger?"
                ),

                JourneyCheckpoint(
                    id: "relationships_2",
                    order: 2,
                    title:
                        "Words That Build or Tear Down",
                    subtitle:
                        "Paul gives practical instruction about speech and conflict.",
                    passage:
                        "Ephesians 4:25-32",
                    focusQuestion:
                        "Which communication habit in this passage would most change your relationships?"
                ),

                JourneyCheckpoint(
                    id: "relationships_3",
                    order: 3,
                    title:
                        "Address Conflict Directly",
                    subtitle:
                        "Jesus gives a pattern for dealing with conflict instead of letting it grow indirectly.",
                    passage:
                        "Matthew 18:15-17",
                    focusQuestion:
                        "What does Jesus' approach teach about addressing conflict clearly and personally?"
                ),

                JourneyCheckpoint(
                    id: "relationships_4",
                    order: 4,
                    title:
                        "What Love Actually Looks Like",
                    subtitle:
                        "Paul describes love through concrete behaviors rather than feelings alone.",
                    passage:
                        "1 Corinthians 13:4-7",
                    focusQuestion:
                        "Which description of love challenges your current behavior the most?"
                ),

                JourneyCheckpoint(
                    id: "relationships_5",
                    order: 5,
                    title:
                        "Humility in Conflict",
                    subtitle:
                        "Paul points to humility and concern for others as central to Christian relationships.",
                    passage:
                        "Philippians 2:1-5",
                    focusQuestion:
                        "What would humility look like without ignoring your own legitimate needs?"
                ),

                JourneyCheckpoint(
                    id: "relationships_6",
                    order: 6,
                    title:
                        "Your Relationship Pattern",
                    subtitle:
                        "Bring the lessons together and identify what you want to practice differently.",
                    passage:
                        "Proverbs 15:1-4",
                    focusQuestion:
                        "What recurring pattern do you want to interrupt in your relationships?"
                )
            ],

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Prayer
    // =====================================================

    private static func prayerPath(
        focus: JourneyFocus
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "prayer"
                ),

            title:
                "Building a Life of Prayer",

            subtitle:
                "Learn how Jesus and Scripture teach us to pray with honesty, persistence, and trust.",

            category:
                .personalized,

            checkpoints: [

                JourneyCheckpoint(
                    id: "prayer_1",
                    order: 1,
                    title:
                        "Teach Us to Pray",
                    subtitle:
                        "Jesus' disciples ask Him directly how they should pray.",
                    passage:
                        "Luke 11:1-13",
                    focusQuestion:
                        "What priorities does Jesus place at the center of prayer?"
                ),

                JourneyCheckpoint(
                    id: "prayer_2",
                    order: 2,
                    title:
                        "Prayer Without Performance",
                    subtitle:
                        "Jesus contrasts sincere prayer with prayer meant to impress others.",
                    passage:
                        "Matthew 6:5-13",
                    focusQuestion:
                        "What does Jesus teach about the purpose and posture of prayer?"
                ),

                JourneyCheckpoint(
                    id: "prayer_3",
                    order: 3,
                    title:
                        "Praying When You Feel Nothing",
                    subtitle:
                        "The Psalms show that prayer can include confusion, grief, and frustration.",
                    passage:
                        "Psalm 13:1-6",
                    focusQuestion:
                        "How does the writer speak honestly to God while still turning toward trust?"
                ),

                JourneyCheckpoint(
                    id: "prayer_4",
                    order: 4,
                    title:
                        "Bringing Anxiety to God",
                    subtitle:
                        "Paul connects prayer with bringing specific concerns before God.",
                    passage:
                        "Philippians 4:4-7",
                    focusQuestion:
                        "What does Paul actually tell believers to do with the things they are anxious about?"
                ),

                JourneyCheckpoint(
                    id: "prayer_5",
                    order: 5,
                    title:
                        "Keep Praying",
                    subtitle:
                        "Jesus tells a story specifically about persistence in prayer.",
                    passage:
                        "Luke 18:1-8",
                    focusQuestion:
                        "Why does Jesus want His followers to keep praying even when answers do not come quickly?"
                ),

                JourneyCheckpoint(
                    id: "prayer_6",
                    order: 6,
                    title:
                        "Create a Sustainable Rhythm",
                    subtitle:
                        "Paul describes prayer as part of an ongoing life with God.",
                    passage:
                        "1 Thessalonians 5:16-24",
                    focusQuestion:
                        "What realistic rhythm of prayer could you begin practicing consistently?"
                )
            ],

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Grief
    // =====================================================

    private static func griefPath(
        focus: JourneyFocus
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "grief"
                ),

            title:
                "Walking Through Grief",

            subtitle:
                "Explore biblical grief, honest lament, the presence of God, and Christian hope.",

            category:
                .personalized,

            checkpoints: [

                JourneyCheckpoint(
                    id: "grief_1",
                    order: 1,
                    title:
                        "Give Grief a Voice",
                    subtitle:
                        "Psalm 13 gives language to pain rather than pretending everything is fine.",
                    passage:
                        "Psalm 13:1-6",
                    focusQuestion:
                        "What does this Psalm show you about speaking honestly to God in grief?"
                ),

                JourneyCheckpoint(
                    id: "grief_2",
                    order: 2,
                    title:
                        "Jesus at the Grave",
                    subtitle:
                        "Jesus enters the grief of Mary and Martha before raising Lazarus.",
                    passage:
                        "John 11:17-44",
                    focusQuestion:
                        "What does Jesus' response reveal about how He relates to people who are grieving?"
                ),

                JourneyCheckpoint(
                    id: "grief_3",
                    order: 3,
                    title:
                        "When Loss Changes Everything",
                    subtitle:
                        "Job experiences devastating loss and responds from inside the pain.",
                    passage:
                        "Job 1:13-22",
                    focusQuestion:
                        "What does Job's response show about grief, worship, and unanswered questions?"
                ),

                JourneyCheckpoint(
                    id: "grief_4",
                    order: 4,
                    title:
                        "Talking to Your Own Soul",
                    subtitle:
                        "Psalm 42 moves back and forth between sorrow and hope.",
                    passage:
                        "Psalm 42:1-11",
                    focusQuestion:
                        "How does the writer hold sorrow and hope together?"
                ),

                JourneyCheckpoint(
                    id: "grief_5",
                    order: 5,
                    title:
                        "Comfort Received and Shared",
                    subtitle:
                        "Paul describes God as the God of comfort in the middle of suffering.",
                    passage:
                        "2 Corinthians 1:3-7",
                    focusQuestion:
                        "How might receiving comfort eventually change the way you relate to others who suffer?"
                ),

                JourneyCheckpoint(
                    id: "grief_6",
                    order: 6,
                    title:
                        "Hope Beyond Loss",
                    subtitle:
                        "Revelation gives a picture of a future where suffering and death do not have the final word.",
                    passage:
                        "Revelation 21:1-5",
                    focusQuestion:
                        "What part of this promised future speaks most directly to your grief?"
                )
            ],

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Fear / Worry
    // =====================================================

    private static func fearPath(
        focus: JourneyFocus
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "fear"
                ),

            title:
                "Facing Fear and Worry",

            subtitle:
                "Learn how Scripture addresses fear without pretending difficult circumstances are not real.",

            category:
                .personalized,

            checkpoints: [

                JourneyCheckpoint(
                    id: "fear_1",
                    order: 1,
                    title:
                        "What Worry Is Looking At",
                    subtitle:
                        "Jesus speaks directly about worry over everyday needs.",
                    passage:
                        "Matthew 6:25-34",
                    focusQuestion:
                        "What does Jesus redirect His listeners to notice when worry dominates their attention?"
                ),

                JourneyCheckpoint(
                    id: "fear_2",
                    order: 2,
                    title:
                        "Fear and Trust Together",
                    subtitle:
                        "The Psalmist does not deny fear; he describes what he does when fear appears.",
                    passage:
                        "Psalm 56:1-13",
                    focusQuestion:
                        "What does the Psalmist do when he is afraid?"
                ),

                JourneyCheckpoint(
                    id: "fear_3",
                    order: 3,
                    title:
                        "Bring the Specific Fear",
                    subtitle:
                        "Paul tells believers what to do with anxious thoughts.",
                    passage:
                        "Philippians 4:4-9",
                    focusQuestion:
                        "What concrete practices does Paul connect with peace?"
                ),

                JourneyCheckpoint(
                    id: "fear_4",
                    order: 4,
                    title:
                        "When the Storm Is Real",
                    subtitle:
                        "The disciples experience genuine danger while Jesus is with them.",
                    passage:
                        "Mark 4:35-41",
                    focusQuestion:
                        "How does Jesus address both the storm and the disciples' fear?"
                ),

                JourneyCheckpoint(
                    id: "fear_5",
                    order: 5,
                    title:
                        "Cast the Weight Somewhere",
                    subtitle:
                        "Peter connects humility, anxiety, watchfulness, and trust in God.",
                    passage:
                        "1 Peter 5:6-10",
                    focusQuestion:
                        "What would it look like to actively cast this specific worry onto God?"
                ),

                JourneyCheckpoint(
                    id: "fear_6",
                    order: 6,
                    title:
                        "A Place to Stand",
                    subtitle:
                        "Psalm 46 describes security even while circumstances are unstable.",
                    passage:
                        "Psalm 46:1-11",
                    focusQuestion:
                        "What truth in this Psalm do you want to remember the next time fear rises?"
                )
            ],

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Loneliness
    // =====================================================

    private static func lonelinessPath(
        focus: JourneyFocus
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "loneliness"
                ),

            title:
                "Walking Through Loneliness",

            subtitle:
                "Explore isolation, God's presence, community, and what Scripture says when you feel alone.",

            category:
                .personalized,

            checkpoints: [

                JourneyCheckpoint(
                    id: "loneliness_1",
                    order: 1,
                    title:
                        "When You Feel Alone",
                    subtitle:
                        "David expresses both isolation and confidence in God's presence.",
                    passage:
                        "Psalm 27:7-14",
                    focusQuestion:
                        "What does David reach for when he feels abandoned?"
                ),

                JourneyCheckpoint(
                    id: "loneliness_2",
                    order: 2,
                    title:
                        "Elijah Under the Tree",
                    subtitle:
                        "After a major spiritual victory, Elijah becomes exhausted, isolated, and discouraged.",
                    passage:
                        "1 Kings 19:1-18",
                    focusQuestion:
                        "How does God respond to Elijah physically, emotionally, and spiritually?"
                ),

                JourneyCheckpoint(
                    id: "loneliness_3",
                    order: 3,
                    title:
                        "I Will Not Leave You Orphaned",
                    subtitle:
                        "Jesus prepares His disciples for His departure and speaks about His continuing presence.",
                    passage:
                        "John 14:15-18",
                    focusQuestion:
                        "What promise does Jesus give to disciples who are afraid of being left alone?"
                ),

                JourneyCheckpoint(
                    id: "loneliness_4",
                    order: 4,
                    title:
                        "Fully Known",
                    subtitle:
                        "Psalm 139 reflects on being completely known and seen by God.",
                    passage:
                        "Psalm 139:1-18",
                    focusQuestion:
                        "What does it mean to you that being alone is not the same as being unseen?"
                ),

                JourneyCheckpoint(
                    id: "loneliness_5",
                    order: 5,
                    title:
                        "Don't Withdraw From Community",
                    subtitle:
                        "Hebrews describes the role believers play in encouraging one another.",
                    passage:
                        "Hebrews 10:19-25",
                    focusQuestion:
                        "What kind of community or connection might you need to pursue rather than waiting for it to happen?"
                ),

                JourneyCheckpoint(
                    id: "loneliness_6",
                    order: 6,
                    title:
                        "Not Abandoned",
                    subtitle:
                        "Paul remembers a moment when people left him but says he was not ultimately alone.",
                    passage:
                        "2 Timothy 4:9-18",
                    focusQuestion:
                        "What would moving forward faithfully look like even if loneliness has not disappeared completely?"
                )
            ],

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Purpose
    // =====================================================

    private static func purposePath(
        focus: JourneyFocus
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "purpose"
                ),

            title:
                "Discovering Purpose",

            subtitle:
                "Explore identity, calling, gifts, service, and faithful direction through Scripture.",

            category:
                .personalized,

            checkpoints: [

                JourneyCheckpoint(
                    id: "purpose_1",
                    order: 1,
                    title:
                        "Created for Good Works",
                    subtitle:
                        "Paul connects grace, identity, and the life God calls believers into.",
                    passage:
                        "Ephesians 2:8-10",
                    focusQuestion:
                        "How does this passage connect salvation with the way you live afterward?"
                ),

                JourneyCheckpoint(
                    id: "purpose_2",
                    order: 2,
                    title:
                        "What God Requires",
                    subtitle:
                        "Micah gives a surprisingly simple summary of faithful living.",
                    passage:
                        "Micah 6:6-8",
                    focusQuestion:
                        "How does this passage challenge the idea that purpose must always be something dramatic?"
                ),

                JourneyCheckpoint(
                    id: "purpose_3",
                    order: 3,
                    title:
                        "Different Gifts, One Body",
                    subtitle:
                        "Paul describes different gifts serving a shared purpose.",
                    passage:
                        "1 Corinthians 12:12-27",
                    focusQuestion:
                        "What does this passage suggest about comparing your calling with someone else's?"
                ),

                JourneyCheckpoint(
                    id: "purpose_4",
                    order: 4,
                    title:
                        "Offer Your Life",
                    subtitle:
                        "Romans describes transformation as something that affects how believers think and live.",
                    passage:
                        "Romans 12:1-8",
                    focusQuestion:
                        "What gifts, responsibilities, or opportunities are already in front of you?"
                ),

                JourneyCheckpoint(
                    id: "purpose_5",
                    order: 5,
                    title:
                        "Purpose in Ordinary Work",
                    subtitle:
                        "Paul applies faithfulness even to ordinary responsibilities.",
                    passage:
                        "Colossians 3:17-24",
                    focusQuestion:
                        "How might purpose change if you viewed ordinary responsibilities as meaningful too?"
                ),

                JourneyCheckpoint(
                    id: "purpose_6",
                    order: 6,
                    title:
                        "Your Next Faithful Step",
                    subtitle:
                        "Jesus sends His followers outward with a clear mission.",
                    passage:
                        "Matthew 28:16-20",
                    focusQuestion:
                        "What is one concrete next step you can faithfully take without needing your entire future figured out?"
                )
            ],

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Self-Control / Habits
    // =====================================================

    private static func selfControlPath(
        focus: JourneyFocus
    ) -> JourneyPath {

        JourneyPath(

            id:
                personalizedID(
                    topic: "self_control"
                ),

            title:
                "Building Self-Control",

            subtitle:
                "Explore discipline, habits, renewal, and how repeated choices shape your life.",

            category:
                .personalized,

            checkpoints: [

                JourneyCheckpoint(
                    id: "self_control_1",
                    order: 1,
                    title:
                        "When There Are No Walls",
                    subtitle:
                        "Proverbs compares a person without self-control to an unprotected city.",
                    passage:
                        "Proverbs 25:28",
                    focusQuestion:
                        "Where does a lack of boundaries make you most vulnerable right now?"
                ),

                JourneyCheckpoint(
                    id: "self_control_2",
                    order: 2,
                    title:
                        "Decide Before the Pressure",
                    subtitle:
                        "Daniel makes a decision about his convictions before the pattern is established.",
                    passage:
                        "Daniel 1:8-17",
                    focusQuestion:
                        "What decision could you make ahead of time instead of relying on willpower in the moment?"
                ),

                JourneyCheckpoint(
                    id: "self_control_3",
                    order: 3,
                    title:
                        "Train With a Goal",
                    subtitle:
                        "Paul compares spiritual discipline to athletic training.",
                    passage:
                        "1 Corinthians 9:24-27",
                    focusQuestion:
                        "What is the difference between punishment and purposeful training?"
                ),

                JourneyCheckpoint(
                    id: "self_control_4",
                    order: 4,
                    title:
                        "Renew the Pattern",
                    subtitle:
                        "Romans connects transformation with a renewed mind.",
                    passage:
                        "Romans 12:1-2",
                    focusQuestion:
                        "Which repeated thought or assumption tends to reinforce the habit you want to change?"
                ),

                JourneyCheckpoint(
                    id: "self_control_5",
                    order: 5,
                    title:
                        "Walk in a Different Direction",
                    subtitle:
                        "Self-control appears as part of a larger life shaped by the Spirit.",
                    passage:
                        "Galatians 5:16-25",
                    focusQuestion:
                        "What healthier behavior needs to replace the habit rather than simply leaving an empty space?"
                ),

                JourneyCheckpoint(
                    id: "self_control_6",
                    order: 6,
                    title:
                        "Build It Over Time",
                    subtitle:
                        "Peter describes spiritual growth as something developed intentionally.",
                    passage:
                        "2 Peter 1:5-8",
                    focusQuestion:
                        "What small practice could you repeat consistently enough for it to become part of who you are becoming?"
                )
            ],

            focus:
                focus,

            createdAt:
                Date()
        )
    }


    // =====================================================
    // MARK: - Unique Personalized ID
    // =====================================================

    /// Personalized paths need unique IDs.
    ///
    /// If someone completes an anger path today and
    /// returns to anger six months later, we do not
    /// want the second journey to inherit the first
    /// journey's progress accidentally.
    private static func personalizedID(
        topic: String
    ) -> String {

        let uuid =
            UUID()
                .uuidString
                .lowercased()


        return
            "personalized_\(topic)_\(uuid)"
    }
}
