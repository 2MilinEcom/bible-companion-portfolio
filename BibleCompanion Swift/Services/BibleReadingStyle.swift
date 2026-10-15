import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension AppAppearance {
  var preferredColorScheme: ColorScheme? {
    switch self {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
  }
}

extension BibleReadingFont {
  fileprivate var design: Font.Design {
    switch self {
    case .system: return .default
    case .serif: return .serif
    case .rounded: return .rounded
    }
  }
}

@MainActor
private struct BibleReadingStyleModifier: ViewModifier {
  @ObservedObject private var settings = AppSettingsStore.shared
  @ScaledMetric(relativeTo: .body) private var scaledBodySize: CGFloat = 17

  func body(content: Content) -> some View {
    let dynamicTypeScale = scaledBodySize / 17
    content
      .font(
        .system(
          size: CGFloat(settings.readingTextSize) * dynamicTypeScale,
          design: settings.readingFont.design)
      )
      .lineSpacing(CGFloat(settings.readingLineSpacing) * dynamicTypeScale)
  }
}

extension View {
  /// Apply only to Scripture text, not navigation controls or chat instructions.
  /// Dynamic Type is respected in addition to the user's reading preferences.
  @MainActor
  func bibleReadingStyle() -> some View {
    modifier(BibleReadingStyleModifier())
  }
}

// =========================================================
// MARK: - App-Wide Pastel Cloud Theme
// =========================================================

// MARK: - Bible Companion visual language
//
// The app deliberately uses semantic colors instead of raw system blues/grays.
// This keeps the current Sky Blue look consistent and makes future user themes
// (pink, parchment, etc.) easy to add without redesigning every screen.

enum AppTheme {
  private static var hue: (Double, Double, Double) {
    switch AppSettingsStore.shared.visualTheme {
    case .sky: return (0.20, 0.43, 0.66)
    case .pink: return (0.64, 0.25, 0.43)
    case .parchment: return (0.49, 0.34, 0.20)
    case .sage: return (0.22, 0.43, 0.34)
    case .rose: return (0.61, 0.29, 0.39)
    case .lavender: return (0.43, 0.34, 0.62)
    }
  }

  private static func adaptive(_ light: (Double, Double, Double),
                               _ dark: (Double, Double, Double)) -> Color {
    #if canImport(UIKit)
    return Color(uiColor: UIColor { traits in
      let c = traits.userInterfaceStyle == .dark ? dark : light
      return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
    })
    #else
    return Color(red: light.0, green: light.1, blue: light.2)
    #endif
  }

  private static func wash(_ amount: Double) -> (Double, Double, Double) {
    let c = hue
    return (c.0 + (1-c.0)*amount, c.1 + (1-c.1)*amount, c.2 + (1-c.2)*amount)
  }
  private static var isPink: Bool { AppSettingsStore.shared.visualTheme == .pink }
  static var skyTop: Color {
    isPink ? adaptive((1.0, 0.85, 0.92), (0.17, 0.09, 0.13))
      : adaptive(wash(0.80), (0.075, 0.10, 0.14))
  }
  static var skyMid: Color {
    isPink ? adaptive((1.0, 0.94, 0.97), (0.12, 0.07, 0.10))
      : adaptive(wash(0.93), (0.09, 0.12, 0.16))
  }
  static var skyBottom: Color {
    isPink ? adaptive((1.0, 0.985, 0.995), (0.14, 0.09, 0.12))
      : adaptive(wash(0.99), (0.11, 0.14, 0.18))
  }
  static var background: Color { skyMid }
  static var surface: Color { adaptive(wash(0.985), (0.15, 0.18, 0.23)) }
  static var surfaceStrong: Color { adaptive((1,1,1), (0.17, 0.20, 0.25)) }
  static var surfaceSoft: Color { adaptive(wash(0.94), (0.13, 0.16, 0.21)) }
  static var surfaceMuted: Color { adaptive(wash(0.88), (0.19, 0.22, 0.28)) }
  static var accent: Color { adaptive(hue, wash(0.55)) }
  static var accentDeep: Color { adaptive(hue, wash(0.65)) }
  static var accentSoft: Color {
    isPink ? adaptive((1.0, 0.70, 0.83), (0.35, 0.19, 0.28))
      : adaptive(wash(0.76), (0.25, 0.31, 0.39))
  }
  static var accentMist: Color {
    isPink ? adaptive((1.0, 0.88, 0.94), (0.26, 0.14, 0.21))
      : adaptive(wash(0.90), (0.18, 0.23, 0.30))
  }
  static var backgroundGlow: Color {
    isPink ? adaptive((1.0, 0.76, 0.88), (0.30, 0.16, 0.24)) : goldSoft
  }
  static var textPrimary: Color { adaptive((0.12, 0.20, 0.29), (0.94, 0.96, 0.99)) }
  static var textSecondary: Color { adaptive((0.33, 0.40, 0.48), (0.70, 0.76, 0.84)) }
  static var heatherGray: Color { textSecondary.opacity(0.8) }
  static var divider: Color { textSecondary.opacity(0.22) }
  static let gold = Color(red: 0.94, green: 0.76, blue: 0.34)
  static var goldSoft: Color { adaptive((1.0,0.95,0.78), (0.30,0.26,0.18)) }
  static let sage = Color(red: 0.48, green: 0.72, blue: 0.65)
  static let shadow = Color.black.opacity(0.07)
  static let shadowStrong = Color.black.opacity(0.12)

  static var screenGradient: LinearGradient { LinearGradient(
    colors: [skyTop, skyMid, skyBottom],
    startPoint: .top,
    endPoint: .bottom
  ) }

  static var cardGradient: LinearGradient { LinearGradient(
    colors: [surfaceStrong, surface],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  ) }

  static var buttonGradient: LinearGradient { LinearGradient(
    colors: [Color(red: hue.0, green: hue.1, blue: hue.2), Color(red: hue.0, green: hue.1, blue: hue.2)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  ) }

  static var heroGradient: LinearGradient { LinearGradient(
    colors: [skyTop, skyMid, skyBottom],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  ) }

  static let cardRadius: CGFloat = 24
  static let innerRadius: CGFloat = 17
}

// MARK: - Global screen backdrop

struct CloudScreenBackground: View {
  @ObservedObject private var settings = AppSettingsStore.shared
  var showsSparkles = true

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        AppTheme.screenGradient

        // Gentle sunlight in the upper-right corner.
        RadialGradient(
          colors: [AppTheme.backgroundGlow.opacity(0.58), Color.clear],
          center: .topTrailing,
          startRadius: 8,
          endRadius: max(proxy.size.width, proxy.size.height) * 0.60
        )

        CloudCluster(scale: 1.08, opacity: 0.80)
          .position(x: proxy.size.width * 0.13, y: proxy.size.height * 0.10)

        CloudCluster(scale: 0.82, opacity: 0.70)
          .position(x: proxy.size.width * 0.88, y: proxy.size.height * 0.24)

        CloudCluster(scale: 1.22, opacity: 0.72)
          .position(x: proxy.size.width * 0.16, y: proxy.size.height * 0.92)

        CloudCluster(scale: 0.95, opacity: 0.60)
          .position(x: proxy.size.width * 0.90, y: proxy.size.height * 0.78)

        if showsSparkles {
          Image(systemName: "sparkle")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppTheme.gold.opacity(0.68))
            .position(x: proxy.size.width * 0.84, y: proxy.size.height * 0.14)

          Image(systemName: "sparkle")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.white.opacity(0.88))
            .position(x: proxy.size.width * 0.22, y: proxy.size.height * 0.22)
        }
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

struct CloudCluster: View {
  var scale: CGFloat = 1
  var opacity: Double = 0.76

  var body: some View {
    ZStack(alignment: .bottom) {
      Capsule()
        .fill(AppTheme.surfaceStrong.opacity(opacity))
        .frame(width: 116, height: 42)

      Circle()
        .fill(AppTheme.surfaceStrong.opacity(opacity))
        .frame(width: 62, height: 62)
        .offset(x: -26, y: -12)

      Circle()
        .fill(AppTheme.surfaceStrong.opacity(opacity * 0.98))
        .frame(width: 78, height: 78)
        .offset(x: 12, y: -16)

      Circle()
        .fill(AppTheme.surfaceStrong.opacity(opacity * 0.94))
        .frame(width: 52, height: 52)
        .offset(x: 44, y: -8)
    }
    .scaleEffect(scale)
    .blur(radius: 0.35)
  }
}

// MARK: - Decorative scenery used by Home and Journey surfaces

struct CloudScenery: View {
  enum Mood {
    case sunrise
    case mountainPath
    case quietClouds
  }

  var mood: Mood = .sunrise
  var showsCompanion = false
  var height: CGFloat = 150

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        AppTheme.heroGradient

        Circle()
          .fill(AppTheme.goldSoft.opacity(0.92))
          .frame(width: 46, height: 46)
          .blur(radius: 0.2)
          .position(
            x: proxy.size.width * (mood == .quietClouds ? 0.78 : 0.80),
            y: proxy.size.height * 0.24
          )
          .shadow(color: AppTheme.gold.opacity(0.20), radius: 14)

        if mood != .quietClouds {
          Image(systemName: "mountain.2.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(
              LinearGradient(
                colors: [
                  AppSettingsStore.shared.visualTheme == .pink ? AppTheme.accentSoft : Color(red: 0.47, green: 0.66, blue: 0.76),
                  AppSettingsStore.shared.visualTheme == .pink ? AppTheme.accentMist : Color(red: 0.72, green: 0.82, blue: 0.79),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(width: proxy.size.width * 0.78)
            .opacity(0.82)
            .position(x: proxy.size.width * 0.56, y: proxy.size.height * 0.67)
        }

        if mood == .mountainPath {
          Path { path in
            path.move(to: CGPoint(x: proxy.size.width * 0.50, y: proxy.size.height * 0.96))
            path.addCurve(
              to: CGPoint(x: proxy.size.width * 0.67, y: proxy.size.height * 0.44),
              control1: CGPoint(x: proxy.size.width * 0.40, y: proxy.size.height * 0.80),
              control2: CGPoint(x: proxy.size.width * 0.72, y: proxy.size.height * 0.67)
            )
          }
          .stroke(
            Color(red: 0.94, green: 0.88, blue: 0.72).opacity(0.95),
            style: StrokeStyle(lineWidth: 17, lineCap: .round)
          )
        }

        CloudCluster(scale: 0.62, opacity: 0.88)
          .position(x: proxy.size.width * 0.13, y: proxy.size.height * 0.34)

        CloudCluster(scale: 0.76, opacity: 0.92)
          .position(x: proxy.size.width * 0.83, y: proxy.size.height * 0.87)

        Image(systemName: "sparkles")
          .foregroundStyle(AppTheme.gold.opacity(0.82))
          .font(.system(size: 18, weight: .semibold))
          .position(x: proxy.size.width * 0.90, y: proxy.size.height * 0.43)

        if showsCompanion {
          CompanionAvatar(size: min(82, height * 0.62), behavior: .floating)
            .position(x: proxy.size.width * 0.82, y: proxy.size.height * 0.68)
        }
      }
    }
    .frame(height: height)
    .clipped()
    .accessibilityHidden(true)
  }
}

// MARK: - Reusable visual modifiers

private struct CloudScreenModifier: ViewModifier {
  @ObservedObject private var settings = AppSettingsStore.shared
  let showsSparkles: Bool

  func body(content: Content) -> some View {
    content
      .foregroundStyle(AppTheme.textPrimary)
      .tint(AppTheme.accent)
      .background {
        CloudScreenBackground(showsSparkles: showsSparkles)
          .ignoresSafeArea()
      }
  }
}

private struct CloudCardModifier: ViewModifier {
  @ObservedObject private var settings = AppSettingsStore.shared
  let radius: CGFloat
  let prominent: Bool

  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .fill(prominent ? AppTheme.surfaceStrong : AppTheme.surface)
          .shadow(
            color: prominent ? AppTheme.shadowStrong : AppTheme.shadow,
            radius: prominent ? 18 : 12,
            x: 0,
            y: prominent ? 8 : 5
          )
      )
      .overlay(
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .stroke(AppTheme.divider, lineWidth: 1)
      )
  }
}

