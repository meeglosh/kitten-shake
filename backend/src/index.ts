// Kitten Shake — Infinite Kittens generation worker.
//
// Endpoints:
//   GET  /health         -> { ok: true }
//   POST /v1/generate    -> { imageB64, remaining } | error JSON (see below)

const PRODUCT_ID = "com.kenzoragames.KittenShake.infinitekittens.monthly";
const FREE_QUOTA_LIMIT = 3;
const RATE_LIMIT_PER_MIN = 10;
const MAX_BODY_BYTES = 10 * 1024; // 10KB

interface GenerateRequestBody {
	deviceId?: unknown;
	transactionJWS?: unknown;
}

function jsonResponse(body: unknown, status = 200): Response {
	return new Response(JSON.stringify(body), {
		status,
		headers: { "content-type": "application/json" },
	});
}

// ---------------------------------------------------------------------------
// StoreKit 2 transaction verification
// ---------------------------------------------------------------------------

interface DecodedTransaction {
	productId: string;
	expiresDate: number; // ms since epoch
}

/**
 * Decodes (but does not cryptographically verify) a StoreKit 2 signed
 * transaction JWS. StoreKit 2 transactions are JWS strings with three
 * base64url segments: header.payload.signature. We only decode the
 * payload here.
 *
 * TODO(Phase 3): Replace this with full Apple x5c certificate chain
 * verification per https://developer.apple.com/documentation/appstoreserverapi/verifying-transactions
 * — fetch/cache Apple's root CA, validate the x5c chain in the JWS
 * header, verify the ES256 signature over header+payload, and confirm
 * the leaf certificate chains to Apple's root before trusting the
 * decoded payload. Until then this is a sanity-checked decode only and
 * MUST NOT be treated as a substitute for real verification in a
 * production release with real revenue at stake beyond soft-launch.
 */
function verifyTransaction(jws: string): DecodedTransaction | null {
	try {
		const parts = jws.split(".");
		if (parts.length !== 3) return null;

		const payloadJson = base64UrlDecode(parts[1]);
		const payload = JSON.parse(payloadJson) as Record<string, unknown>;

		const productId = payload.productId;
		const expiresDate = payload.expiresDate;

		if (typeof productId !== "string" || productId !== PRODUCT_ID) {
			return null;
		}
		if (typeof expiresDate !== "number") {
			return null;
		}
		if (expiresDate <= Date.now()) {
			return null;
		}

		return { productId, expiresDate };
	} catch {
		return null;
	}
}

function base64UrlDecode(segment: string): string {
	const base64 = segment.replace(/-/g, "+").replace(/_/g, "/");
	const padded = base64 + "=".repeat((4 - (base64.length % 4)) % 4);
	const binary = atob(padded);
	// Decode as UTF-8 bytes -> string.
	const bytes = Uint8Array.from(binary, (c) => c.charCodeAt(0));
	return new TextDecoder().decode(bytes);
}

// ---------------------------------------------------------------------------
// Free quota (KV-backed, best-effort atomic via read-modify-write)
// ---------------------------------------------------------------------------

interface QuotaCheckResult {
	allowed: boolean;
	remaining: number;
}

/** Checks whether a device still has free generations left, WITHOUT spending one. */
async function peekFreeQuota(kv: KVNamespace, deviceId: string): Promise<QuotaCheckResult> {
	const key = `free:${deviceId}`;
	const raw = await kv.get(key);
	const used = raw ? Number.parseInt(raw, 10) || 0 : 0;
	const remaining = Math.max(0, FREE_QUOTA_LIMIT - used);
	return { allowed: remaining > 0, remaining };
}

/** Spends one free generation. Call only after a successful generation. */
async function spendFreeQuota(kv: KVNamespace, deviceId: string): Promise<number> {
	const key = `free:${deviceId}`;
	const raw = await kv.get(key);
	const used = raw ? Number.parseInt(raw, 10) || 0 : 0;
	const next = used + 1;
	await kv.put(key, String(next));
	return Math.max(0, FREE_QUOTA_LIMIT - next);
}

// ---------------------------------------------------------------------------
// Per-device rate limiting (best-effort, KV timestamp window)
// ---------------------------------------------------------------------------

async function checkRateLimit(kv: KVNamespace, deviceId: string): Promise<boolean> {
	const key = `rl:${deviceId}`;
	const now = Date.now();
	const windowMs = 60_000;
	const raw = await kv.get(key);
	const timestamps: number[] = raw ? (JSON.parse(raw) as number[]) : [];
	const recent = timestamps.filter((t) => now - t < windowMs);

	if (recent.length >= RATE_LIMIT_PER_MIN) {
		return false;
	}

	recent.push(now);
	await kv.put(key, JSON.stringify(recent), { expirationTtl: 120 });
	return true;
}

// ---------------------------------------------------------------------------
// Kitten prompt generation (server-side only — never trust client prompts)
// ---------------------------------------------------------------------------

