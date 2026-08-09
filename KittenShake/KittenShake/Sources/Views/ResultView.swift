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
    @State private var confettiVisible = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            KSScreenBackground()

            confettiOverlay

            VStack(spacing: KSTheme.spacingS) {
                KittenShakeWordmark(logoSize: 32, titleSize: 21)

                headline

                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: finalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                                .stroke(KSTheme.cardBorder, lineWidth: 4)
                        )
                        .shadow(color: .black.opacity(0.14), radius: 16, y: 10)

                    ZStack {
                        Circle().fill(KSTheme.peach).frame(width: 52, height: 52)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(KSTheme.accent)
                    }
                    .overlay(Circle().stroke(KSTheme.surface, lineWidth: 3))
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                    .offset(x: 14, y: 14)
                }
                .padding(.horizontal, KSTheme.spacingM)
                .padding(.top, KSTheme.spacingXS)

                quickTileGrid
                    .padding(.horizontal, KSTheme.spacingM)
                    .padding(.top, KSTheme.spacingS)

                Button {
                    SoundPlayer.shared.playClick()
                    createAnother()
                } label: {
                    Label("Create Another", systemImage: "wand.and.stars")
                }
                .buttonStyle(.ksPrimary)
                .padding(.horizontal, KSTheme.spacingM)
                .padding(.top, KSTheme.spacingS)

                Button {
                    path.removeAll()
                } label: {
                    Text("Back to Home")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KSTheme.accent)
                }
                .padding(.top, KSTheme.spacingXS)
            }
            .padding(.top, KSTheme.spacingS)
            .padding(.bottom, KSTheme.spacingS)
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
        .onAppear {
            TabBarVisibility.shared.isHidden = true
            withAnimation(.easeOut(duration: 0.5).delay(0.05)) {
                confettiVisible = true
            }
        }
        .onDisappear {
            TabBarVisibility.shared.isHidden = false
        }
    }

    /// "Your kitten masterpiece is ready!" set at display scale across two
    /// fixed lines (mirroring the mockup's manual break rather than relying
    /// on text wrap), with "ready!" picked out in `accentDeep`.
    private var headline: some View {
        VStack(spacing: -4) {
            Text("Your kitten")
                .foregroundStyle(KSTheme.textPrimary)
            HStack(spacing: 8) {
                Text("masterpiece is")
                    .foregroundStyle(KSTheme.textPrimary)
                Text("ready!")
                    .foregroundStyle(KSTheme.accentDeep)
            }
        }
        .font(KSTheme.display(30, weight: .black))
        .minimumScaleFactor(0.85)
        .lineLimit(1)
        .multilineTextAlignment(.center)
        .padding(.horizontal, KSTheme.spacingM)
    }

    private var quickTileGrid: some View {
        VStack(spacing: KSTheme.spacingM) {
            HStack(spacing: KSTheme.spacingM) {
                verticalTile(title: "Save to Photos") {
                    simpleIcon("square.and.arrow.down.fill", tint: KSTheme.accent)
                } action: {
                    saveToPhotos()
                }
                verticalTile(title: "Share") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(KSTheme.accent)
                        .frame(width: 34, height: 34)
                } action: {
                    showShareSheet = true
                }
            }
            HStack(spacing: KSTheme.spacingM) {
                horizontalTile(title: "Messages") {
                    messagesIcon
                } action: {
                    shareToMessages()
                }
                horizontalTile(title: "Instagram") {
                    instagramIcon
                } action: {
                    shareToInstagram()
                }
            }
        }
    }

    private func simpleIcon(_ systemName: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint)
                .frame(width: 34, height: 34)
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    /// A plain (no background tile) green speech-bubble glyph, matching the
    /// mockup's flat Messages icon rather than a boxed system icon.
    private var messagesIcon: some View {
        Image(systemName: "message.fill")
            .font(.system(size: 28))
            .foregroundStyle(Color(red: 0.2, green: 0.82, blue: 0.36))
            .frame(width: 34, height: 34)
    }

    private var instagramIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
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

    /// Top-row tile style: icon above label, matching the mockup's Save to
    /// Photos / Share tiles.
    private func verticalTile(
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
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: KSTheme.controlRadius, style: .continuous)
                    .fill(KSTheme.surface)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    /// Bottom-row tile style: shorter, icon left / label right, matching the
    /// mockup's Messages / Instagram tiles.
    private func horizontalTile(
        title: String,
        @ViewBuilder icon: () -> some View,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            SoundPlayer.shared.playClick()
            action()
        } label: {
            HStack(spacing: 12) {
                icon()
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KSTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, KSTheme.spacingM)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: KSTheme.controlRadius, style: .continuous)
                    .fill(KSTheme.surface)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    /// A fixed, hand-placed scatter of confetti pieces (small rounded
    /// rectangles) and gold sparkles echoing the mockup's celebratory
    /// density around the headline and down both flanks of the photo card —
    /// static rather than randomized so the layout reliably matches the
    /// reference, with a light one-shot fade/scale entrance.
    private var confettiOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                ForEach(Array(ConfettiPiece.layout.enumerated()), id: \.offset) { _, piece in
                    piece.shape(dark: colorScheme == .dark)
                        .position(x: piece.x * w, y: piece.y * h)
                }
            }
            .opacity(confettiVisible ? 1 : 0)
            .scaleEffect(confettiVisible ? 1 : 0.6)
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