private struct InsetCloudCardModifier: ViewModifier {
  @ObservedObject private var settings = AppSettingsStore.shared
  let radius: CGFloat

  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .fill(AppTheme.surfaceSoft)
      )
      .overlay(
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .stroke(AppTheme.accent.opacity(0.10), lineWidth: 1)
      )
  }
}

struct CloudPrimaryButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled
  @ObservedObject private var settings = AppSettingsStore.shared
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .fontWeight(.semibold)
      .foregroundStyle(Color.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .padding(.horizontal, 18)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(AppTheme.buttonGradient)
          .shadow(
            color: AppTheme.accent.opacity(configuration.isPressed ? 0.10 : 0.24),
            radius: configuration.isPressed ? 4 : 10,
            y: configuration.isPressed ? 2 : 5
          )
      )
      .opacity(isEnabled ? 1 : 0.45)
      .scaleEffect(configuration.isPressed ? 0.985 : 1)
      .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
  }
}

struct CloudSecondaryButtonStyle: ButtonStyle {
  @ObservedObject private var settings = AppSettingsStore.shared
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .fontWeight(.semibold)
      .foregroundStyle(AppTheme.accentDeep)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 13)
      .padding(.horizontal, 16)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(AppTheme.surfaceStrong.opacity(configuration.isPressed ? 0.74 : 0.94))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(AppTheme.accent.opacity(0.18), lineWidth: 1)
      )
  }
}

