import SwiftUI

/// Renders a single kitten on the canvas and handles its direct-manipulation
/// gestures: drag to move, pinch to scale, two-finger rotate, and tap to pet.
struct KittenSpriteView: View {
    @Binding var sprite: KittenSprite
    let canvasSide: CGFloat
    let isSelected: Bool
    let uiImage: UIImage?
    let onSelect: () -> Void
    let onPet: () -> Void

    @GestureState private var dragDelta: CGSize = .zero
    @GestureState private var pinchDelta: CGFloat = 1.0
    @GestureState private var rotationDelta: Angle = .zero

    var body: some View {
        let baseSize = canvasSide * KittenSprite.defaultSizeFraction

        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.clear
            }
        }
        .frame(width: baseSize, height: baseSize)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
        }
        .scaleEffect(sprite.scale * pinchDelta)
        .rotationEffect(sprite.rotation + rotationDelta)
        .position(
            x: sprite.normalizedPosition.x * canvasSide + dragDelta.width,
            y: sprite.normalizedPosition.y * canvasSide + dragDelta.height
        )
        .gesture(
            SimultaneousGesture(
                SimultaneousGesture(
                    DragGesture(minimumDistance: 2)
                        .updating($dragDelta) { value, state, _ in state = value.translation }
                        .onChanged { _ in onSelect() }
                        .onEnded { value in
                            sprite.normalizedPosition.x += value.translation.width / canvasSide
                            sprite.normalizedPosition.y += value.translation.height / canvasSide
                            clampPosition()
                        },
                    MagnificationGesture()
                        .updating($pinchDelta) { value, state, _ in state = value }
                        .onChanged { _ in onSelect() }
                        .onEnded { value in
                            sprite.scale = min(max(sprite.scale * value, KittenSprite.minScale), KittenSprite.maxScale)
                        }
                ),
                RotationGesture()
                    .updating($rotationDelta) { value, state, _ in state = value }
                    .onChanged { _ in onSelect() }
                    .onEnded { value in
                        sprite.rotation += value
                    }
            )
        )
        .onTapGesture {
            onSelect()
            onPet()
        }
        .animation(.easeOut(duration: 0.15), value: sprite.imageName)
    }

    private func clampPosition() {
        sprite.normalizedPosition.x = min(max(sprite.normalizedPosition.x, 0), 1)
        sprite.normalizedPosition.y = min(max(sprite.normalizedPosition.y, 0), 1)
    }
}
