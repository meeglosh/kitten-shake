import SwiftUI

/// The app's top-level bottom tab bar: Home / Creations / Settings.
struct RootView: View {
    @State private var selection: Int = {
        switch UITestSupport.screen {
        case "creations": return 1
        case "settings", "paywall": return 2
        default: return 0
        }
    }()

    private let tabItems = [
        KSTabBarItem(title: "Home", systemImage: "house.fill"),
        KSTabBarItem(title: "Creations", systemImage: "photo.stack.fill"),
        KSTabBarItem(title: "Settings", systemImage: "gearshape.fill")
    ]

    var body: some View {
        // Deliberately not a system `TabView`: on current SDKs its floating
        // tab-bar background-extension chrome persists faintly behind the
        // safe area even with `.toolbar(.hidden, for: .tabBar)` set,
        // showing as a stray rounded card peeking out below our custom
        // `KSTabBar`. A plain `ZStack` toggling visibility/hit-testing
        // keeps all three tabs alive (so navigation/scroll state survives
        // switching tabs, like `TabView` would) without any of that
        // reserved system chrome.
        ZStack {
            HomeContainerView()
                .opacity(selection == 0 ? 1 : 0)
                .allowsHitTesting(selection == 0)

            CreationsView()
                .opacity(selection == 1 ? 1 : 0)
                .allowsHitTesting(selection == 1)

            SettingsView()
                .opacity(selection == 2 ? 1 : 0)
                .allowsHitTesting(selection == 2)
        }
        .tint(KSTheme.accent)
        .fontDesign(.rounded)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            KSTabBar(selection: $selection, items: tabItems)
                .padding(.bottom, 4)
        }
        .onAppear {
            if UITestSupport.screen == "creations", CreationStore.shared.creations.isEmpty,
               let sample = ResourceLocator.image(named: "kitten_03") {
                CreationStore.shared.save(sample)
            }
        }
    }
}

#Preview {
    RootView()
}
