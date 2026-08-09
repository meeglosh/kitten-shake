import SwiftUI

/// Lets a pushed screen (currently just `ResultView`, a full-height
/// celebration screen with no mockup tab bar) ask `RootView` to collapse its
/// floating `KSTabBar` safe-area inset. `RootView` sits *above*
/// `HomeContainerView`'s navigation stack in the view tree, so a plain
/// `@EnvironmentObject` set from a pushed child wouldn't flow upward; a
/// shared singleton (same pattern as `CreationStore.shared`) is the simplest
/// way to bridge that without threading state through every intermediate
/// view.
final class TabBarVisibility: ObservableObject {
    static let shared = TabBarVisibility()
    @Published var isHidden = false
    private init() {}
}

struct KSTabBarItem {
    let title: String
    let systemImage: String
}

/// A floating white-pill tab bar matching the mockups exactly: active tab
/// shows a coral icon + label with a short underline bar beneath; inactive
/// tabs are muted gray-navy. Purely a chrome replacement for the native
/// `TabView` bar — `RootView` still owns `selection` and the three
/// destinations, so navigation/flow is unchanged.
struct KSTabBar: View {
    @Binding var selection: Int
    let items: [KSTabBarItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                tabButton(index: index)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(KSTheme.surface)
        )
        // The shadow is drawn as its own layer (rather than directly on the
        // capsule background) so its blur has room to fade out above the
        // safe area instead of being hard-clipped by the screen edge, which
        // otherwise reads as a stray rounded-rect artifact peeking out below
        // the bar.
        .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 3)
        .padding(.horizontal, KSTheme.spacingM)
        .padding(.bottom, 4)
    }

    private func tabButton(index: Int) -> some View {
        let isSelected = selection == index
        let item = items[index]
        return Button {
            if selection != index {
                SoundPlayer.shared.playClick()
            }
            selection = index
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                Text(item.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .rounded))
                Capsule()
                    .fill(isSelected ? KSTheme.accent : Color.clear)
                    .frame(width: 18, height: 3)
            }
            .foregroundStyle(isSelected ? KSTheme.accent : KSTheme.textSecondary.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? KSTheme.accent.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
