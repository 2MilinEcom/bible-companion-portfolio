import SwiftUI

struct MainTabView: View {
  @State private var todayRootID = UUID()
  @ObservedObject private var navigation = MainNavigationCoordinator.shared
  @AppStorage("selectedMainTab") private var selection = 0
  @EnvironmentObject private var tutorial: AppTutorialCoordinator
  @ObservedObject private var settings = AppSettingsStore.shared

  var body: some View {
    TabView(selection: $selection) {
      NavigationStack { HomeView() }
        .id(todayRootID)
        .tabItem { Label("Today", systemImage: "sun.max") }.tag(0)
      NavigationStack { BibleExplorerView() }
        .tabItem { Label("Bible", systemImage: "book") }.tag(1)
      NavigationStack { CompanionView() }
        .tabItem { Label("Companion", systemImage: "bubble.left.and.bubble.right") }.tag(2)
      NavigationStack { JourneyHomeView() }
        .tabItem { Label("Journey", systemImage: "map") }.tag(3)
      NavigationStack {
        AppSettingsView(showsDone: false) {
          todayRootID = UUID()
          selection = 0
          tutorial.reset()
        }
      }
      .tabItem { Label("You", systemImage: "person.crop.circle") }.tag(4)
    }
    .tint(AppTheme.accent)
    .onOpenURL { url in
      if DailyWidgetShared.isTodayDeepLink(url) {
        navigation.dailyStudyRequested = true
        todayRootID = UUID()
        selection = 0
      }
    }
    .onChange(of: tutorial.isActive) { _, active in
      if active { selection = 0 }
    }
  }
}

private struct JourneyHomeView: View {
  @State private var activePath: JourneyPath?
  var body: some View {
    Group {
      if let activePath {
        JourneyMapView(journey: activePath)
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            Text("One step at a time").font(.largeTitle.bold())
            Text("Choose a path through Scripture that meets you where you are.")
              .foregroundStyle(AppTheme.textSecondary)
            NavigationLink { ChangePathView(onPathChanged: refresh) } label: {
              Label("Find your path", systemImage: "sparkles")
            }.buttonStyle(CloudPrimaryButtonStyle())
            NavigationLink { JourneyMapView() } label: {
              VStack(alignment: .leading, spacing: 8) {
                Text("Meet Jesus").font(.title2.bold())
                Text("Begin with the foundations, at your own pace.")
                  .foregroundStyle(AppTheme.textSecondary)
              }.frame(maxWidth: .infinity, alignment: .leading)
                .padding(22).cloudCard()
            }.buttonStyle(.plain)
          }.padding(24)
        }
        .cloudScreen()
        .navigationTitle("Journey")
      }
    }
    .onAppear(perform: refresh)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        NavigationLink { ChangePathView(onPathChanged: refresh) } label: {
          Image(systemName: "map")
        }.accessibilityLabel("Choose a different journey")
      }
    }
  }
  private func refresh() {
    activePath = StorageService.shared.loadActivePersonalizedPath()
  }
}