/// One decorative confetti piece: either a small rotated rounded rectangle
/// or a four-point sparkle, placed at a fixed position (normalized 0...1 so
/// it scales to any screen size) picked to echo the mockup's scatter around
/// the headline and down both sides of the photo card.
private struct ConfettiPiece {
    enum Kind { case rect, sparkle }

    let x: CGFloat
    let y: CGFloat
    let kind: Kind
    let color: Color
    let rotation: Double
    let size: CGFloat

    @ViewBuilder
    func shape(dark: Bool) -> some View {
        let opacity = dark ? 0.9 : 0.65
        switch kind {
        case .rect:
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: size, height: size * 1.75)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
        case .sparkle:
            Image(systemName: "sparkle")
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(KSTheme.gold)
                .opacity(dark ? 1 : 0.8)
        }
    }

    /// Mockup pastel palette: coral, gold, lavender, mint, sky blue.
    private static let coral = KSTheme.accent
    private static let gold = KSTheme.gold
    private static let lavender = Color(red: 0.68, green: 0.56, blue: 0.86)
    private static let mint = Color(red: 0.53, green: 0.81, blue: 0.64)
    private static let sky = Color(red: 0.47, green: 0.68, blue: 0.93)

    static let layout: [ConfettiPiece] = [
        // Flanking the wordmark/headline.
        ConfettiPiece(x: 0.10, y: 0.045, kind: .rect, color: coral, rotation: -35, size: 9),
        ConfettiPiece(x: 0.18, y: 0.075, kind: .rect, color: gold, rotation: 20, size: 8),
        ConfettiPiece(x: 0.07, y: 0.10, kind: .rect, color: sky, rotation: -50, size: 8),
        ConfettiPiece(x: 0.09, y: 0.135, kind: .sparkle, color: gold, rotation: 0, size: 14),
        ConfettiPiece(x: 0.90, y: 0.05, kind: .rect, color: sky, rotation: 25, size: 9),
        ConfettiPiece(x: 0.91, y: 0.085, kind: .rect, color: lavender, rotation: -20, size: 8),
        ConfettiPiece(x: 0.81, y: 0.10, kind: .sparkle, color: gold, rotation: 0, size: 12),
        ConfettiPiece(x: 0.89, y: 0.135, kind: .rect, color: gold, rotation: 15, size: 7),

        // Down the left flank of the photo card.
        ConfettiPiece(x: 0.055, y: 0.30, kind: .rect, color: sky, rotation: -20, size: 8),
        ConfettiPiece(x: 0.045, y: 0.36, kind: .rect, color: gold, rotation: 30, size: 8),
        ConfettiPiece(x: 0.06, y: 0.415, kind: .rect, color: lavender, rotation: -15, size: 8),
        ConfettiPiece(x: 0.07, y: 0.475, kind: .sparkle, color: gold, rotation: 0, size: 13),

        // Down the right flank of the photo card.
        ConfettiPiece(x: 0.935, y: 0.275, kind: .rect, color: mint, rotation: 20, size: 7),
        ConfettiPiece(x: 0.925, y: 0.335, kind: .rect, color: sky, rotation: -25, size: 8),
        ConfettiPiece(x: 0.94, y: 0.39, kind: .rect, color: coral, rotation: 15, size: 8),
        ConfettiPiece(x: 0.94, y: 0.45, kind: .rect, color: gold, rotation: -30, size: 7)
    ]
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
