import SwiftUI

struct EditorView: View {
    let backgroundImage: UIImage

    @State private var sprites: [KittenSprite] = []
    @State private var selectedSpriteID: UUID?
    @State private var shakeTimestamps: [Date] = []
    @State private var tipIndex = 0
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var savedToast = false
    @State private var kittenImageCache: [String: UIImage] = [:]

    private let tips = AppTips.all
    private let tipTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            tipBanner

            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                ZStack {
                    Image(uiImage: backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: side, height: side)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { selectedSpriteID = nil }

                    ForEach($sprites) { $sprite in
                        KittenSpriteView(
                            sprite: $sprite,
                            canvasSide: side,
                            isSelected: sprite.id == selectedSpriteID,
                            uiImage: image(for: sprite.imageName),
                            onSelect: { selectedSpriteID = sprite.id },
                            onPet: pet
                        )
                    }
                }
                .frame(width: side, height: side)
                .background(ShakeDetectorView(onShake: handleShake))
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .padding()

            toolbar
        }
        .navigationTitle("Kitten Shake")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if sprites.isEmpty { addKitten() }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(activityItems: [shareImage])
            }
        }
        .overlay(alignment: .top) {
            if savedToast {
                Text("Saved to Photos!")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: savedToast)
    }

    private var tipBanner: some View {
        Text(tips[tipIndex])
            .font(.footnote.italic())
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
            .padding(.horizontal, 24)
            .id(tipIndex)
            .transition(.opacity)
            .onReceive(tipTimer) { _ in
                withAnimation { tipIndex = (tipIndex + 1) % tips.count }
            }
    }

    private var toolbar: some View {
        VStack(spacing: 14) {
            HStack(spacing: 28) {
                toolbarButton(icon: "plus.circle.fill", label: "Add", action: addKitten)
                toolbarButton(icon: "shuffle.circle.fill", label: "New Kitten", action: shuffleSelected)
                toolbarButton(icon: "trash.circle.fill", label: "Delete", action: deleteSelected)
                    .disabled(selectedSpriteID == nil)
                    .opacity(selectedSpriteID == nil ? 0.35 : 1.0)
            }

            HStack(spacing: 16) {
                Button {
                    SoundPlayer.shared.playClick()
                    saveToPhotos()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    SoundPlayer.shared.playClick()
                    share()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .disabled(sprites.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private func toolbarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            SoundPlayer.shared.playClick()
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title2)
                Text(label).font(.caption2)
            }
            .frame(minWidth: 64)
        }
    }

    private func image(for name: String) -> UIImage? {
        if let cached = kittenImageCache[name] { return cached }
        guard let loaded = ResourceLocator.image(named: name) else { return nil }
        kittenImageCache[name] = loaded
        return loaded
    }

    private func addKitten() {
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
        sprites.removeAll { $0.id == id }
        selectedSpriteID = sprites.last?.id
    }

    private func pet() {
        SoundPlayer.shared.startPurr()
        SoundPlayer.shared.stopPurr(after: 1.5)
    }

    private func handleShake() {
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
            kittenImage: { image(for: $0) }
        )
    }

    private func saveToPhotos() {
        let image = flattenedImage()
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        withAnimation { savedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { savedToast = false }
        }
    }

    private func share() {
        shareImage = flattenedImage()
        showShareSheet = true
    }
}
