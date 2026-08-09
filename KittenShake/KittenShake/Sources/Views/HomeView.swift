import SwiftUI
import PhotosUI

/// Owns the Home tab's navigation stack so the photo flow (pick → crop →
/// edit → result) can pop all the way back to the Home root from anywhere
/// ("Create Another" / "Back to Home").
struct HomeContainerView: View {
    @State private var path: [HomeRoute]
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    init() {
        switch UITestSupport.screen {
        case "editor":
            if let sample = ResourceLocator.image(named: "kitten_01") {
                _path = State(initialValue: [.editor(ImageBox(sample))])
            } else {
                _path = State(initialValue: [])
            }
        case "editorSeed":
            // Verification-only hook: if a photo has been pushed into the
            // simulator's Documents directory ahead of launch (see the AI
            // kitten / Vision-placement verification flow), use it as the
            // editor background so we can screenshot placement against a
            // real face. Falls back to the bundled sample kitten photo.
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let seedURL = documents.appendingPathComponent("ksSeedPhoto.jpg")
            if let data = try? Data(contentsOf: seedURL), let seeded = UIImage(data: data) {
                _path = State(initialValue: [.editor(ImageBox(seeded))])
            } else if let sample = ResourceLocator.image(named: "kitten_01") {
                _path = State(initialValue: [.editor(ImageBox(sample))])
            } else {
                _path = State(initialValue: [])
            }
        case "result":
            // Renders a real flattened + watermarked export (exercising the
            // same ImageExporter path Save/Share use) so the verification
            // screenshot proves the watermark pipeline, not a raw asset.
            if let background = ResourceLocator.image(named: "kitten_01"),
               let overlay = ResourceLocator.image(named: "kitten_05") {
                let sprite = KittenSprite(imageName: "kitten_05", normalizedPosition: CGPoint(x: 0.7, y: 0.7))
                let flattened = ImageExporter.renderFlattenedImage(
                    background: background,
                    sprites: [sprite],
                    kittenImage: { _ in overlay }
                )
                _path = State(initialValue: [.result(ImageBox(flattened))])
            } else {
                _path = State(initialValue: [])
            }
        default:
            _path = State(initialValue: [])
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path, showOnboarding: $showOnboarding)
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .crop(let box):
                        CropView(sourceImage: box.image, path: $path)
                    case .editor(let box):
                        EditorView(backgroundImage: box.image, path: $path)
                    case .result(let box):
                        ResultView(finalImage: box.image, path: $path)
                    }
                }
        }
        .onAppear {
            if UITestSupport.screen == "onboarding" {
                showOnboarding = true
            } else if UITestSupport.screen == nil && !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }
    }
}

struct HomeView: View {
    @Binding var path: [HomeRoute]
    @Binding var showOnboarding: Bool

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            KSTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: KSTheme.spacingL) {
                    header

                    heroCard

                    VStack(spacing: 6) {
                        Text("Shake photos.")
                            .foregroundStyle(KSTheme.textPrimary)
                        Text("Add kittens.")
                            .foregroundStyle(KSTheme.accent)
                        Text("Smile. ✨")
                            .foregroundStyle(KSTheme.textPrimary)
                    }
                    .font(KSTheme.display(30))
                    .multilineTextAlignment(.center)

                    VStack(spacing: KSTheme.spacingM) {
                        Button {
                            SoundPlayer.shared.playClick()
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showCamera = true
                            } else {
                                showPhotoPicker = true
                            }
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                        }
                        .buttonStyle(.ksPrimary)

                        Button {
                            SoundPlayer.shared.playClick()
                            showPhotoPicker = true
                        } label: {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.ksSecondary)
                    }
                    .padding(.horizontal, KSTheme.spacingM)

                    Button {
                        showOnboarding = true
                    } label: {
                        Label("How it works", systemImage: "chevron.right")
                            .labelStyle(.trailingIcon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KSTheme.accent)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, KSTheme.spacingXL)
                }
                .padding(.horizontal, KSTheme.spacingL)
                .padding(.top, KSTheme.spacingM)
            }
            .ksReadableWidth()
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePickerView(sourceType: .camera) { image in
                showCamera = false
                if let image {
                    path.append(.crop(ImageBox(image)))
                }
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photosPickerItem, matching: .images)
        .onChange(of: photosPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    path.append(.crop(ImageBox(uiImage)))
                }
                photosPickerItem = nil
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            KittenShakeWordmark()
            Spacer()
        }
        .overlay(alignment: .topLeading) {
            SparkleAccent(systemName: "heart.fill", color: KSTheme.accent.opacity(0.55), size: 16)
                .offset(x: 4, y: -6)
        }
        .overlay(alignment: .topTrailing) {
            SparkleAccent(color: KSTheme.gold, size: 18)
                .offset(x: -4, y: -6)
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [KSTheme.accent.opacity(0.35), KSTheme.gold.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(1, contentMode: .fit)
                .frame(maxHeight: 300)
                .overlay {
                    VStack(spacing: 10) {
                        Image(systemName: "cat.fill")
                            .font(.system(size: 64))
                        Text("Your next kitten photo\nstarts here")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                        .stroke(KSTheme.cardBorder, lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.12), radius: 16, y: 10)

            ZStack {
                Circle().fill(KSTheme.surface).frame(width: 56, height: 56)
                Image(systemName: "heart.fill")
                    .foregroundStyle(KSTheme.accent)
            }
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
            .offset(x: -12, y: 12)
        }
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
        }
    }
}

private extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}

#Preview {
    HomeContainerView()
}
