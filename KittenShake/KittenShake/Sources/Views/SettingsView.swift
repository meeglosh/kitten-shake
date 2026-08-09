import SwiftUI

struct SettingsView: View {
    @State private var showOnboarding = false
    @State private var showPaywallForVerification = false

    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KSScreenBackground()

                ScrollView {
                    VStack(spacing: KSTheme.spacingL) {
                        HStack {
                            Text("Settings")
                                .font(KSTheme.display(30))
                                .foregroundStyle(KSTheme.textPrimary)
                            Spacer()
                        }
                        .padding(.top, KSTheme.spacingS)

                        SubscriptionSection()

                        settingsSection(title: "General") {
                            settingsRow(icon: "questionmark.circle.fill", title: "Replay Tutorial") {
                                showOnboarding = true
                            }
                        }

                        settingsSection(title: "About") {
                            settingsInfoRow(icon: "info.circle.fill", title: "Version", value: appVersion)
                            Divider().padding(.leading, 52)
                            settingsInfoRow(
                                icon: "heart.text.square.fill",
                                title: "Credits",
                                value: "Kitten photos used under Creative Commons license."
                            )
                        }

                        Text("Made with ♡ for cat lovers everywhere")
                            .font(.footnote)
                            .foregroundStyle(KSTheme.textSecondary)
                            .padding(.top, KSTheme.spacingM)
                            .padding(.bottom, 110)
                    }
                    .padding(.horizontal, KSTheme.spacingM)
                    .padding(.top, KSTheme.spacingM)
                }
                .ksReadableWidth()
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView { showOnboarding = false }
            }
            .sheet(isPresented: $showPaywallForVerification) {
                PaywallView()
            }
            .onAppear {
                // Verification-only hook (see UITestSupport): jumps straight
                // to the paywall sheet so it can be screenshotted without a
                // real tap on the subscription row.
                if UITestSupport.screen == "paywall" {
                    showPaywallForVerification = true
                }
            }
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: KSTheme.spacingS) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KSTheme.textSecondary)
                .padding(.leading, KSTheme.spacingS)

            VStack(spacing: 0) { content() }
                .background(
                    RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                        .fill(KSTheme.surface)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                )
        }
    }

    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundStyle(KSTheme.accent)
                    .frame(width: 28)
                Text(title)
                    .foregroundStyle(KSTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(KSTheme.textSecondary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, KSTheme.spacingM)
        }
    }

    private func settingsInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(KSTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(KSTheme.textPrimary)
                Text(value)
                    .font(.footnote)
                    .foregroundStyle(KSTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, KSTheme.spacingM)
    }
}

/// The "Infinite Kittens" subscription row: shows live status backed by
/// `Entitlements.shared` (Subscribed ✓, or price + subscribe) and opens
/// `PaywallView` to purchase, manage, or restore.
struct SubscriptionSection: View {
    @ObservedObject private var entitlements = Entitlements.shared
    @State private var showPaywall = false

    var body: some View {
        KSCard {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(KSTheme.accent.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: "sparkles")
                            .foregroundStyle(KSTheme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Infinite Kittens")
                            .font(.headline)
                            .foregroundStyle(KSTheme.textPrimary)
                        Text(entitlements.isSubscriber ? "Subscribed ✓" : "\(entitlements.priceText)/month — unlimited AI kittens")
                            .font(.footnote)
                            .foregroundStyle(KSTheme.textSecondary)
                    }
                    Spacer()
                    if entitlements.isSubscriber {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(KSTheme.accent)
                    } else {
                        Text("Subscribe")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(KSTheme.accent, in: Capsule())
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .task { await entitlements.loadProduct() }
    }
}

#Preview {
    SettingsView()
}