extension View {
  func cloudScreen(showsSparkles: Bool = true) -> some View {
    modifier(CloudScreenModifier(showsSparkles: showsSparkles))
  }

  func cloudCard(radius: CGFloat = AppTheme.cardRadius, prominent: Bool = false) -> some View {
    modifier(CloudCardModifier(radius: radius, prominent: prominent))
  }

  func cloudInsetCard(radius: CGFloat = AppTheme.innerRadius) -> some View {
    modifier(InsetCloudCardModifier(radius: radius))
  }
}

// =========================================================
// MARK: - Pastel Cloud Reusable Components
// =========================================================

// MARK: - Home hero

struct HomeCloudHero: View {
  let preferredName: String

  private var greeting: String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 5..<12: return "Good morning"
    case 12..<18: return "Good afternoon"
    default: return "Good evening"
    }
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      CloudScenery(mood: .sunrise, showsCompanion: true, height: 190)

      VStack(alignment: .leading, spacing: 7) {
        Text(greeting)
          .font(.system(.title3, design: .serif, weight: .semibold))
          .foregroundStyle(AppTheme.textPrimary.opacity(0.86))

        Text(preferredName.isEmpty ? "Bible Companion" : preferredName)
          .font(.system(size: 34, weight: .bold, design: .serif))
          .foregroundStyle(AppTheme.textPrimary)
          .lineLimit(1)
          .minimumScaleFactor(0.72)

        Text("The same God who guided you yesterday is with you today.")
          .font(.subheadline)
          .foregroundStyle(AppTheme.textSecondary)
          .lineSpacing(2)
          .frame(maxWidth: 220, alignment: .leading)
      }
      .padding(20)
    }
    .frame(height: 190)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(Color.white.opacity(0.75), lineWidth: 1)
    )
    .shadow(color: AppTheme.shadow, radius: 15, y: 7)
  }
}

