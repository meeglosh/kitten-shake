import SwiftUI

/// Mockup 5: the scene-composition hub. Shows every placed kitten
/// composited on the background, a thumbnail tray to re-select/remove any
/// of them, and the entry points for adding more kittens (classic shake or
/// AI generation), reordering (Layers), undo, and Save.
struct BuildSceneView: View {
    @Binding var path: [HomeRoute]
    @EnvironmentObject private var scene: EditorScene

    @ObservedObject private var entitlements = Entitlements.shared
    @ObservedObject private var quota = GenerationQuota.shared

    @State private var showAddSheet = false
    @State private var showLayers = false
    @State private var isGenerating = false
    @State private var generatingPulse = false
    @State private var generationErrorMessage: String?
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            KSScreenBackground()

            ScrollView {
                VStack(spacing: KSTheme.spacingM) {
                    topBar

                    headline

                    photoCard
                        .frame(height: 340)
                        .padding(.horizontal, KSTheme.spacingM)

                    thumbnailTray
                        .padding(.horizontal, KSTheme.spacingM)

                    VStack(spacing: 12) {
                        Button {
                            SoundPlayer.shared.playClick()
                            showAddSheet = true
                        } label: {
                            Label("Add Another Kitten", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.ksPrimary)

                        HStack(spacing: 14) {
                            Button {
                                SoundPlayer.shared.playClick()
                                saveScene()
                            } label: {
                                Label("Save", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.ksSecondary)
                            .disabled(scene.sprites.isEmpty)

                            Button {
                                SoundPlayer.shared.playClick()
                                showLayers = true
                            } label: {
                                Label("Layers", systemImage: "square.3.layers.3d")
                            }
                            .buttonStyle(.ksSecondary)
                            .disabled(scene.sprites.isEmpty)
                        }
                    }
                    .padding(.horizontal, KSTheme.spacingM)
                    .padding(.bottom, KSTheme.flowBottomClearance)
                }
            }
            .ksReadableWidth()

            if isGenerating {
                generatingOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            if UITestSupport.autoAI {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { addAIKitten() }
            }
            if UITestSupport.autoExport {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { saveScene() }
            }
        }
        .confirmationDialog("Add Another Kitten", isPresented: $showAddSheet, titleVisibility: .visible) {
            Button("Shake a Classic Kitten") {
                path.append(.shakeReview)
            }
            Button(aiKittenLabel) {
                addAIKitten()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showLayers) {
            LayersSheet(scene: scene)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .animation(.easeInOut(duration: 0.2), value: isGenerating)
        .alert(
            "Oops",
            isPresented: Binding(
                get: { generationErrorMessage != nil },
                set: { if !$0 { generationErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { generationErrorMessage = nil }
        } message: {
            Text(generationErrorMessage ?? "")
        }
    }

    private var aiKittenLabel: String {
        entitlements.isSubscriber ? "✨ AI Kitten" : "✨ AI Kitten (\(quota.freeRemaining) free left)"
    }

    private var topBar: some View {
        HStack {
            Button {
                SoundPlayer.shared.playClick()
                if !path.isEmpty { path.removeLast() }
            } label: {
                ZStack {
                    Circle().fill(KSTheme.surface).frame(width: 40, height: 40)
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(KSTheme.accent)
                }
            }
            Spacer()
            BrandHeader(markSize: 48, lineSize: 22)
            Spacer()
            Button {
                SoundPlayer.shared.playClick()
                scene.undo()
            } label: {
                ZStack {
                    Circle().fill(KSTheme.surface).frame(width: 40, height: 40)
                    Image(systemName: "arrow.uturn.backward")
                        .font(.headline)
                        .foregroundStyle(scene.canUndo ? KSTheme.accent : KSTheme.textSecondary.opacity(0.4))
                }
            }
            .disabled(!scene.canUndo)
        }
        .padding(.horizontal, KSTheme.spacingM)
        .padding(.top, KSTheme.spacingS)
    }

    private var headline: some View {
        HStack(spacing: 10) {
            Rectangle().fill(KSTheme.accent.opacity(0.4)).frame(width: 22, height: 2)
            Text("Build Your Scene")
                .font(KSTheme.display(28))
                .foregroundStyle(KSTheme.textPrimary)
            Rectangle().fill(KSTheme.accent.opacity(0.4)).frame(width: 22, height: 2)
        }
    }

    private var photoCard: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack(alignment: .topLeading) {
                ZStack {
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
                                .onTapGesture { scene.pet() }
                        }
                    }
                }
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                        .stroke(.white, lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.14), radius: 16, y: 8)

                countPill
                    .padding(14)

                ZStack {
                    Circle().fill(KSTheme.surface).frame(width: 48, height: 48)
                    Image(systemName: "heart.fill").foregroundStyle(KSTheme.accent)
                }
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                .padding(14)
                .frame(width: side, height: side, alignment: .bottomTrailing)
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private var countPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "cat.fill")
                .foregroundStyle(KSTheme.accent)
            Text("\(scene.sprites.count) kitten\(scene.sprites.count == 1 ? "" : "s")")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KSTheme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(KSTheme.surface.opacity(0.92)))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    private var thumbnailTray: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(scene.sprites.enumerated()), id: \.element.id) { index, sprite in
                    thumbnail(for: sprite, index: index)
                }

                addTile
            }
            .padding(.vertical, 4)
        }
    }

    private func thumbnail(for sprite: KittenSprite, index: Int) -> some View {
        Button {
            SoundPlayer.shared.playClick()
            scene.selectedSpriteID = sprite.id
            path.append(.position)
        } label: {
            ZStack(alignment: .topLeading) {
                Group {
                    if let uiImage = scene.image(for: sprite.imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        KSTheme.surface
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(KSTheme.cardBorder, lineWidth: 2)
                )

                Text("\(index + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(KSTheme.accent))
                    .offset(x: -6, y: -6)
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    scene.removeSprite(id: sprite.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KSTheme.textPrimary)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(KSTheme.surface))
                        .shadow(color: .black.opacity(0.15), radius: 2)
                }
                .offset(x: 6, y: -6)
            }
        }
        .buttonStyle(.plain)
    }

    private var addTile: some View {
        Button {
            SoundPlayer.shared.playClick()
            showAddSheet = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.headline)
                Text("Add")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(KSTheme.accent)
            .frame(width: 72, height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .foregroundStyle(KSTheme.accent.opacity(0.6))
            )
        }
        .buttonStyle(.plain)
    }

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: KSTheme.spacingM) {
                Image(systemName: "cat.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                    .scaleEffect(generatingPulse ? 1.15 : 0.88)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: generatingPulse)
                Text("Summoning your kitten…")
                    .font(KSTheme.display(20))
                    .foregroundStyle(.white)
                Text("This can take up to 20 seconds ✨")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(KSTheme.spacingXL)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous))
        }
        .onAppear { generatingPulse = true }
        .onDisappear { generatingPulse = false }
        .transition(.opacity)
    }

    /// Requests a new AI kitten from the backend, places it intelligently on
    /// the current photo via `KittenPlacer`, adds it to the scene, and jumps
    /// into Position Mode to adjust it — mirroring the AI path that used to
    /// live in `EditorView`, wired to the same quota/paywall/entitlements
    /// services.
    private func addAIKitten() {
        guard !isGenerating else { return }
        guard entitlements.isSubscriber || quota.freeRemaining > 0 else {
            showPaywall = true
            return
        }
        guard let background = scene.backgroundImage else { return }

        SoundPlayer.shared.playClick()
        isGenerating = true

        Task {
            do {
                let jws = entitlements.isSubscriber ? entitlements.currentTransactionJWS : nil
                let result = try await KittenGenerationClient.generate(transactionJWS: jws)
                quota.record(remaining: result.remaining)

                guard let name = GeneratedKittenStore.shared.save(result.image) else {
                    throw KittenGenerationError.decoding
                }
                scene.kittenImageCache[name] = result.image

                let placement = await KittenPlacer.computePlacement(for: background)
                scene.addSprite(imageName: name, normalizedPosition: placement.normalizedPosition, scale: placement.scale)
                isGenerating = false
                path.append(.position)
            } catch let error as KittenGenerationError {
                isGenerating = false
                if case .subscriptionRequired = error {
                    quota.markExhausted()
                    showPaywall = true
                } else {
                    generationErrorMessage = error.errorDescription
                }
            } catch {
                isGenerating = false
                generationErrorMessage = "Something went wrong. Please try again."
            }
        }
    }

    private func saveScene() {
        guard let flattened = scene.flattenedImage(includeWatermark: !entitlements.isSubscriber) else { return }
        UIImageWriteToSavedPhotosAlbum(flattened, nil, nil, nil)
        CreationStore.shared.save(flattened)
        path.append(.result(ImageBox(flattened)))
    }
}

/// In-theme sheet for reordering placed kittens' stacking order (front/back)
/// via a plain `List` with `.onMove`, styled with the app's cream/coral
/// palette instead of stock list chrome.
private struct LayersSheet: View {
    @ObservedObject var scene: EditorScene
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                KSTheme.background.ignoresSafeArea()
                List {
                    ForEach(Array(scene.sprites.enumerated()), id: \.element.id) { index, sprite in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(KSTheme.accent))

                            if let uiImage = scene.image(for: sprite.imageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }

                            Text("Kitten \(index + 1)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KSTheme.textPrimary)
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(KSTheme.textSecondary)
                        }
                        .listRowBackground(KSTheme.surface)
                    }
                    .onMove { source, destination in
                        scene.moveSprites(fromOffsets: source, toOffset: destination)
                    }
                }
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
            }
            .navigationTitle("Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KSTheme.accent)
                }
            }
        }
    }
}
