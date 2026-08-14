import Foundation
import StoreKit
import Combine
import os

/// The underlying cause `Product.products(for:)` can fail for silently:
/// on TestFlight, an App Store Connect-side misconfiguration (agreement not
/// signed, product not yet propagated, etc.) makes StoreKit return an
/// *empty* array rather than throwing — so an empty result is treated as a
/// failure here, not as "no product yet".
private enum ProductLoadError: Error, LocalizedError {
    case notFound

    var errorDescription: String? {
        "Product.products(for:) returned no matching product (App Store Connect configuration issue, or not yet propagated)."
    }
}

/// Loading state for the StoreKit product backing the paywall, tracked
/// separately from `product` itself so the UI can distinguish "still
/// loading", "loaded", and "failed" instead of inferring failure from
/// `product == nil`, which can't be told apart from "hasn't loaded yet".
enum ProductLoadState {
    case loading
    case loaded
    case failed(Error?)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

/// Observable subscription state for "Infinite Kittens", backed by
/// StoreKit 2. Loads the monthly auto-renewable product, listens for
/// `Transaction.updates`, and derives `isSubscriber` from
/// `Transaction.currentEntitlements`. Also exposes the latest verified
/// transaction's signed JWS so the backend can validate the subscription
/// independently of Apple's servers (see `KittenGenerationClient`).
@MainActor
final class Entitlements: ObservableObject {
    static let shared = Entitlements()

    static let productID = "com.kenzoragames.KittenShake.infinitekittens.monthly"

    private static let logger = Logger(subsystem: "com.kenzoragames.KittenShake", category: "Entitlements")

    @Published private(set) var isSubscriber: Bool = false
    @Published private(set) var product: Product?
    @Published private(set) var isLoadingProduct = false
    @Published private(set) var productLoadState: ProductLoadState = .loading
    @Published private(set) var purchaseInProgress = false
    @Published var lastError: String?

    /// The `jwsRepresentation` of the most recent verified, unrevoked
    /// transaction for the subscription — sent to the backend as proof of
    /// entitlement so it can skip the free-generation limit.
    @Published private(set) var currentTransactionJWS: String?

    private var updatesTask: Task<Void, Never>?
    private var autoRetryTask: Task<Void, Never>?
    private var hasAutoRetried = false
    private let isForcedForVerification = UITestSupport.forceSubscriber

    private init() {
        if isForcedForVerification { isSubscriber = true }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update: update)
            }
        }
        Task { await self.loadProduct() }
        Task { await self.refreshEntitlements() }
    }

    deinit {
        updatesTask?.cancel()
        autoRetryTask?.cancel()
    }

    var priceText: String {
        product?.displayPrice ?? "$2.99"
    }

    func loadProduct() async {
        guard product == nil else {
            productLoadState = .loaded
            return
        }
        isLoadingProduct = true
        productLoadState = .loading
        defer { isLoadingProduct = false }
        do {
            let products = try await Product.products(for: [Self.productID])
            guard let loaded = products.first else {
                // Not thrown by StoreKit — Product.products(for:) returns an
                // empty array (rather than an error) when App Store Connect
                // hasn't propagated the product, which is what we see on
                // TestFlight. Treat that the same as a thrown failure so the
                // paywall can surface it instead of silently doing nothing.
                throw ProductLoadError.notFound
            }
            product = loaded
            productLoadState = .loaded
            lastError = nil
        } catch {
            Self.logger.error("StoreKit product load failed for \(Self.productID, privacy: .public): \(String(describing: error), privacy: .public)")
            lastError = "Couldn't load subscription details. Check your connection and try again."
            productLoadState = .failed(error)
            scheduleAutoRetryIfNeeded()
        }
    }

    /// User-initiated retry (e.g. tapping "Try Again" on the paywall's error
    /// card). Re-enters `loadProduct()`, which will retry the StoreKit call
    /// since `product` is still nil.
    func retryLoad() {
        autoRetryTask?.cancel()
        Task { await loadProduct() }
    }

    /// Automatically retries once, ~2s after the first failure, to smooth
    /// over transient network blips without the user having to notice and
    /// tap "Try Again" themselves. Only fires once per app session; after
    /// that, failures require an explicit retry.
    private func scheduleAutoRetryIfNeeded() {
        guard !hasAutoRetried else { return }
        hasAutoRetried = true
        autoRetryTask?.cancel()
        autoRetryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard let self, !Task.isCancelled else { return }
            if case .failed = self.productLoadState {
                await self.loadProduct()
            }
        }
    }

    func purchase() async {
        lastError = nil
        if product == nil { await loadProduct() }
        guard let product else {
            lastError = "The subscription isn't available right now."
            return
        }
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(update: verification)
            case .userCancelled:
                break
            case .pending:
                lastError = "Your purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            lastError = "Purchase failed. Please try again."
        }
    }

    func restore() async {
        lastError = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isSubscriber {
                lastError = "No active subscription found for this Apple ID."
            }
        } catch {
            lastError = "Couldn't restore purchases. Please try again."
        }
    }

    /// Re-derives `isSubscriber` and `currentTransactionJWS` from
    /// StoreKit's local, cryptographically verified entitlement set.
    func refreshEntitlements() async {
        if isForcedForVerification {
            isSubscriber = true
            return
        }
        var subscribed = false
        var jws: String?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == Self.productID else { continue }
            if transaction.revocationDate == nil {
                subscribed = true
                jws = result.jwsRepresentation
            }
        }
        isSubscriber = subscribed
        currentTransactionJWS = jws
    }

    private func handle(update result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.productID {
            await transaction.finish()
        }
        await refreshEntitlements()
    }
}