// MARK: - Section headers

struct CloudSectionHeader: View {
  let title: String
  var subtitle: String? = nil
  var icon: String? = nil

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      if let icon {
        Image(systemName: icon)
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(AppTheme.accentDeep)
          .frame(width: 34, height: 34)
          .background(Circle().fill(AppTheme.accentMist))
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(.title3, design: .serif, weight: .bold))
          .foregroundStyle(AppTheme.textPrimary)

        if let subtitle {
          Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
            .lineSpacing(2)
        }
      }

      Spacer(minLength: 0)
    }
  }
}

// MARK: - Journey hero

struct JourneyCloudHero: View {
  let title: String
  let subtitle: String
  var progress: Double? = nil
  var companion: Bool = true

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .bottomLeading) {
        CloudScenery(mood: .mountainPath, showsCompanion: companion, height: 170)

        LinearGradient(
          colors: [Color.clear, Color.black.opacity(0.62)],
          startPoint: .center,
          endPoint: .bottom
        )

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.system(.title2, design: .serif, weight: .bold))
            .foregroundStyle(Color.white)
            .shadow(color: Color.black.opacity(0.22), radius: 3, y: 1)

          Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(Color.white.opacity(0.94))
            .lineLimit(2)
        }
        .padding(18)
        .padding(.trailing, companion ? 70 : 0)
      }

      if let progress {
        VStack(spacing: 8) {
          HStack {
            Text("Your progress")
              .font(.caption.weight(.semibold))
              .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text("\(Int(progress * 100))%")
              .font(.caption.weight(.bold))
              .foregroundStyle(AppTheme.accentDeep)
          }

          ProgressView(value: progress)
            .tint(AppTheme.accent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppTheme.surfaceStrong)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 26, style: .continuous)
        .stroke(AppTheme.divider, lineWidth: 1)
    )
    .shadow(color: AppTheme.shadow, radius: 14, y: 6)
  }
}

// MARK: - Small themed icon tile

struct CloudIconTile: View {
  let systemName: String
  var tint: Color = AppTheme.accent
  var size: CGFloat = 42

  var body: some View {
    Image(systemName: systemName)
      .font(.system(size: size * 0.42, weight: .semibold))
      .foregroundStyle(tint)
      .frame(width: size, height: size)
      .background(
        RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
          .fill(tint.opacity(0.11))
      )
      .overlay(
        RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
          .stroke(tint.opacity(0.10), lineWidth: 1)
      )
  }
}

// MARK: - Cloud message bubble

struct CompanionCloudBubbleBackground: View {
  var isUser: Bool

  var body: some View {
    RoundedRectangle(cornerRadius: 20, style: .continuous)
      .fill(
        isUser
          ? AnyShapeStyle(AppTheme.buttonGradient)
          : AnyShapeStyle(AppTheme.surfaceStrong)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(
            isUser ? Color.white.opacity(0.22) : AppTheme.accent.opacity(0.10),
            lineWidth: 1
          )
      )
      .shadow(color: AppTheme.shadow.opacity(isUser ? 0.55 : 0.80), radius: 8, y: 4)
  }
}
