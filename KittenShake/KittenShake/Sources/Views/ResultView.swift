import SwiftUI

/// Shown after a Save or Share completes in the editor: a celebratory
/// preview of the flattened image with quick follow-up actions.
struct ResultView: View {
    let finalImage: UIImage
    @Binding var path: [HomeRoute]

    @State private var showShareSheet = false
    @State private var savedToast = false

    private let confettiColors: [Color] = [
        KSTheme.accent, KSTheme.gold, .blue.opacity(0.6), .purple.opacity(0.6), .green.opacity(0.5)
    ]

    var body: some View {
        ZStack {
            KSTheme.background.ignoresSafeArea()

            confettiOverlay

            ScrollView {
                VStack(spacing: KSTheme.spacingL) {
                    KittenShakeWordmark(logoSize: 36, titleSize: 24)
                        .padding(.top, KSTheme.spacingM)

                    Text("Your kitten masterpiece is ready!")
                        .font(KSTheme.display(28))
                        .foregroundStyle(KSTheme.textPrimary)
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

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: KSTheme.spacingM) {
                        Button {
                            SoundPlayer.shared.playClick()
                            saveToPhotos()
                        } label: {
                            Label("Save to Photos", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.ksSecondary)

                        Button {
                            SoundPlayer.shared.playClick()
                            showShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.ksSecondary)
                    }
                    .padding(.horizontal, KSTheme.spacingM)

                    Button {
                        SoundPlayer.shared.playClick()
                        path.removeAll()
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
                    .padding(.bottom, KSTheme.spacingL)
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
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [finalImage])
        }
        .animation(.spring(duration: 0.35), value: savedToast)
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
}
