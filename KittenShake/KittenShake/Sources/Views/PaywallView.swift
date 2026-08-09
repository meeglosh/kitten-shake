import SwiftUI

/// The "Infinite Kittens" paywall. Presented when a non-subscriber runs out
/// of free AI generations (from `EditorView`) or taps the subscription row
/// in Settings. Doubles as the App Store review screenshot for the
/// subscription, so it carries the required auto-renew/terms disclosure.
struct PaywallView: View {
    @ObservedObject private var entitlements = Entitlements.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            ZStack {
                KSScreenBackground()

                ScrollView {
                    VStack(spacing: KSTheme.spacingL) {
                        header

                        KSCard {
                            VStack(alignment: .leading, spacing: KSTheme.spacingM) {
                                benefitRow(
                                    icon: "infinity",
                                    title: "∞ AI-generated kittens",
                                    subtitle: "No more counting free tries"
                                )
                                Divider()
                                benefitRow(
                                    icon: "wand.and.stars",
                                    title: "Smart placement",
                                    subtitle: "Kittens land beside you, never over your face"
                                )
                                Divider()
                                benefitRow(
                                    icon: "photo.badge.checkmark",
                                    title: "No watermark",
                                    subtitle: "Clean exports, ready to share"
                                )
                            }
                        }

                        if entitlements.isSubscriber {
                            subscribedCard
                        } else {
                            subscribeSection
                        }

                        if let error = entitlements.lastError {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        legalNote
                    }
                    .padding(.horizontal, KSTheme.spacingM)
                    .padding(.bottom, KSTheme.spacingL)
                }
                .ksReadableWidth()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(KSTheme.textSecondary)
                }
            }
        }
        .fontDesign(.rounded)
        .task { await entitlements.loadProduct() }
    }

    private var header: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(KSTheme.accent.opacity(0.15)).frame(width: 72, height: 72)
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundStyle(KSTheme.accent)
            }
            Text("Infinite Kittens")
                .font(KSTheme.display(32))
                .foregroundStyle(KSTheme.textPrimary)
            Text("Unlimited AI-generated kittens, perfectly placed on every photo.")
                .font(.subheadline)
                .foregroundStyle(KSTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, KSTheme.spacingL)
    }

    private var subscribedCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(KSTheme.accent)
            Text("Subscribed ✓")
                .font(.headline)
                .foregroundStyle(KSTheme.textPrimary)
            Spacer()
        }
        .padding(KSTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: KSTheme.controlRadius, style: .continuous)
                .fill(KSTheme.surface)
        )
    }

    private var subscribeSection: some View {
        VStack(spacing: KSTheme.spacingS) {
            Text("\(entitlements.priceText) / month")
                .font(KSTheme.display(22))
                .foregroundStyle(KSTheme.textPrimary)

            Button {
                SoundPlayer.shared.playClick()
                Task {
                    await entitlements.purchase()
                    if entitlements.isSubscriber { dismiss() }
                }
            } label: {
                if entitlements.purchaseInProgress {
                    ProgressView().tint(.white)
                } else {
                    Text("Subscribe")
                }
            }
            .buttonStyle(.ksPrimary(disabled: entitlements.purchaseInProgress || entitlements.product == nil))
            .disabled(entitlements.purchaseInProgress || entitlements.product == nil)

            Button {
                isRestoring = true
                Task {
                    await entitlements.restore()
                    isRestoring = false
                    if entitlements.isSubscriber { dismiss() }
                }
            } label: {
                if isRestoring {
                    ProgressView()
                } else {
                    Text("Restore purchases")
                        .font(.footnote.weight(.semibold))
                }
            }
            .foregroundStyle(KSTheme.accent)
            .padding(.top, 4)
        }
        .padding(.top, KSTheme.spacingS)
    }

    private var legalNote: some View {
        Text("Infinite Kittens is a \(entitlements.priceText)/month auto-renewing subscription. Payment is charged to your Apple ID at confirmation of purchase. Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period. Manage or cancel anytime in Settings > Apple ID > Subscriptions.")
            .font(.caption2)
            .foregroundStyle(KSTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, KSTheme.spacingS)
    }

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(KSTheme.accent.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundStyle(KSTheme.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(KSTheme.textPrimary)
                Text(subtitle).font(.caption).foregroundStyle(KSTheme.textSecondary)
            }
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
}
