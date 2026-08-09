import SwiftUI

/// A simple square crop step: the photo fills a square viewport and the
/// user can pan/pinch to choose the crop before continuing to the editor.
struct CropView: View {
    let sourceImage: UIImage

    @State private var scale: CGFloat = 1.0
    @GestureState private var pinchDelta: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var dragDelta: CGSize = .zero
    @State private var navigateToEditor = false
    @State private var croppedImage: UIImage?

    private var viewportSide: CGFloat { UIScreen.main.bounds.width - 40 }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Crop Your Photo")
                    .font(.freckleFace(size: 30))
                Text("Pinch and drag to position your photo")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)

            cropCanvas

            Spacer()

            Button {
                SoundPlayer.shared.playClick()
                crop()
            } label: {
                Text("Use Photo")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToEditor) {
            if let croppedImage {
                EditorView(backgroundImage: croppedImage)
            }
        }
    }

    private var cropCanvas: some View {
        let side = viewportSide
        return Image(uiImage: sourceImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: side, height: side)
            .scaleEffect(scale * pinchDelta)
            .offset(x: offset.width + dragDelta.width, y: offset.height + dragDelta.height)
            .frame(width: side, height: side)
            .clipped()
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 3))
            .shadow(radius: 6)
            .contentShape(Rectangle())
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .updating($dragDelta) { value, state, _ in state = value.translation }
                        .onEnded { value in
                            offset.width += value.translation.width
                            offset.height += value.translation.height
                        },
                    MagnificationGesture()
                        .updating($pinchDelta) { value, state, _ in state = value }
                        .onEnded { value in
                            scale = min(max(scale * value, 1.0), 4.0)
                        }
                )
            )
    }

    private func crop() {
        let side = viewportSide
        let targetSide: CGFloat = max(2048, min(sourceImage.size.width, sourceImage.size.height))
        let renderScale = targetSide / side

        let imageSize = sourceImage.size
        let fillScale = max(side / imageSize.width, side / imageSize.height)
        let displayedWidth = imageSize.width * fillScale * scale
        let displayedHeight = imageSize.height * fillScale * scale

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: targetSide, height: targetSide), format: format)

        let result = renderer.image { _ in
            let drawWidth = displayedWidth * renderScale
            let drawHeight = displayedHeight * renderScale
            let drawX = (targetSide - drawWidth) / 2 + offset.width * renderScale
            let drawY = (targetSide - drawHeight) / 2 + offset.height * renderScale
            sourceImage.draw(in: CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight))
        }

        croppedImage = result
        navigateToEditor = true
    }
}
