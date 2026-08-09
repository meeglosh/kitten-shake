import SwiftUI

// MARK: - Cat mark line-art paths
//
// A resolution-independent recreation of the brand's coral line-art cat
// face: an open "brow + ears" stroke, two short cheek strokes, and one big
// smile arc forming the jaw, plus filled sleepy eyes, a tiny nose, a small
// smile, and three whiskers per side. Tuned against the mockups in
// img/Redesign over several iterations — see BRAND_REVIEW notes in the PR
// description for the comparison history.

private struct CatBrowAndEars: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 100
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.move(to: pt(18, 37))
        p.addCurve(to: pt(13, 10), control1: pt(15, 28), control2: pt(13, 20))
        p.addCurve(to: pt(36, 27), control1: pt(15, 20), control2: pt(24, 24))
        p.addCurve(to: pt(50, 33), control1: pt(44, 30), control2: pt(47, 32))
        p.addCurve(to: pt(64, 27), control1: pt(53, 32), control2: pt(56, 30))
        p.addCurve(to: pt(87, 10), control1: pt(76, 24), control2: pt(85, 20))
        p.addCurve(to: pt(82, 37), control1: pt(87, 20), control2: pt(85, 28))
        return p
    }
}

private struct CatCheekStroke: Shape {
    var left: Bool
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 100
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        if left {
            p.move(to: pt(18, 38))
            p.addCurve(to: pt(10, 56), control1: pt(13, 45), control2: pt(10, 50))
        } else {
            p.move(to: pt(82, 38))
            p.addCurve(to: pt(90, 56), control1: pt(87, 45), control2: pt(90, 50))
        }
        return p
    }
}

private struct CatSmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 100
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.move(to: pt(10, 58))
        p.addCurve(to: pt(50, 84), control1: pt(12, 72), control2: pt(29, 84))
        p.addCurve(to: pt(90, 58), control1: pt(71, 84), control2: pt(88, 72))
        return p
    }
}


/// The brand's cat-face mark: coral line art with warm-ink facial features,
/// drawn as scalable `Shape`s so it stays crisp at any size (compact tab/nav
/// glyph, header logo, or 1024pt app icon).
struct CatMarkView: View {
    var strokeColor: Color = KSTheme.accent
    var inkColor: Color = KSTheme.textPrimary

    private var strokeStyle: StrokeStyle { StrokeStyle(lineWidth: 4.4, lineCap: .round, lineJoin: .round) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let lw = w * 0.044
            ZStack {
                CatBrowAndEars().stroke(strokeColor, style: strokeStyle(lw))
                CatCheekStroke(left: true).stroke(strokeColor, style: strokeStyle(lw))
                CatCheekStroke(left: false).stroke(strokeColor, style: strokeStyle(lw))
                CatSmileArc().stroke(strokeColor, style: strokeStyle(lw))

                // Round, friendly dark-filled eyes with a tiny white
                // highlight dot, mirrored left/right.
                Group {
                    Circle().fill(inkColor)
                        .frame(width: w * 0.1, height: w * 0.1)
                        .position(x: w * 0.375, y: w * 0.5)
                    Circle().fill(.white)
                        .frame(width: w * 0.03, height: w * 0.03)
                        .position(x: w * 0.354, y: w * 0.478)
                }
                Group {
                    Circle().fill(inkColor)
                        .frame(width: w * 0.1, height: w * 0.1)
                        .position(x: w * 0.625, y: w * 0.5)
                    Circle().fill(.white)
                        .frame(width: w * 0.03, height: w * 0.03)
                        .position(x: w * 0.604, y: w * 0.478)
                }

                Path { p in
                    let cx = w * 0.5, cy = w * 0.585, hw = w * 0.026, hh = w * 0.024
                    p.move(to: CGPoint(x: cx - hw, y: cy - hh))
                    p.addQuadCurve(to: CGPoint(x: cx + hw, y: cy - hh), control: CGPoint(x: cx, y: cy - hh * 1.6))
                    p.addQuadCurve(to: CGPoint(x: cx, y: cy + hh), control: CGPoint(x: cx + hw * 0.3, y: cy + hh * 0.3))
                    p.addQuadCurve(to: CGPoint(x: cx - hw, y: cy - hh), control: CGPoint(x: cx - hw * 0.3, y: cy + hh * 0.3))
                }
                .fill(inkColor)

                Path { p in
                    let cx = w * 0.5, cy = w * 0.615
                    p.move(to: CGPoint(x: cx, y: cy))
                    p.addLine(to: CGPoint(x: cx, y: cy + w * 0.02))
                    p.addQuadCurve(to: CGPoint(x: cx - w * 0.055, y: cy + w * 0.03), control: CGPoint(x: cx - w * 0.018, y: cy + w * 0.05))
                    p.move(to: CGPoint(x: cx, y: cy + w * 0.02))
                    p.addQuadCurve(to: CGPoint(x: cx + w * 0.055, y: cy + w * 0.03), control: CGPoint(x: cx + w * 0.018, y: cy + w * 0.05))
                }
                .stroke(inkColor, style: StrokeStyle(lineWidth: w * 0.018, lineCap: .round, lineJoin: .round))

                ForEach(0..<3) { i in
                    let yOff = (CGFloat(i) - 1) * w * 0.055
                    Path { p in
                        p.move(to: CGPoint(x: w * 0.03, y: w * 0.53 + yOff))
                        p.addLine(to: CGPoint(x: w * 0.22, y: w * 0.53 + yOff * 0.55))
                    }
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: w * 0.011, lineCap: .round))
                    Path { p in
                        p.move(to: CGPoint(x: w * 0.97, y: w * 0.53 + yOff))
                        p.addLine(to: CGPoint(x: w * 0.78, y: w * 0.53 + yOff * 0.55))
                    }
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: w * 0.011, lineCap: .round))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func strokeStyle(_ lineWidth: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
    }
}

// MARK: - Brand header

/// The full lockup used as a centered header on most screens: cat mark at
/// left, two-line "Kitten Shake" wordmark at right with a small coral heart
/// accent above it (echoing the mockups' heart-dotted "i").
struct BrandHeader: View {
    var markSize: CGFloat = 64
    var lineSize: CGFloat = 30

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            CatMarkView()
                .frame(width: markSize, height: markSize)

            VStack(alignment: .leading, spacing: -2) {
                // "Kitten" is split so the heart can be pinned directly
                // above the "i" glyph itself (dotting the i) rather than
                // eyeballing an offset across the whole wordmark.
                HStack(spacing: 0) {
                    Text("K")
                    ZStack(alignment: .top) {
                        Text("i")
                        Image(systemName: "heart.fill")
                            .font(.system(size: lineSize * 0.22))
                            .foregroundStyle(KSTheme.accent)
                            .offset(y: -lineSize * 0.14)
                    }
                    Text("tten")
                }
                Text("Shake")
            }
            .font(.fraunces(size: lineSize, weight: .black))
            .foregroundStyle(KSTheme.textPrimary)
        }
    }
}

/// Small standalone cat-mark variant for compact headers (nav bars, sheet
/// title bars) where the full two-line wordmark doesn't fit.
struct CompactCatMark: View {
    var size: CGFloat = 44

    var body: some View {
        CatMarkView()
            .frame(width: size, height: size)
    }
}

#Preview("Brand header") {
    VStack(spacing: 32) {
        BrandHeader()
        CompactCatMark()
    }
    .padding()
    .background(KSTheme.background)
}
