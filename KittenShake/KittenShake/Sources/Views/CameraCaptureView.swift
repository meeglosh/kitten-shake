import SwiftUI
import PhotosUI
import Combine

/// Custom AVFoundation camera screen (mockup 3): full-bleed live preview in
/// a rounded card, a hint pill, and a cream control tray with flash/shutter/
/// flip/library controls. Falls back to a friendly placeholder when the
/// device has no camera (the Simulator) so it never crashes — the Library
/// button keeps working in that state.
struct CameraCaptureView: View {
    @Binding var path: [HomeRoute]
    var onCaptured: (UIImage) -> Void

    @StateObject private var camera = CameraController()
    @Environment(\.dismiss) private var dismiss

    @State private var showPhotoPicker = false
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            KSScreenBackground()

            VStack(spacing: KSTheme.spacingM) {
                topBar

                previewCard
                    .padding(.horizontal, KSTheme.spacingM)

                controlTray
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onReceive(camera.$capturedImage.compactMap { $0 }) { image in
            onCaptured(image)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photosPickerItem, matching: .images)
        .onChange(of: photosPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    onCaptured(uiImage)
                }
                photosPickerItem = nil
            }
        }
    }

    private var topBar: some View {
        HStack {
            CompactCatMark(size: 32)
            Spacer()
            Text("Take Photo")
                .font(KSTheme.display(24))
                .foregroundStyle(KSTheme.textPrimary)
            Spacer()
            Button {
                SoundPlayer.shared.playClick()
                dismiss()
            } label: {
                ZStack {
                    Circle().fill(KSTheme.surface).frame(width: 40, height: 40)
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(KSTheme.textPrimary)
                }
            }
        }
        .padding(.horizontal, KSTheme.spacingM)
        .padding(.top, KSTheme.spacingS)
    }

    private var previewCard: some View {
        ZStack(alignment: .bottom) {
            if camera.isAvailable {
                CameraPreviewView(session: camera.session)
            } else {
                unavailablePlaceholder
            }

            hintPill
                .padding(.bottom, KSTheme.spacingM)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                .stroke(KSTheme.cardBorder, lineWidth: 4)
        )
        .shadow(color: .black.opacity(0.14), radius: 16, y: 8)
    }

    private var unavailablePlaceholder: some View {
        ZStack {
            KSTheme.surface
            VStack(spacing: KSTheme.spacingS) {
                Image(systemName: "cat.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(KSTheme.accent)
                Text("Camera not available in Simulator")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KSTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Use the Library button below instead.")
                    .font(.caption)
                    .foregroundStyle(KSTheme.textSecondary)
            }
            .padding(KSTheme.spacingL)
        }
    }

    private var hintPill: some View {
        KSPill(systemImage: "sparkle", text: "Choose a clear photo with room for kittens.", background: .white.opacity(0.85))
            .padding(.horizontal, KSTheme.spacingM)
    }

    private var controlTray: some View {
        VStack(spacing: KSTheme.spacingM) {
            HStack {
                controlButton(icon: camera.flashMode.systemImage, label: "Flash") {
                    camera.cycleFlash()
                }
                .opacity(camera.isAvailable ? 1 : 0.35)
                .disabled(!camera.isAvailable)

                Spacer()

                shutterButton

                Spacer()

                controlButton(icon: "arrow.triangle.2.circlepath.camera", label: "Flip") {
                    camera.flip()
                }
                .opacity(camera.isAvailable ? 1 : 0.35)
                .disabled(!camera.isAvailable)
            }

            controlButton(icon: "photo.on.rectangle", label: "Library") {
                showPhotoPicker = true
            }
        }
        .padding(.horizontal, KSTheme.spacingXL)
        .padding(.top, KSTheme.spacingL)
        // The tray's background deliberately bleeds to the true screen edge
        // (`.ignoresSafeArea(edges: .bottom)`) for a full-bleed look, but the
        // floating `KSTabBar` (see `RootView`) still renders on top of that
        // region, so the *content* needs its own reserved clearance or the
        // last control row's captions end up covered by the bar.
        .padding(.bottom, KSTheme.flowBottomClearance)
        .frame(maxWidth: .infinity)
        .background(
            KSTheme.surface
                .clipShape(RoundedCorner(radius: 32, corners: [.topLeft, .topRight]))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var shutterButton: some View {
        Button {
            SoundPlayer.shared.playClick()
            camera.capturePhoto()
        } label: {
            ZStack {
                Circle().fill(.white).frame(width: 74, height: 74)
                Circle().stroke(KSTheme.accent, lineWidth: 5).frame(width: 82, height: 82)
            }
        }
        .disabled(!camera.isAvailable)
        .opacity(camera.isAvailable ? 1 : 0.4)
    }

    private func controlButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            SoundPlayer.shared.playClick()
            action()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(KSTheme.background).frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(KSTheme.textPrimary)
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(KSTheme.textPrimary)
            }
        }
    }
}

/// Rounds only specific corners — used for the camera control tray's
/// top-only rounded card.
struct RoundedCorner: Shape {
    var radius: CGFloat = 24
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
