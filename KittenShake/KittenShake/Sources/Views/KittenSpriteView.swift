import SwiftUI

/// The three ways Position Mode's segmented control can constrain a plain
/// one-finger pan gesture on the selected sprite. Pinch-to-zoom and
/// twist-to-rotate always work regardless of this setting — only the plain
/// drag's behavior changes.
enum SpriteTransformMode: CaseIterable {
    case move, scale, rotate

    var label: String {
        switch self {
        case .move: return "Move"
        case .scale: return "Scale"
        case .rotate: return "Rotate"
        }
    }

    var systemImage: String {
        switch self {
        case .move: return "arrow.up.and.down.and.arrow.left.and.right"
        case .scale: return "arrow.up.left.and.arrow.down.right"
        case .rotate: return "arrow.triangle.2.circlepath"
        }
    }
}

/// Renders a single kitten on the canvas and handles its direct-manipulation
/// gestures: drag to move (or scale/rotate, per `constrainedMode`), pinch to
/// scale, two-finger rotate, and tap to pet.
struct KittenSpriteView: View {
    @Binding var sprite: KittenSprite
    let canvasSide: CGFloat
    let isSelected: Bool
    let uiImage: UIImage?
    let onSelect: () -> Void
    let onPet: () -> Void
    var onTransformBegin: () -> Void = {}
    /// When non-nil (Position Mode), constrains what a plain one-finger pan
    /// does: `.move` drags, `.scale` uses vertical pan to scale, `.rotate`
    /// uses horizontal pan to rotate. `nil` (Build Scene / shake-review)
    /// means a plain pan always moves, matching the original editor.
    var constrainedMode: SpriteTransformMode? = nil
    /// Shows the Position Mode selection chrome: white bounding box, coral
    /// corner-handle dots, and a rotate-handle badge below the box.
    var showHandles: Bool = false

    @GestureState private var dragDelta: CGSize = .zero
    @GestureState private var pinchDelta: CGFloat = 1.0
    @GestureState private var rotationDelta: Angle = .zero
    @State private var didBeginTransform = false

    var body: some View {
        let baseSize = canvasSide * KittenSprite.defaultSizeFraction
        let liveScale = sprite.scale * pinchDelta * scaleDragFactor
        let liveRotation = sprite.rotation + rotationDelta + rotateDragAngle

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
            if isSelected && !showHandles {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
        }
        .overlay {
            if showHandles {
                selectionHandles(boxSize: baseSize * liveScale)
            }
        }
        .scaleEffect(liveScale)
        .rotationEffect(liveRotation)
        .position(
            x: sprite.normalizedPosition.x * canvasSide + moveDragOffset.width,
            y: sprite.normalizedPosition.y * canvasSide + moveDragOffset.height
        )
        .gesture(
            SimultaneousGesture(
                SimultaneousGesture(
                    DragGesture(minimumDistance: 2)
                        .updating($dragDelta) { value, state, _ in state = value.translation }
                        .onChanged { _ in beginTransformIfNeeded() }
                        .onEnded { value in applyDragEnd(value.translation) },
                    MagnificationGesture()
                        .updating($pinchDelta) { value, state, _ in state = value }
                        .onChanged { _ in beginTransformIfNeeded() }
                        .onEnded { value in
                            sprite.scale = min(max(sprite.scale * value, KittenSprite.minScale), KittenSprite.maxScale)
                            didBeginTransform = false
                        }
                ),
                RotationGesture()
                    .updating($rotationDelta) { value, state, _ in state = value }
                    .onChanged { _ in beginTransformIfNeeded() }
                    .onEnded { value in
                        sprite.rotation += value
                        didBeginTransform = false
                    }
            )
        )
        .onTapGesture {
            onSelect()
            onPet()
        }
        .animation(.easeOut(duration: 0.15), value: sprite.imageName)
    }

    // MARK: - Constrained-drag math

    /// Plain-pan translation applied as a position move (only when
    /// unconstrained or explicitly in `.move` mode).
    private var moveDragOffset: CGSize {
        guard constrainedMode == nil || constrainedMode == .move else { return .zero }
        return dragDelta
    }

    /// Vertical pan-to-scale factor in `.scale` mode: dragging up grows the
    /// kitten, dragging down shrinks it.
    private var scaleDragFactor: CGFloat {
        guard constrainedMode == .scale else { return 1 }
        let sensitivity: CGFloat = 300
        return max(0.2, 1 - dragDelta.height / sensitivity)
    }

    /// Horizontal pan-to-rotate angle in `.rotate` mode.
    private var rotateDragAngle: Angle {
        guard constrainedMode == .rotate else { return .zero }
        return .degrees(dragDelta.width * 0.6)
    }

    private func applyDragEnd(_ translation: CGSize) {
        switch constrainedMode {
        case .scale:
            let sensitivity: CGFloat = 300
            let factor = max(0.2, 1 - translation.height / sensitivity)
            sprite.scale = min(max(sprite.scale * factor, KittenSprite.minScale), KittenSprite.maxScale)
        case .rotate:
            sprite.rotation += .degrees(translation.width * 0.6)
        case .move, .none:
            sprite.normalizedPosition.x += translation.width / canvasSide
            sprite.normalizedPosition.y += translation.height / canvasSide
            clampPosition()
        }
        didBeginTransform = false
    }

    private func beginTransformIfNeeded() {
        if !didBeginTransform {
            didBeginTransform = true
            onTransformBegin()
        }
        onSelect()
    }

    private func clampPosition() {
        sprite.normalizedPosition.x = min(max(sprite.normalizedPosition.x, 0), 1)
        sprite.normalizedPosition.y = min(max(sprite.normalizedPosition.y, 0), 1)
    }

    /// White bounding box + coral corner dots + rotate-handle badge, matching
    /// Position Mode's mockup selection chrome.
    private func selectionHandles(boxSize: CGFloat) -> some View {
        let corners: [UnitPoint] = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]
        return ZStack {
            RoundedRectangle(cornerRadius: 2)
                .stroke(.white, lineWidth: 2)
                .shadow(color: .black.opacity(0.25), radius: 2)

            GeometryReader { geo in
                ForEach(corners.indices, id: \.self) { i in
                    let point = corners[i]
                    Circle()
                        .fill(KSTheme.accent)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .position(x: geo.size.width * point.x, y: geo.size.height * point.y)
                }
            }

            VStack {
                Spacer()
                ZStack {
                    Circle().fill(.white).frame(width: 32, height: 32)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KSTheme.accent)
                }
                .shadow(color: .black.opacity(0.2), radius: 3)
                .offset(y: 24)
            }
        }
        .frame(width: boxSize, height: boxSize)
    }
}
