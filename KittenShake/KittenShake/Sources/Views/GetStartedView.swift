import SwiftUI
import AVFoundation
import Photos
import PhotosUI

/// First-run interception screen shown the very first time the user taps
/// Take Photo / Choose Library from Home: explains the flow, lets the user
/// pick a source, and surfaces live camera/photo-library permission status.
/// Once `hasCompletedGetStarted` is set, Home skips straight to
/// camera/picker on subsequent launches.
struct GetStartedView: View {
    @Binding var path: [HomeRoute]
    @AppStorage("ks.hasCompletedGetStarted") private var hasCompletedGetStarted = false

    enum Source { case camera, library }

    @State private var selectedSource: Source = .camera
    @State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Environment(\.scenePhase) private var scenePhase

    @State private var showPhotoPicker = false
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            KSScreenBackground()

            ScrollView {
                VStack(spacing: KSTheme.spacingL) {
                    header

                    VStack(spacing: 6) {
                        HStack(spacing: 10) {
                            burst(flip: false)
                            Text("Get started")
                                .font(KSTheme.display(40))
                                .foregroundStyle(KSTheme.textPrimary)
                            burst(flip: true)
                        }
                        Text("Snap a new photo or pick one from your library, then shake to add a surprise kitten.")
                            .font(.subheadline)
                            .foregroundStyle(KSTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, KSTheme.spacingM)
                    }

                    VStack(spacing: 14) {
                        sourceRow(
                            icon: "camera.fill",
                            title: "Camera",
                            subtitle: "Snap a new photo",
                            isSelected: selectedSource == .camera
                        ) { selectedSource = .camera }

                        sourceRow(
                            icon: "photo.on.rectangle",
                            title: "Photo Library",
                            subtitle: "Choose from your photos",
                            isSelected: selectedSource == .library
                        ) { selectedSource = .library }
                    }
                    .padding(.horizontal, KSTheme.spacingM)

                    permissionsCard
                        .padding(.horizontal, KSTheme.spacingM)

                    Button {
                        SoundPlayer.shared.playClick()
                        proceed()
                    } label: {
                        Label("Continue", systemImage: "sparkles")
                    }
                    .buttonStyle(.ksPrimary)
                    .padding(.horizontal, KSTheme.spacingM)

                    Button {
                        path.removeAll()
                    } label: {
                        Text("Not now")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KSTheme.accent)
                    }
                    // Pushed `navigationDestination` content doesn't reliably
                    // inherit the floating `KSTabBar`'s `safeAreaInset` from
                    // `RootView` (unlike the NavigationStack's root, e.g.
                    // Home), so without explicit clearance here this link
                    // ends up laid out behind the tab bar. Reserve enough
                    // room for the tab bar's rendered height plus its own
                    // margins so "Not now" is always fully visible above it.
                    .padding(.bottom, KSTheme.flowBottomClearance)
                }
                .padding(.top, KSTheme.spacingM)
            }
            .ksReadableWidth()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshStatuses)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshStatuses() }
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
        BrandHeader()
            .overlay(alignment: .topLeading) {
                SparkleAccent(systemName: "heart.fill", color: KSTheme.accent.opacity(0.55), size: 16)
                    .offset(x: -8, y: -2)
            }
            .overlay(alignment: .topTrailing) {
                SparkleAccent(color: KSTheme.gold, size: 18)
                    .offset(x: 8, y: -2)
            }
    }

    private func burst(flip: Bool) -> some View {
        VStack(spacing: 3) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(KSTheme.accent.opacity(0.7))
                    .frame(width: 16 - CGFloat(i) * 3, height: 3)
            }
        }
        .rotationEffect(.degrees(flip ? -35 : 35))
    }

    private func sourceRow(
        icon: String,
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            SoundPlayer.shared.playClick()
            action()
        }) {
            KSCard(padding: KSTheme.spacingM) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(KSTheme.accent.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundStyle(KSTheme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(KSTheme.display(19))
                            .foregroundStyle(KSTheme.textPrimary)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(KSTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(KSTheme.accent)
                }
            }
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                .stroke(isSelected ? KSTheme.accent : Color.clear, lineWidth: 2)
        )
    }

    private var permissionsCard: some View {
        KSCard(padding: KSTheme.spacingM) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Permissions")
                    .font(KSTheme.display(18))
                    .foregroundStyle(KSTheme.textPrimary)
                    .padding(.bottom, KSTheme.spacingS)

                permissionRow(
                    icon: "camera.fill",
                    title: "Camera access",
                    subtitle: "Allow access to take photos with your camera.",
                    isGranted: cameraStatus == .authorized,
                    isDenied: cameraStatus == .denied || cameraStatus == .restricted
                ) { requestCameraAccess() }

                Divider().padding(.vertical, 10)

                permissionRow(
                    icon: "photo.on.rectangle",
                    title: "Photos access",
                    subtitle: "Allow access to your photo library.",
                    isGranted: photoStatus == .authorized || photoStatus == .limited,
                    isDenied: photoStatus == .denied || photoStatus == .restricted
                ) { requestPhotoAccess() }
            }
        }
    }

    private func permissionRow(
        icon: String,
        title: String,
        subtitle: String,
        isGranted: Bool,
        isDenied: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            if isGranted { return }
            SoundPlayer.shared.playClick()
            if isDenied {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } else {
                action()
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(KSTheme.accent.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundStyle(KSTheme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KSTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(KSTheme.textSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(isGranted ? KSTheme.accent : Color.clear)
                        .overlay(Circle().stroke(KSTheme.textSecondary.opacity(isGranted ? 0 : 0.3), lineWidth: 1.5))
                        .frame(width: 30, height: 30)
                    if isGranted {
                        Image(systemName: "checkmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func refreshStatuses() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async { refreshStatuses() }
        }
    }

    private func requestPhotoAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
            DispatchQueue.main.async { refreshStatuses() }
        }
    }

    private func proceed() {
        hasCompletedGetStarted = true
        switch selectedSource {
        case .camera:
            path.append(.camera)
        case .library:
            showPhotoPicker = true
        }
    }
}
