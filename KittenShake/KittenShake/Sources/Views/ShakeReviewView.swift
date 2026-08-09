import SwiftUI

/// Mockup 6: the shake-review screen. Sits within the tabbed chrome (a
/// `BrandHeader` + the floating `KSTabBar` supplied by `RootView`), auto-
/// places a random "candidate" kitten on entry, and lets the user reshake,
/// remove, or confirm it before moving on to Position Mode.
struct ShakeReviewView: View {
    @Binding var path: [HomeRoute]
    @EnvironmentObject private var scene: EditorScene

    @State private var candidateID: UUID?
    @State private var showShakeDetected = false

    var body: some View {
        ZStack {
            KSScreenBackground()

            VStack(spacing: KSTheme.spacingM) {
                BrandHeader(markSize: 56, lineSize: 26)
                    .padding(.top, KSTheme.spacingS)

                statusPill

                photoCard
                    .padding(.horizontal, KSTheme.spacingM)

                actionButtons
                    .padding(.horizontal, KSTheme.spacingM)

                Button {
                    removeCandidate()
                } label: {
                    Text("Remove")
                        .font(.subheadline.weight(.semibold))
                        .underline()
                        .foregroundStyle(KSTheme.textSecondary)
                }
                .disabled(candidateID == nil)
                .opacity(candidateID == nil ? 0.4 : 1)

                Spacer(minLength: KSTheme.flowBottomClearance)
            }
            .ksReadableWidth()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            if candidateID == nil {
                candidateID = scene.addCandidateKitten()
            }
        }
        .animation(.spring(duration: 0.3), value: showShakeDetected)
        .animation(.spring(duration: 0.3), value: candidateID)
    }

    private var statusPill: some View {
        Group {
            if showShakeDetected {
                KSPill(systemImage: "iphone.gen3.radiowaves.left.and.right", text: "Shake detected!")
            } else if candidateID != nil {
                KSPill(systemImage: "sparkles", text: "New kitten added")
            } else {
                KSPill(systemImage: "hand.tap.fill", text: "Shake to add a kitten", tint: KSTheme.textSecondary, background: KSTheme.surface)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private var photoCard: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack(alignment: .bottomTrailing) {
                if let background = scene.backgroundImage {
                    Image(uiImage: background)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: side, height: side)
                }

                ForEach(scene.sprites) { sprite in
                    if let uiImage = scene.image(for: sprite.imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: side * KittenSprite.defaultSizeFraction * sprite.scale)
                            .rotationEffect(sprite.rotation)
                            .position(x: sprite.normalizedPosition.x * side, y: sprite.normalizedPosition.y * side)
                    }
                }

                ZStack {
                    Circle().fill(KSTheme.peach).frame(width: 52, height: 52)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(KSTheme.accent)
                }
                .overlay(Circle().stroke(KSTheme.surface, lineWidth: 3))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                // Matches the Home/Result treatment: the badge hangs
                // partially outside the card's bottom-right corner rather
                // than sitting fully inside it.
                .offset(x: 14, y: 14)
                .padding(14)
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                    .stroke(.white, lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.14), radius: 16, y: 8)
            .overlay(alignment: .topLeading) {
                HeroRadiatingDashes(pointingRight: false)
                    .offset(x: -10, y: -6)
            }
            .overlay(alignment: .topTrailing) {
                HeroRadiatingDashes(pointingRight: true)
                    .offset(x: 10, y: -6)
            }
            .background(ShakeDetectorView(onShake: handleShake))
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var actionButtons: some View {
        HStack(spacing: 14) {
            Button {
                shakeAgain()
            } label: {
                Label("Shake Again", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.ksSecondary)

            Button {
                useThisKitten()
            } label: {
                Label("Use This Kitten", systemImage: "heart.fill")
            }
            .buttonStyle(.ksPrimary)
            .disabled(candidateID == nil)
            .opacity(candidateID == nil ? 0.5 : 1)
        }
    }

    private func shakeAgain() {
        SoundPlayer.shared.playClick()
        handleShake()
    }

    private func handleShake() {
        withAnimation { showShakeDetected = true }
        scene.reshuffle(spriteID: candidateID)
        if candidateID == nil {
            candidateID = scene.selectedSpriteID
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showShakeDetected = false }
        }
    }

    private func removeCandidate() {
        guard let id = candidateID else { return }
        SoundPlayer.shared.playClick()
        scene.removeSprite(id: id)
        candidateID = nil
    }

    private func useThisKitten() {
        guard let id = candidateID else { return }
        SoundPlayer.shared.playClick()
        scene.selectedSpriteID = id
        path.append(.position)
    }
}
