import Foundation
import UIKit

/// Errors surfaced by the AI-generation backend, mapped from its documented
/// HTTP status contract.
enum KittenGenerationError: LocalizedError {
    case subscriptionRequired
    case rateLimited
    case generationFailed
    case notConfigured
    case network(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .subscriptionRequired:
            return "You've used all your free kittens. Subscribe to Infinite Kittens for unlimited AI kittens."
        case .rateLimited:
            return "Too many requests right now — give it a minute and try again."
        case .generationFailed:
            return "The kitten generator hiccuped. Please try again."
        case .notConfigured:
            return "AI kittens aren't available right now. Please try again later."
        case .network(let message):
            return message
        case .decoding:
            return "Something went wrong reading the response. Please try again."
        }
    }
}

struct KittenGenerationResult {
    let image: UIImage
    /// Free uses remaining, or `nil` for subscribers (unlimited).
    let remaining: Int?
}

/// Client for the Kitten Shake AI-generation Worker. Contract:
/// `POST /v1/generate` with `{"deviceId": String, "transactionJWS": String?}`
/// returns `{"imageB64": String, "remaining": Int?}` — a transparent
/// 1024x1024 PNG kitten cutout, ready to composite onto the editor canvas.
enum KittenGenerationClient {
    static let baseURL = URL(string: "https://kitten-gen.dry-base-037d.workers.dev")!

    static func generate(transactionJWS: String?) async throws -> KittenGenerationResult {
        var body: [String: Any] = ["deviceId": DeviceIdentity.current]
        if let transactionJWS {
            body["transactionJWS"] = transactionJWS
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("v1/generate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw KittenGenerationError.network("Couldn't reach the kitten generator. Check your connection and try again.")
        }

        guard let http = response as? HTTPURLResponse else {
            throw KittenGenerationError.decoding
        }

        switch http.statusCode {
        case 200:
            break
        case 402:
            throw KittenGenerationError.subscriptionRequired
        case 429:
            throw KittenGenerationError.rateLimited
        case 503:
            throw KittenGenerationError.notConfigured
        default:
            throw KittenGenerationError.generationFailed
        }

        struct ResponsePayload: Decodable {
            let imageB64: String
            let remaining: Int?
        }

        guard let payload = try? JSONDecoder().decode(ResponsePayload.self, from: data),
              let imageData = Data(base64Encoded: payload.imageB64),
              let image = UIImage(data: imageData) else {
            throw KittenGenerationError.decoding
        }

        return KittenGenerationResult(image: image, remaining: payload.remaining)
    }
}