const BREEDS = [
	"tabby",
	"calico",
	"tuxedo",
	"orange ginger",
	"gray British Shorthair",
	"white Persian",
	"black",
	"Siamese",
	"tortoiseshell",
	"Maine Coon",
];

const POSES = ["sitting upright", "standing", "lying down curled up", "mid-playful-pounce", "stretching"];

const EXPRESSIONS = ["curious", "sleepy", "playful", "alert", "content", "wide-eyed"];

function randomPick<T>(arr: readonly T[]): T {
	return arr[Math.floor(Math.random() * arr.length)];
}

function buildKittenPrompt(): string {
	const breed = randomPick(BREEDS);
	const pose = randomPick(POSES);
	const expression = randomPick(EXPRESSIONS);
	return (
		`Photorealistic cute kitten, ${breed} breed, full body visible, ${pose}, ` +
		`${expression} expression, isolated subject on a transparent background, ` +
		`studio-quality lighting, sharp focus, high detail fur texture.`
	);
}

// ---------------------------------------------------------------------------
// OpenAI Images API
// ---------------------------------------------------------------------------

async function generateKittenImage(apiKey: string): Promise<string | null> {
	const prompt = buildKittenPrompt();

	const response = await fetch("https://api.openai.com/v1/images/generations", {
		method: "POST",
		headers: {
			authorization: `Bearer ${apiKey}`,
			"content-type": "application/json",
		},
		body: JSON.stringify({
			model: "gpt-image-1",
			prompt,
			background: "transparent",
			size: "1024x1024",
			output_format: "png",
			quality: "medium",
			n: 1,
		}),
	});

	if (!response.ok) {
		return null;
	}

	const data = (await response.json()) as { data?: Array<{ b64_json?: string }> };
	const b64 = data.data?.[0]?.b64_json;
	return typeof b64 === "string" ? b64 : null;
}

// ---------------------------------------------------------------------------
// Request handling
// ---------------------------------------------------------------------------

async function handleGenerate(request: Request, env: Env): Promise<Response> {
	const contentLengthHeader = request.headers.get("content-length");
	if (contentLengthHeader && Number.parseInt(contentLengthHeader, 10) > MAX_BODY_BYTES) {
		return jsonResponse({ error: "payload_too_large" }, 413);
	}

	const rawBody = await request.text();
	if (rawBody.length > MAX_BODY_BYTES) {
		return jsonResponse({ error: "payload_too_large" }, 413);
	}

	let body: GenerateRequestBody;
	try {
		body = JSON.parse(rawBody) as GenerateRequestBody;
	} catch {
		return jsonResponse({ error: "invalid_json" }, 400);
	}

	const deviceId = body.deviceId;
	if (typeof deviceId !== "string" || deviceId.length === 0 || deviceId.length > 256) {
		return jsonResponse({ error: "invalid_device_id" }, 400);
	}

	const transactionJWS = typeof body.transactionJWS === "string" ? body.transactionJWS : undefined;

	const withinRateLimit = await checkRateLimit(env.QUOTA_KV, deviceId);
	if (!withinRateLimit) {
		return jsonResponse({ error: "rate_limited" }, 429);
	}

	// --- Entitlement check ---------------------------------------------------
	let isSubscriber = false;

	if (transactionJWS) {
		const decoded = verifyTransaction(transactionJWS);
		isSubscriber = decoded !== null;
	}

	if (!isSubscriber) {
		const quota = await peekFreeQuota(env.QUOTA_KV, deviceId);
		if (!quota.allowed) {
			return jsonResponse({ error: "subscription_required", remaining: 0 }, 402);
		}
	}

	// --- Entitled: generate ----------------------------------------------------
	if (!env.OPENAI_API_KEY) {
		return jsonResponse({ error: "not_configured" }, 503);
	}

	const imageB64 = await generateKittenImage(env.OPENAI_API_KEY);
	if (!imageB64) {
		return jsonResponse({ error: "generation_failed" }, 502);
	}

	// Only spend a free credit after a successful generation, so failed
	// generations don't consume the user's limited free uses.
	let remaining: number | null = null;
	if (!isSubscriber) {
		remaining = await spendFreeQuota(env.QUOTA_KV, deviceId);
	}

	return jsonResponse({ imageB64, remaining });
}

export default {
	async fetch(request: Request, env: Env): Promise<Response> {
		const url = new URL(request.url);

		if (request.method === "GET" && url.pathname === "/health") {
			return jsonResponse({ ok: true });
		}

		if (request.method === "POST" && url.pathname === "/v1/generate") {
			try {
				return await handleGenerate(request, env);
			} catch (err) {
				console.error("generate_error", err instanceof Error ? err.message : String(err));
				return jsonResponse({ error: "internal_error" }, 500);
			}
		}

		return jsonResponse({ error: "not_found" }, 404);
	},
} satisfies ExportedHandler<Env>;
