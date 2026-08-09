import SwiftUI

/// The app's top-level bottom tab bar: Home / Creations / Settings.
struct RootView: View {
    @State private var selection: Int = {
        switch UITestSupport.screen {
        case "creations": return 1
        case "settings": return 2
        default: return 0
        }
    }()

    var body: some View {
        TabView(selection: $selection) {
            HomeContainerView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            CreationsView()
                .tabItem { Label("Creations", systemImage: "photo.stack.fill") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(KSTheme.accent)
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
