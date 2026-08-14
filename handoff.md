# Kitten Shake — Project Handoff

_Last updated: 2026-08-14_

## What this is
2026 resurrection of Kitten Shake (Kenzora Games, original 2013 app): take/pick a photo, square-crop it, shake for a random kitten (meows!), pet/drag/pinch/twirl it, stack multiple kittens, save/share. Rebuilt from scratch in SwiftUI — no original source survived; assets were recovered from the final IPA and archive folders (`original project files/`).

## Current state (all on TestFlight under the original app record)
- **App**: `KittenShake/` — SwiftUI, iOS 17+, Universal (Apple requires iPad support on this app record), portrait, XcodeGen (`cd KittenShake && xcodegen generate`).
- **Latest TestFlight build: 2.0 (6), VALID** (uploaded 2026-08-09). Builds 1–6 all VALID.
- **Design**: strict fidelity to the mockups in `img/Redesign/` (binding spec, per owner). Fraunces (OFL) display type, vector cat logo (`CatMark.swift`), guided flow: Home → Get Started → custom camera → crop → shake-review → position mode → Build Your Scene → Result. Floating tab bar (`KSTabBar` + `TabBarVisibility.shared`) shows ONLY on Home, shake-review, Creations, Settings. All 8 mockup screens went through side-by-side tuning. Intentional deviations: coral links (not mockup blue), Undo on Build Scene, live permission states on Get Started, free-tier watermark on exports.
- **Monetization**: "Infinite Kittens" $2.99/mo auto-renew sub (`com.kenzoragames.KittenShake.infinitekittens.monthly`, ASC subscription 6799694937 in group 22297599 "Infinite Kittens"). Free tier: classic 16-kitten shake (watermarked exports) + 3 AI generations per device. Subscribers: unlimited AI kittens + no watermark.
- **AI backend**: Cloudflare Worker `kitten-gen` → https://kitten-gen.dry-base-037d.workers.dev (source in `backend/`). OpenAI gpt-image-1, transparent 1024 PNGs, server-side prompts only, KV quota (namespace 08a604f19ed94bf7b18d7a99b4107286), 10/min rate limit. Secret OPENAI_API_KEY is set (owner's key file: `~/.config/kitten-shake/openai.key.rtf`). Contract documented in `backend/src/index.ts`.
- **Smart placement**: on-device Vision (faces + saliency) in `KittenPlacer.swift`, AI kittens only.

## OPEN ISSUE — Subscribe CTA blocked (where we left off)
On TestFlight, `Product.products(for:)` returns empty, so the paywall's Subscribe never enables. The ASC product record is complete (localizations, $2.99 USA price, availability, review screenshot COMPLETE, state MISSING_METADATA). **Prime suspect: the Paid Applications agreement** (Business → Agreements, Tax, Banking) was likely never signed on this 2013-era account — without it Apple serves no products. **Waiting on the owner to check/sign it (Account Holder only).** A paywall UX fix is committed (loading spinner / "Can't reach the App Store" + Try Again / os.Logger diagnostics) but **not yet shipped — build 7 is intentionally held** so it can verify the full purchase flow once the agreement is resolved.

## Release mechanics (proven, used for builds 1–6)
- Signing: manual — cert "Apple Distribution: Kenzora Games (7K9WY5T49S)" + profile "KittenShake App Store" (ASC profile APZ4NTKZW3, installed locally). The ASC API key can't mint cloud-managed certs (403), hence manual.
- ASC API key GD6Y5ZHB45 at `~/.appstoreconnect/private_keys/`, issuer `69a6de72-d2ec-47e3-e053-5b8c7c11a4d1`. App Apple ID 825393423, bundle `com.kenzoragames.KittenShake`, SKU K0002.
- Ship recipe: bump CURRENT_PROJECT_VERSION in `KittenShake/project.yml` → xcodegen → Release build + `strings` check that no `ksScreen`/`ksForceSubscriber`/`ksAutoAI`/`ksAutoExport` leak (debug hooks are `#if DEBUG`-guarded in `UITestSupport.swift`) → `xcodebuild archive` + `-exportArchive` (method app-store-connect, destination upload) → poll `/v1/builds?filter[app]=825393423` until VALID.
- Debug verification: `-ksScreen <name>` launch args (home, getstarted, camera, shakereview, position, buildscene, result, paywall…) jump straight to seeded screens for simulator screenshots. Debug builds only.
- Recurring gotcha: the floating tab bar does not propagate safe-area insets into NavigationStack-pushed screens — bottom content needs explicit clearance (`KSTheme.flowBottomClearance`) on tab-bar screens, or hide the bar via `TabBarVisibility.shared`.

## Before public App Store release (Phase 3 seeds)
1. Resolve the Paid Applications agreement + one real sandbox purchase test on device (last unverified link).
2. Full Apple x5c/ES256 JWS verification in the Worker (currently decode-only; TODO in `backend/src/index.ts`).
3. Terms of Use + Privacy Policy URLs on the paywall (App Review requirement).
4. Subscription territories beyond USA; consider more localizations.
5. App Store listing refresh (screenshots, description).
6. Product idea parked: "remove watermark" is bundled in the sub; a cheaper standalone unlock was once floated.

## Repo map
- `KittenShake/` — the app (project.yml is the source of truth; .xcodeproj is generated/gitignored)
- `backend/` — Cloudflare Worker
- `img/Redesign/` — the 8 binding design mockups; `img/` — original 2013 app screenshots
- `original project files/` — 2013 archive (assets, PSDs, IPAs, wireframes; kitten CC attribution in `Kittens/CC atribution/`)
- Owner memory (Claude): `~/.claude/projects/-Users-mikejerugim-kitten-shake/memory/`
