import Foundation
import StoreKit
import Combine

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

    @Published private(set) var isSubscriber: Bool = false
    @Published private(set) var product: Product?
    @Published private(set) var isLoadingProduct = false
    @Published private(set) var purchaseInProgress = false
    @Published var lastError: String?

    /// The `jwsRepresentation` of the most recent verified, unrevoked
    /// transaction for the subscription — sent to the backend as proof of
    /// entitlement so it can skip the free-generation limit.
    @Published private(set) var currentTransactionJWS: String?

    private var updatesTask: Task<Void, Never>?
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
    }

    var priceText: String {
        product?.displayPrice ?? "$2.99"
    }

    func loadProduct() async {
        guard product == nil else { return }
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            lastError = "Couldn't load subscription details. Check your connection and try again."
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
