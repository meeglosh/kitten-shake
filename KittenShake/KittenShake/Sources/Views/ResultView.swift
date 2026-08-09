import SwiftUI
import MessageUI

/// Shown after Build Scene's Save completes: a celebratory preview of the
/// flattened image plus a 2x2 quick-share tile grid (mockup 8) — Save to
/// Photos, system Share, Messages (MFMessageComposeViewController), and
/// Instagram (pasteboard hand-off to `instagram://app`, falling back to the
/// system share sheet when either integration isn't available).
struct ResultView: View {
    let finalImage: UIImage
    @Binding var path: [HomeRoute]
    @AppStorage("ks.hasCompletedGetStarted") private var hasCompletedGetStarted = false

    @State private var showShareSheet = false
    @State private var showMessageCompose = false
    @State private var savedToast = false

    private let confettiColors: [Color] = [
        KSTheme.accent, KSTheme.gold, .blue.opacity(0.6), .purple.opacity(0.6), .green.opacity(0.5)
    ]

    var body: some View {
        ZStack {
            KSScreenBackground()

            confettiOverlay

            ScrollView {
                VStack(spacing: KSTheme.spacingL) {
                    KittenShakeWordmark(logoSize: 36, titleSize: 24)
                        .padding(.top, KSTheme.spacingM)

                    (
                        Text("Your kitten masterpiece is ")
                            .foregroundStyle(KSTheme.textPrimary)
                        + Text("ready!")
                            .foregroundStyle(KSTheme.accent)
                    )
                    .font(KSTheme.display(28))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KSTheme.spacingL)

                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: finalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 320)
                            .clipShape(RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                                    .stroke(KSTheme.cardBorder, lineWidth: 4)
                            )
                            .shadow(color: .black.opacity(0.14), radius: 16, y: 10)

                        ZStack {
                            Circle().fill(KSTheme.surface).frame(width: 48, height: 48)
                            Image(systemName: "heart.fill").foregroundStyle(KSTheme.accent)
                        }
                        .shadow(radius: 4)
                        .padding(12)
                    }
                    .padding(.horizontal, KSTheme.spacingM)

                    quickTileGrid
                        .padding(.horizontal, KSTheme.spacingM)

                    Button {
                        SoundPlayer.shared.playClick()
                        createAnother()
                    } label: {
                        Label("Create Another", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.ksPrimary)
                    .padding(.horizontal, KSTheme.spacingM)

                    Button {
                        path.removeAll()
                    } label: {
                        Text("Back to Home")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KSTheme.accent)
                    }
                    .padding(.bottom, KSTheme.flowBottomClearance)
                }
            }
            .ksReadableWidth()

            if savedToast {
                VStack {
                    Text("Saved to Photos!")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(KSTheme.textPrimary, in: Capsule())
                        .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [finalImage])
        }
        .sheet(isPresented: $showMessageCompose) {
            MessageComposeView(image: finalImage) { showMessageCompose = false }
        }
        .animation(.spring(duration: 0.35), value: savedToast)
    }

    private var quickTileGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: KSTheme.spacingM) {
            quickTile(title: "Save to Photos") {
                simpleIcon("square.and.arrow.down.fill", tint: KSTheme.accent)
            } action: {
                saveToPhotos()
            }
            quickTile(title: "Share") {
                simpleIcon("square.and.arrow.up", tint: KSTheme.accent)
            } action: {
                showShareSheet = true
            }
            quickTile(title: "Messages") {
                messagesIcon
            } action: {
                shareToMessages()
            }
            quickTile(title: "Instagram") {
                instagramIcon
            } action: {
                shareToInstagram()
            }
        }
    }

    private func simpleIcon(_ systemName: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.15))
                .frame(width: 34, height: 34)
            Image(systemName: systemName)
                .font(.system(size: 16))
                .foregroundStyle(tint)
        }
    }

    private var messagesIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.2, green: 0.82, blue: 0.36))
                .frame(width: 34, height: 34)
            Image(systemName: "message.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white)
        }
    }

    private var instagramIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.65, blue: 0.14),
                            Color(red: 0.89, green: 0.24, blue: 0.42),
                            Color(red: 0.53, green: 0.16, blue: 0.71)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 34, height: 34)
            Image(systemName: "camera.fill")
                .font(.system(size: 15))
                .foregroundStyle(.white)
        }
    }

    private func quickTile(
        title: String,
        @ViewBuilder icon: () -> some View,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            SoundPlayer.shared.playClick()
            action()
        } label: {
            VStack(spacing: 10) {
                icon()
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KSTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: KSTheme.controlRadius, style: .continuous)
                    .fill(KSTheme.surface)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    private var confettiOverlay: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<18, id: \.self) { i in
                    let seed = Double(i)
                    let x = CGFloat((seed * 53).truncatingRemainder(dividingBy: Double(geo.size.width)))
                    let y = CGFloat((seed * 97).truncatingRemainder(dividingBy: Double(geo.size.height)))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(confettiColors[i % confettiColors.count])
                        .frame(width: 8, height: 14)
                        .rotationEffect(.degrees(seed * 37))
                        .position(x: x, y: y)
                        .opacity(0.55)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func saveToPhotos() {
        UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
        withAnimation { savedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { savedToast = false }
        }
    }

    private func shareToMessages() {
        if MFMessageComposeViewController.canSendText() {
            showMessageCompose = true
        } else {
            showShareSheet = true
        }
    }

    /// Standard "share to Instagram" pattern since the old document-
    /// interaction API was deprecated: write the image to the pasteboard,
    /// then deep-link into the app so the user can paste it into a Story or
    /// post. Falls back to the system share sheet when Instagram isn't
    /// installed.
    private func shareToInstagram() {
        guard let url = URL(string: "instagram://app"), UIApplication.shared.canOpenURL(url) else {
            showShareSheet = true
            return
        }
        UIPasteboard.general.image = finalImage
        UIApplication.shared.open(url)
    }

    private func createAnother() {
        path.removeAll()
        if hasCompletedGetStarted {
            path.append(.camera)
        } else {
            path.append(.getStarted)
        }
    }
}

/// Wraps `MFMessageComposeViewController` to attach the exported image to a
/// new Messages draft.
private struct MessageComposeView: UIViewControllerRepresentable {
    let image: UIImage
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        if let data = image.jpegData(compressionQuality: 0.92) {
            controller.addAttachmentData(data, typeIdentifier: "public.jpeg", filename: "KittenShake.jpg")
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true, completion: onFinish)
        }
    }
}
