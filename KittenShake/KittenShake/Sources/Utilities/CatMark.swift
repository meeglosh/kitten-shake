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
        p.move(to: pt(13, 40))
        p.addCurve(to: pt(7, 8), control1: pt(9, 29), control2: pt(7, 18))
        p.addCurve(to: pt(34, 26), control1: pt(9, 19), control2: pt(21, 23))
        p.addCurve(to: pt(50, 32), control1: pt(43, 29), control2: pt(46, 31))
        p.addCurve(to: pt(66, 26), control1: pt(54, 31), control2: pt(57, 29))
        p.addCurve(to: pt(93, 8), control1: pt(79, 23), control2: pt(91, 19))
        p.addCurve(to: pt(87, 40), control1: pt(93, 18), control2: pt(91, 29))
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
            p.move(to: pt(13, 41))
            p.addCurve(to: pt(6, 58), control1: pt(8, 48), control2: pt(6, 52))
        } else {
            p.move(to: pt(87, 41))
            p.addCurve(to: pt(94, 58), control1: pt(92, 48), control2: pt(94, 52))
        }
        return p
    }
}

private struct CatSmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 100
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.move(to: pt(6, 60))
        p.addCurve(to: pt(50, 90), control1: pt(8, 77), control2: pt(27, 90))
        p.addCurve(to: pt(94, 60), control1: pt(73, 90), control2: pt(92, 77))
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
            let lw = w * 0.062
            ZStack {
                CatBrowAndEars().stroke(strokeColor, style: strokeStyle(lw))
                CatCheekStroke(left: true).stroke(strokeColor, style: strokeStyle(lw))
                CatCheekStroke(left: false).stroke(strokeColor, style: strokeStyle(lw))
                CatSmileArc().stroke(strokeColor, style: strokeStyle(lw))

                // Rosy cheek dots, mirrored left/right, sitting just below
                // and outside the eyes for a happy, blush-y look.
                Circle().fill(strokeColor.opacity(0.55))
                    .frame(width: w * 0.1, height: w * 0.1)
                    .position(x: w * 0.21, y: w * 0.635)
                Circle().fill(strokeColor.opacity(0.55))
                    .frame(width: w * 0.1, height: w * 0.1)
                    .position(x: w * 0.79, y: w * 0.635)

                // Big, round, friendly dark-filled eyes with a bright white
                // highlight dot, mirrored left/right.
                Group {
                    Circle().fill(inkColor)
                        .frame(width: w * 0.15, height: w * 0.15)
                        .position(x: w * 0.365, y: w * 0.495)
                    Circle().fill(.white)
                        .frame(width: w * 0.045, height: w * 0.045)
                        .position(x: w * 0.336, y: w * 0.465)
                }
                Group {
                    Circle().fill(inkColor)
                        .frame(width: w * 0.15, height: w * 0.15)
                        .position(x: w * 0.635, y: w * 0.495)
                    Circle().fill(.white)
                        .frame(width: w * 0.045, height: w * 0.045)
                        .position(x: w * 0.606, y: w * 0.465)
                }

                Path { p in
                    let cx = w * 0.5, cy = w * 0.575, hw = w * 0.026, hh = w * 0.024
                    p.move(to: CGPoint(x: cx - hw, y: cy - hh))
                    p.addQuadCurve(to: CGPoint(x: cx + hw, y: cy - hh), control: CGPoint(x: cx, y: cy - hh * 1.6))
                    p.addQuadCurve(to: CGPoint(x: cx, y: cy + hh), control: CGPoint(x: cx + hw * 0.3, y: cy + hh * 0.3))
                    p.addQuadCurve(to: CGPoint(x: cx - hw, y: cy - hh), control: CGPoint(x: cx - hw * 0.3, y: cy + hh * 0.3))
                }
                .fill(inkColor)

                // Wide, open, happy smile: a broad U with an upturned grin
                // at each corner instead of the previous tight closed-mouth
                // curve, plus a small tongue-peek dimple.
                Path { p in
                    let cx = w * 0.5, cy = w * 0.615
                    p.move(to: CGPoint(x: cx - w * 0.09, y: cy - w * 0.01))
                    p.addQuadCurve(to: CGPoint(x: cx, y: cy + w * 0.075), control: CGPoint(x: cx - w * 0.05, y: cy + w * 0.075))
                    p.addQuadCurve(to: CGPoint(x: cx + w * 0.09, y: cy - w * 0.01), control: CGPoint(x: cx + w * 0.05, y: cy + w * 0.075))
                }
                .stroke(inkColor, style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round, lineJoin: .round))

                ForEach(0..<3) { i in
                    let yOff = (CGFloat(i) - 1) * w * 0.06
                    Path { p in
                        p.move(to: CGPoint(x: -w * 0.12, y: w * 0.53 + yOff))
                        p.addLine(to: CGPoint(x: w * 0.24, y: w * 0.53 + yOff * 0.5))
                    }
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: w * 0.015, lineCap: .round))
                    Path { p in
                        p.move(to: CGPoint(x: w * 1.12, y: w * 0.53 + yOff))
                        p.addLine(to: CGPoint(x: w * 0.76, y: w * 0.53 + yOff * 0.5))
                    }
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: w * 0.015, lineCap: .round))
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
