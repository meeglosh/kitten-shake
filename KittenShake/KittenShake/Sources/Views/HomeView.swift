import SwiftUI
import PhotosUI

/// Owns the Home tab's navigation stack so the photo flow (pick → crop →
/// edit → result) can pop all the way back to the Home root from anywhere
/// ("Create Another" / "Back to Home").
struct HomeContainerView: View {
    @State private var path: [HomeRoute]
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    @StateObject private var scene = EditorScene()

    init() {
        var initialPath: [HomeRoute] = []
        var seededScene: EditorScene?

        switch UITestSupport.screen {
        case "getstarted":
            initialPath = [.getStarted]
        case "camera":
            initialPath = [.camera]
        case "shakereview":
            if let sample = ResourceLocator.image(named: "kitten_01") {
                let s = EditorScene()
                s.reset(background: sample)
                seededScene = s
            }
            initialPath = [.shakeReview]
        case "position":
            if let sample = ResourceLocator.image(named: "kitten_01") {
                let s = EditorScene()
                s.seedForDebug(background: sample)
                seededScene = s
            }
            initialPath = [.position]
        case "buildscene":
            if let sample = ResourceLocator.image(named: "kitten_01") {
                let s = EditorScene()
                s.seedForDebug(background: sample)
                s.addSprite(imageName: "kitten_05", normalizedPosition: CGPoint(x: 0.32, y: 0.34), scale: 0.9)
                seededScene = s
            }
            initialPath = [.buildScene]
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
                initialPath = [.result(ImageBox(flattened))]
            }
        default:
            break
        }

        _path = State(initialValue: initialPath)
        if let seededScene {
            _scene = StateObject(wrappedValue: seededScene)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path, showOnboarding: $showOnboarding)
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .getStarted:
                        GetStartedView(path: $path)
                    case .camera:
                        CameraCaptureView(path: $path) { image in
                            path.append(.crop(ImageBox(image)))
                        }
                    case .crop(let box):
                        CropView(sourceImage: box.image, path: $path)
                    case .shakeReview:
                        ShakeReviewView(path: $path)
                    case .position:
                        PositionModeView(path: $path)
                    case .buildScene:
                        BuildSceneView(path: $path)
                    case .result(let box):
                        ResultView(finalImage: box.image, path: $path)
                    }
                }
        }
        .environmentObject(scene)
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
    @EnvironmentObject private var scene: EditorScene

    @AppStorage("ks.hasCompletedGetStarted") private var hasCompletedGetStarted = false
    @State private var showPhotoPicker = false
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            KSScreenBackground()

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        header
                            .scaleEffect(0.9)
                            .frame(height: 52)

                        heroCard
                            .frame(height: proxy.size.height * 0.33)

                        VStack(spacing: -2) {
                            Text("Shake photos.")
                                .foregroundStyle(KSTheme.textPrimary)
                            Text("Add kittens.")
                                .foregroundStyle(KSTheme.accentDeep)
                            HStack(spacing: 6) {
                                Text("Smile.")
                                    .foregroundStyle(KSTheme.textPrimary)
                                Image(systemName: "sparkle")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(KSTheme.gold)
                            }
                        }
                        .font(KSTheme.display(30, weight: .black))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)

                        VStack(spacing: 10) {
                            Button {
                                SoundPlayer.shared.playClick()
                                startPhotoFlow(preferCamera: true)
                            } label: {
                                HStack(spacing: 10) {
                                    KSIconTile(fill: .white) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(KSTheme.accent)
                                    }
                                    Text("Take Photo")
                                }
                            }
                            .buttonStyle(.ksPrimary)

                            Button {
                                SoundPlayer.shared.playClick()
                                startPhotoFlow(preferCamera: false)
                            } label: {
                                HStack(spacing: 10) {
                                    KSIconTile(fill: KSTheme.peach) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(KSTheme.accent)
                                    }
                                    Text("Choose from Library")
                                }
                            }
                            .buttonStyle(.ksSecondary)
                        }
                        .padding(.horizontal, KSTheme.spacingM)
                        .padding(.top, 6)

                        Button {
                            showOnboarding = true
                        } label: {
                            Label("How it works", systemImage: "chevron.right")
                                .labelStyle(.trailingIcon)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KSTheme.accent)
                        }
                        .padding(.top, 2)
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal, KSTheme.spacingL)
                    .padding(.top, KSTheme.spacingS)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
            }
            .ksReadableWidth()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photosPickerItem, matching: .images)
        .onChange(of: photosPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    beginScene(with: uiImage)
                }
                photosPickerItem = nil
            }
        }
    }

    /// First run: intercept with Get Started (permissions/explainer) before
    /// touching the camera or photo picker. After that's been completed
    /// once, go straight to the requested source, matching the pre-redesign
    /// behavior.
    private func startPhotoFlow(preferCamera: Bool) {
        guard hasCompletedGetStarted else {
            path.append(.getStarted)
            return
        }
        if preferCamera {
            path.append(.camera)
        } else {
            showPhotoPicker = true
        }
    }

    private func beginScene(with image: UIImage) {
        path.append(.crop(ImageBox(image)))
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
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                Image("HomeHeroSample")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                            .stroke(KSTheme.cardBorder, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 10)

                ZStack {
                    Circle().fill(KSTheme.peach).frame(width: 56, height: 56)
                    Image(systemName: "heart.fill")
                        .foregroundStyle(KSTheme.accent)
                }
                .overlay(Circle().stroke(KSTheme.surface, lineWidth: 3))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                .offset(x: -12, y: 12)
            }
            .overlay(alignment: .leading) {
                HeroRadiatingDashes(pointingRight: false)
                    .offset(x: -22)
            }
            .overlay(alignment: .trailing) {
                HeroRadiatingDashes(pointingRight: true)
                    .offset(x: 22)
            }
        }
    }
}

/// Small coral icon tile used behind the Home buttons' glyphs (camera / photo
/// library), matching the mockup's rounded-square icon chips.
private struct KSIconTile<Content: View>: View {
    var fill: Color
    var size: CGFloat = 30
    @ViewBuilder var content: Content

    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(fill)
            .frame(width: size, height: size)
            .overlay(content)
    }
}

/// Three short coral dash marks radiating outward at hero-card mid-height,
/// echoing the mockup's "sparkle burst" accents on either side of the photo.
private struct HeroRadiatingDashes: View {
    var pointingRight: Bool

    var body: some View {
        VStack(spacing: 6) {
            dash(length: 14)
            dash(length: 20)
            dash(length: 14)
        }
        .frame(width: 16, height: 46)
    }

    private func dash(length: CGFloat) -> some View {
        Capsule()
            .fill(KSTheme.accent.opacity(0.6))
            .frame(width: 3, height: length)
            .rotationEffect(.degrees(pointingRight ? 24 : -24))
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
