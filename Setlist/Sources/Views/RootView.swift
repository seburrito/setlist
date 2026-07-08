import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case home, library, progress, history
}

/// Top-level composition: the four tabs, the always-visible tab bar, the
/// persistent mini-bar (visible whenever a workout is active and focus mode
/// isn't open — even while the overview sheet itself is showing), and the
/// full-screen active-workout overlay. This mirrors the design's layering:
/// tab bar always at the very bottom, workout sheet above it but still leaving
/// the tab bar reachable, mini-bar floating above both.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var session: WorkoutSession?

    var body: some View {
        Group {
            if let session {
                RootContent(session: session)
            } else {
                Theme.background.ignoresSafeArea()
            }
        }
        .onAppear {
            if session == nil {
                session = WorkoutSession(context: modelContext)
            }
        }
    }
}

private struct RootContent: View {
    let session: WorkoutSession

    @State private var tab: AppTab = .home
    @State private var showStartPicker = false
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            Group {
                switch tab {
                case .home: HomeView(session: session, showStartPicker: $showStartPicker, showSettings: $showSettings)
                case .library: LibraryView()
                case .progress: ProgressTabView()
                case .history: HistoryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if session.isSheetVisible {
                ActiveWorkoutOverview(session: session)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.bottom, Theme.tabBarHeight)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }

            TabBarView(tab: tab) { newTab in
                tab = newTab
                session.collapse()
            }
            .zIndex(2)

            if session.isMiniBarVisible {
                MiniBarView(session: session)
                    .padding(.horizontal, 10)
                    .padding(.bottom, Theme.tabBarHeight + 10)
                    .zIndex(3)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: session.isSheetVisible)
        .animation(.spring(response: 0.3, dampingFraction: 0.86), value: session.isMiniBarVisible)
        .sheet(isPresented: $showStartPicker) {
            StartWorkoutSheet(session: session, isPresented: $showStartPicker)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }
}
