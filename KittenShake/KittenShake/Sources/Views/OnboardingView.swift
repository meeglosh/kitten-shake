import SwiftUI

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let body: String
}

/// A skippable, swipeable 4-slide walkthrough shown on first launch and
/// reopenable from Home ("How it works") and Settings ("Replay tutorial").
struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            symbol: "photo.on.rectangle.angled",
            title: "Pick a Photo",
            body: "Snap a new photo or choose one from your library to get started."
        ),
        OnboardingSlide(
            symbol: "iphone.gen3.radiowaves.left.and.right",
            title: "Shake for a Kitten",
            body: "Shake for a new kitten! Don't forget to pet it!"
        ),
        OnboardingSlide(
            symbol: "hand.draw.fill",
            title: "Pet, Pinch & Twirl",
            body: "Pinch your kitten to make it shrink, and use two fingers to twirl it into place."
        ),
        OnboardingSlide(
            symbol: "square.and.arrow.up.on.square.fill",
            title: "Save & Share",
            body: "Save your masterpiece to Photos or share it with the world."
        )
    ]

    var body: some View {
        ZStack {
            KSTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") { onFinish() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KSTheme.accent)
                }
                .padding(.horizontal, KSTheme.spacingL)
                .padding(.top, KSTheme.spacingM)

                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        slideView(slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < slides.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(page < slides.count - 1 ? "Next" : "Get Started")
                }
                .buttonStyle(.ksPrimary)
                .padding(.horizontal, KSTheme.spacingXL)
                .padding(.bottom, KSTheme.spacingL)
            }
            .ksReadableWidth()
        }
    }

    private func slideView(_ slide: OnboardingSlide) -> some View {
        VStack(spacing: KSTheme.spacingL) {
            Spacer()

            ZStack {
                Circle()
                    .fill(KSTheme.accent.opacity(0.14))
                    .frame(width: 200, height: 200)
                Image(systemName: slide.symbol)
                    .font(.system(size: 76, weight: .regular))
                    .foregroundStyle(KSTheme.accent)
                SparkleAccent(color: KSTheme.gold, size: 20)
                    .offset(x: 78, y: -78)
                SparkleAccent(systemName: "heart.fill", color: KSTheme.accent.opacity(0.6), size: 16)
                    .offset(x: -84, y: 70)
            }

            Text(slide.title)
                .font(KSTheme.display(30))
                .foregroundStyle(KSTheme.textPrimary)

            Text(slide.body)
                .font(.body)
                .foregroundStyle(KSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KSTheme.spacingXL)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
