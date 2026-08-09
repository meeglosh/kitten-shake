import SwiftUI

struct EditorView: View {
    let backgroundImage: UIImage
    @Binding var path: [HomeRoute]

    @State private var sprites: [KittenSprite] = []
    @State private var selectedSpriteID: UUID?
    @State private var shakeTimestamps: [Date] = []
    @State private var kittenImageCache: [String: UIImage] = [:]

    @State private var undoStack: [[KittenSprite]] = []
    @State private var showHint = true

    @ObservedObject private var entitlements = Entitlements.shared
    @ObservedObject private var quota = GenerationQuota.shared
    @State private var isGenerating = false
    @State private var generatingPulse = false
    @State private var generationErrorMessage: String?
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            KSTheme.background.ignoresSafeArea()

            VStack(spacing: KSTheme.spacingM) {
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    ZStack(alignment: .bottom) {
                        Image(uiImage: backgroundImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: side, height: side)
                            .clipShape(RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                                    .stroke(KSTheme.cardBorder, lineWidth: 4)
                            )
                            .shadow(color: .black.opacity(0.12), radius: 14, y: 8)
                            .onTapGesture { selectedSpriteID = nil }

                        ForEach($sprites) { $sprite in
                            KittenSpriteView(
                                sprite: $sprite,
                                canvasSide: side,
                                isSelected: sprite.id == selectedSpriteID,
                                uiImage: image(for: sprite.imageName),
                                onSelect: { selectedSpriteID = sprite.id },
                                onPet: pet,
                                onTransformBegin: pushUndo
                            )
                        }

                        if showHint {
                            hintCard
                                .padding(.bottom, KSTheme.spacingM)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .frame(width: side, height: side)
                    .background(ShakeDetectorView(onShake: handleShake))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .padding(.horizontal, KSTheme.spacingM)

                toolbar
            }
            .ksReadableWidth()

            if isGenerating {
                generatingOverlay
            }
        }
        .navigationTitle("Edit Photo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if sprites.isEmpty { addKitten() }
            if UITestSupport.autoAI {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { addAIKitten() }
            }
            if UITestSupport.autoExport {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { exportAndShowResult() }
            }
        }
        .animation(.spring(duration: 0.35), value: showHint)
        .animation(.easeInOut(duration: 0.2), value: isGenerating)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
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

    private var hintCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .foregroundStyle(KSTheme.textPrimary)
            VStack(alignment: .leading, spacing: 0) {
                Text("Shake your phone")
                    .foregroundStyle(KSTheme.textPrimary)
                Text("to add a kitten")
                    .foregroundStyle(KSTheme.accent)
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    private var toolbar: some View {
        KSCard(padding: KSTheme.spacingM) {
            VStack(spacing: KSTheme.spacingM) {
                HStack(spacing: 20) {
                    toolbarButton(icon: "shuffle", label: "New Kitten", action: shuffleSelected)
                    toolbarButton(icon: "arrow.uturn.backward", label: "Undo", action: undo)
                        .disabled(undoStack.isEmpty)
                        .opacity(undoStack.isEmpty ? 0.35 : 1.0)
                    toolbarButton(icon: "trash", label: "Delete", action: deleteSelected)
                        .disabled(selectedSpriteID == nil)
                        .opacity(selectedSpriteID == nil ? 0.35 : 1.0)
                }

                Button {
                    SoundPlayer.shared.playClick()
                    addKitten()
                } label: {
                    Label("Add Kitten", systemImage: "cat.fill")
                }
                .buttonStyle(.ksPrimary)

                Button {
                    addAIKitten()
                } label: {
                    HStack(spacing: 6) {
                        Label("AI Kitten", systemImage: "sparkles")
                        if !entitlements.isSubscriber {
                            Text("· \(quota.freeRemaining) free left")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
                .buttonStyle(.ksSparkle(disabled: isGenerating))
                .disabled(isGenerating)

                HStack(spacing: 16) {
                    Button {
                        SoundPlayer.shared.playClick()
                        saveToPhotos()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.ksSecondary)

                    Button {
                        SoundPlayer.shared.playClick()
                        exportAndShowResult()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.ksSecondary)
                }
                .disabled(sprites.isEmpty)
            }
        }
        .padding(.horizontal, KSTheme.spacingM)
        .padding(.bottom, KSTheme.spacingS)
    }

    private func toolbarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            SoundPlayer.shared.playClick()
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label).font(.caption2)
            }
            .foregroundStyle(KSTheme.textPrimary)
            .frame(minWidth: 64)
        }
    }

    private func image(for name: String) -> UIImage? {
        if let cached = kittenImageCache[name] { return cached }
        let loaded = GeneratedKittenStore.shared.contains(name)
            ? GeneratedKittenStore.shared.image(named: name)
            : ResourceLocator.image(named: name)
        guard let loaded else { return nil }
        kittenImageCache[name] = loaded
        return loaded
    }

    /// Requests a new AI kitten from the backend, places it intelligently
    /// on the current photo via `KittenPlacer`, and adds it to the canvas.
    /// Non-subscribers with no free generations left are sent to the
    /// paywall instead of hitting the network.
    private func addAIKitten() {
        guard !isGenerating else { return }
        guard entitlements.isSubscriber || quota.freeRemaining > 0 else {
            showPaywall = true
            return
        }

        SoundPlayer.shared.playClick()
        dismissHint()
        isGenerating = true

        Task {
            do {
                let jws = entitlements.isSubscriber ? entitlements.currentTransactionJWS : nil
                let result = try await KittenGenerationClient.generate(transactionJWS: jws)
                quota.record(remaining: result.remaining)

                guard let name = GeneratedKittenStore.shared.save(result.image) else {
                    throw KittenGenerationError.decoding
                }
                kittenImageCache[name] = result.image

                let placement = await KittenPlacer.computePlacement(for: backgroundImage)

                pushUndo()
                let sprite = KittenSprite(
                    imageName: name,
                    normalizedPosition: placement.normalizedPosition,
                    scale: placement.scale
                )
                sprites.append(sprite)
                selectedSpriteID = sprite.id
                SoundPlayer.shared.playRandomMeow()
                isGenerating = false
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

    private func dismissHint() {
        if showHint { showHint = false }
    }

    private func pushUndo() {
        undoStack.append(sprites)
        if undoStack.count > 20 { undoStack.removeFirst() }
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        sprites = previous
        if !sprites.contains(where: { $0.id == selectedSpriteID }) {
            selectedSpriteID = sprites.last?.id
        }
    }

    private func addKitten() {
        pushUndo()
        dismissHint()
        let existingNames = Set(sprites.map { $0.imageName })
        let name = KittenCatalog.classicPack.kittenImageNames.first { !existingNames.contains($0) }
            ?? KittenCatalog.randomKittenImageName()
        let jitter = CGFloat.random(in: -0.08...0.08)
        let sprite = KittenSprite(
            imageName: name,
            normalizedPosition: CGPoint(x: 0.5 + jitter, y: 0.5 + jitter)
        )
        sprites.append(sprite)
        selectedSpriteID = sprite.id
        SoundPlayer.shared.playRandomMeow()
    }

    private func shuffleSelected() {
        guard let id = selectedSpriteID, let idx = sprites.firstIndex(where: { $0.id == id }) else {
            addKitten()
            return
        }
        registerShakeAndPlayMeow(replacingIndex: idx)
    }

    private func deleteSelected() {
        guard let id = selectedSpriteID else { return }
        pushUndo()
        sprites.removeAll { $0.id == id }
        selectedSpriteID = sprites.last?.id
    }

    private func pet() {
        SoundPlayer.shared.startPurr()
        SoundPlayer.shared.stopPurr(after: 1.5)
    }

    private func handleShake() {
        dismissHint()
        guard let id = selectedSpriteID, let idx = sprites.firstIndex(where: { $0.id == id }) else {
            addKitten()
            return
        }
        registerShakeAndPlayMeow(replacingIndex: idx)
    }

    /// Swaps the sprite at `idx` for a new random kitten and plays a meow.
    /// Tracks recent shake timestamps so rapid, repeated shaking triggers
    /// the "annoyed" meow variant instead of a normal one.
    private func registerShakeAndPlayMeow(replacingIndex idx: Int) {
        pushUndo()
        let now = Date()
        shakeTimestamps.append(now)
        shakeTimestamps = shakeTimestamps.filter { now.timeIntervalSince($0) < 1.5 }
        let annoyed = shakeTimestamps.count >= 3

        sprites[idx].imageName = KittenCatalog.randomKittenImageName(excluding: sprites[idx].imageName)
        SoundPlayer.shared.playRandomMeow(annoyed: annoyed)
    }

    private func flattenedImage() -> UIImage {
        ImageExporter.renderFlattenedImage(
            background: backgroundImage,
            sprites: sprites,
            kittenImage: { image(for: $0) },
            includeWatermark: !entitlements.isSubscriber
        )
    }

    private func saveToPhotos() {
        let image = flattenedImage()
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        CreationStore.shared.save(image)
        path.append(.result(ImageBox(image)))
    }

    private func exportAndShowResult() {
        let image = flattenedImage()
        CreationStore.shared.save(image)
        path.append(.result(ImageBox(image)))
    }
}
