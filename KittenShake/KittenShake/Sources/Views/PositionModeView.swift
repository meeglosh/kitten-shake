import SwiftUI

/// Mockup 7: fine-tune the position/scale/rotation of the currently
/// selected sprite. Reuses `KittenSpriteView` for the actual gesture
/// handling (pinch/rotate/drag always work); the Move/Scale/Rotate segmented
/// control additionally constrains what a plain one-finger pan does.
struct PositionModeView: View {
    @Binding var path: [HomeRoute]
    @EnvironmentObject private var scene: EditorScene

    @State private var mode: SpriteTransformMode = .move

    var body: some View {
        ZStack {
            KSScreenBackground()

            VStack(spacing: KSTheme.spacingM) {
                topBar

                selectedPill

                canvas
                    .padding(.horizontal, KSTheme.spacingM)

                bottomPanel
                    .padding(.horizontal, KSTheme.spacingM)
                    // The mockup shows no tab bar on this screen, and it's
                    // hidden via `TabBarVisibility` below, so only normal
                    // safe-area breathing room is needed here.
                    .padding(.bottom, KSTheme.spacingL)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            TabBarVisibility.shared.isHidden = true
        }
        .onDisappear {
            TabBarVisibility.shared.isHidden = false
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                SoundPlayer.shared.playClick()
                path.removeLast()
            } label: {
                ZStack {
                    Circle().fill(KSTheme.surface).frame(width: 40, height: 40)
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(KSTheme.accent)
                }
            }
            Spacer()
            BrandHeader(markSize: 40, lineSize: 20)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, KSTheme.spacingM)
        .padding(.top, KSTheme.spacingS)
    }

    private var selectedPill: some View {
        KSPill(systemImage: "pawprint.fill", text: "Kitten selected", tint: KSTheme.textPrimary, background: KSTheme.surface)
    }

    private var canvas: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                if let background = scene.backgroundImage {
                    Image(uiImage: background)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: side, height: side)
                }

                ForEach($scene.sprites) { $sprite in
                    KittenSpriteView(
                        sprite: $sprite,
                        canvasSide: side,
                        isSelected: sprite.id == scene.selectedSpriteID,
                        uiImage: scene.image(for: sprite.imageName),
                        onSelect: { scene.selectedSpriteID = sprite.id },
                        onPet: { scene.pet() },
                        onTransformBegin: { scene.pushUndo() },
                        constrainedMode: sprite.id == scene.selectedSpriteID ? mode : nil,
                        showHandles: sprite.id == scene.selectedSpriteID
                    )
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                    .stroke(.white, lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.14), radius: 16, y: 8)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var bottomPanel: some View {
        KSCard(padding: KSTheme.spacingM) {
            VStack(spacing: KSTheme.spacingM) {
                modeSegmentedControl

                Button {
                    SoundPlayer.shared.playClick()
                    path.append(.buildScene)
                } label: {
                    Label("Done", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.ksPrimary)

                Text("💡 Pinch to zoom. Twist to rotate. Drag to move. ✨")
                    .font(.caption)
                    .foregroundStyle(KSTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var modeSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(SpriteTransformMode.allCases, id: \.self) { m in
                Button {
                    SoundPlayer.shared.playClick()
                    mode = m
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: m.systemImage)
                            .font(.headline)
                        Text(m.label)
                            .font(.caption.weight(.semibold))
                        Capsule()
                            .fill(mode == m ? KSTheme.accent : Color.clear)
                            .frame(height: 3)
                    }
                    .foregroundStyle(mode == m ? KSTheme.accent : KSTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                if m != SpriteTransformMode.allCases.last {
                    Divider().frame(height: 32)
                }
            }
        }
    }
}
