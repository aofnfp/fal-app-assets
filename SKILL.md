---
name: app-asset-forge
description: >
  Generate production-ready app assets using Fal.ai — icons, logos, splash screens, favicons, onboarding illustrations,
  empty states, achievement badges, notification icons, tab bar icons, and more for iOS and Android.
  Use this skill whenever the user wants to create, generate, or design ANY visual asset for a mobile app, web app, or PWA.
  Triggers include: app icon, logo, splash screen, launch screen, favicon, onboarding screen, empty state illustration,
  achievement badge, feature graphic, app store screenshot mockup, notification icon, tab bar icon, in-app illustration,
  brand assets, or any mention of Fal.ai image generation for apps. Also use when the user wants to generate multiple
  asset sizes for different platforms (iOS, Android, web), create icon sets, or produce platform-ready asset bundles.
  Even if the user just says "make me an icon" or "I need visuals for my app" — this is the skill to use.
---

# App Asset Forge

One-stop skill for generating every visual asset an app needs — icons, logos, splash screens, onboarding illustrations, empty states, achievement badges, favicons, notification icons, tab bar icons, feature graphics, and more — using Fal.ai's image generation API. Covers iOS, Android, and Web/PWA with platform-correct sizes and formats.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/generate.sh` | Generate any asset via Fal.ai queue API (bash/curl) |
| `scripts/generate_bundle.py` | Resize a master image into all platform sizes (Python/Pillow) |
| `scripts/upload.sh` | Upload local files to Fal CDN |
| `scripts/search-models.sh` | Search and discover Fal.ai models |
| `scripts/lib.sh` | Shared utilities: retry, JSON safety, env loading, error detection |

## Prerequisites

- **FAL_KEY** environment variable set. Get a key at https://fal.ai/dashboard/keys
- For bundle generation: Python 3.8+ with Pillow (`pip install Pillow --break-system-packages`)
- All generation scripts use `curl` — no SDK install needed for basic generation

## Understanding App Assets

Before generating anything, you need to understand what each asset is, why it matters, and the technical constraints that make it succeed or fail. This is critical because generating the wrong size, wrong format, or wrong style wastes API calls and produces assets that won't pass App Store / Play Store review.

### App Icon — The Single Most Important Asset

The app icon is the first thing a user sees on their home screen, in search results, and in the store. It must be instantly recognizable at 29×29 pt (58px) AND look stunning at 1024×1024. This creates a unique constraint: icons must be simple, bold, and use strong silhouettes — fine detail disappears at small sizes.

**Technical requirements:**
- **iOS App Store**: 1024×1024 px PNG. NO transparency. NO alpha channel. Xcode auto-generates all smaller sizes from this master. iOS applies its own corner radius mask — never bake rounded corners into the icon.
- **Android Play Store**: 512×512 px PNG or JPEG. No alpha. Android uses adaptive icons (108×108 dp canvas) where the inner 72×72 dp "safe zone" is guaranteed visible under any mask shape (circle, squircle, teardrop). Generate the foreground layer as 432×432 px with the icon centered in the inner two-thirds.
- **Design principles**: Fill the entire canvas. Use 1-2 dominant colors. Avoid text in icons (it becomes unreadable at small sizes). Avoid photos — use flat/geometric/illustrated styles. Test at 29px: if it's a blob, simplify.

### Logo — Brand Identity

Logos come in several types, and the type determines the model and prompt strategy:
- **Wordmark** (text-only, e.g., "Google"): USE Ideogram V3 or Recraft V4 — text accuracy is non-negotiable
- **Lettermark** (initials, e.g., "IBM"): Same as above — text must be letter-perfect
- **Pictorial/Symbol** (e.g., Apple's apple): Use Recraft V4 SVG for true vector output
- **Abstract mark** (geometric shape): Use Recraft V4 SVG
- **Combination** (icon + text): Generate icon separately with Recraft V4, add text with Ideogram V3 or composite manually

Logos must be scalable (work at 16px favicon AND on a billboard) — this is why SVG output from Recraft V4 is so valuable.

### Splash Screen / Launch Screen

The screen shown during app startup. Its job is to feel instant — Apple's HIG says it should look nearly identical to the app's first screen.
- **iOS**: Modern apps use a storyboard with Auto Layout (not a static image). If generating an illustration for the splash, target 1125×2436 px (iPhone 14 Pro) and center the content.
- **Android 12+**: Uses the Splash Screen API. The icon is a VectorDrawable within a 432dp canvas, with only the inner 288dp guaranteed visible. Background is a single solid color.
- **Common pattern**: Generate a centered icon/illustration and a complementary background color. Don't put text on splash screens.

### Onboarding Screens

Walkthrough screens shown on first launch (typically 3-5 screens). They teach the user what the app does.
- Each screen has an illustration in the top 60-70%, and text + CTA button in the bottom 30-40%
- **Critical**: Always prompt to "leave the bottom 30% empty for text overlay"
- Must maintain visual consistency across all screens (same style, same palette, same character design)
- Nano Banana 2 is ideal because it maintains character consistency across generations

### Empty State Illustrations

Shown when a screen has no content (empty inbox, no search results, empty cart). Their job is to feel friendly, not broken.
- Small: typically displayed at 200-400dp
- Generate at 800×800 px, scale down
- Must be simple enough to read at small size
- Should feel encouraging ("nothing here yet!") not depressing

### Achievement Badges

Reward icons for gamification (streaks, milestones, level-ups). Displayed at small sizes in lists and as popup notifications.
- Generate at 512×512, display at 48-96dp
- Must be bold, recognizable, and feel rewarding (gold, stars, shields)
- Avoid text — badges are often shown in grids where text is unreadable

### Notification Icon (Android-specific)

Android notification icons have strict rules:
- **MUST be solid white (#FFFFFF) silhouette on transparent background**
- The system applies a tint color — your icon is just the alpha mask
- Generate at 96×96 px (xxxhdpi), scale to other densities
- No gradients, no shadows, no color — the system ignores all of it
- Must be recognizable at 24×24 dp (tiny!)

### Tab Bar Icons / Navigation Icons

The icons in the bottom tab bar (iOS) or bottom navigation (Android).
- **iOS**: 25×25 pt → 75×75 px at @3x. iOS uses the alpha channel as a mask — provide silhouettes
- **Android**: 24×24 dp → 96×96 px at xxxhdpi. Material design outlined style
- Must be visually consistent as a set — same stroke weight, same style

### Favicon

The tiny icon in browser tabs. Seems small but is critical for web apps and PWAs.
- ICO bundle: 16×16, 32×32, 48×48 in one file
- Apple touch icon: 180×180 PNG
- PWA: 192×192 and 512×512 PNG (required for installable PWAs)
- Must be recognizable at 16px — usually the app icon simplified to its most basic form

### Feature Graphic (Android Play Store)

The banner at the top of your Play Store listing. 1024×500 px, landscape. No alpha.
- This is marketing — it should be eye-catching and convey the app's purpose
- Leave space on the left third for the app name (Play Store overlays it)

### App Store Screenshots

Not generated by this skill (they require actual app UI), but worth knowing:
- iOS: Upload 1290×2796 px, Apple auto-scales to all devices
- Android: 1080×1920 px phone, 1600×2560 px tablet

## Fal.ai API — How to Actually Call It

All generation uses the Fal.ai Queue API. This is the actual HTTP interface — no SDK needed.

### Authentication

```
Authorization: Key YOUR_FAL_KEY
```

Every request needs this header. The key comes from https://fal.ai/dashboard/keys and is stored in the `FAL_KEY` environment variable.

### Queue System (How Every Generation Works)

All requests go through Fal's queue for reliability:

```
Submit Request → Get request_id → Poll Status → Get Result
```

This is important because video generation can take 30-60 seconds, and even images take 2-10 seconds. The queue prevents timeouts.

### Step 1: Submit to Queue

```bash
curl -s -X POST "https://queue.fal.run/fal-ai/recraft/v4" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Minimal flat design camera icon, geometric shapes, blue gradient, centered on white background, no text",
    "image_size": {"width": 1024, "height": 1024},
    "num_images": 1
  }'
```

**Response:**
```json
{
  "request_id": "abc123-def456",
  "status": "IN_QUEUE",
  "response_url": "https://queue.fal.run/fal-ai/recraft/v4/requests/abc123-def456",
  "status_url": "https://queue.fal.run/fal-ai/recraft/v4/requests/abc123-def456/status",
  "cancel_url": "https://queue.fal.run/fal-ai/recraft/v4/requests/abc123-def456/cancel"
}
```

### Step 2: Poll Status

```bash
curl -s -X GET "https://queue.fal.run/fal-ai/recraft/v4/requests/abc123-def456/status" \
  -H "Authorization: Key $FAL_KEY"
```

Status will be: `IN_QUEUE` → `IN_PROGRESS` → `COMPLETED` (or `FAILED`)

### Step 3: Get Result

```bash
curl -s -X GET "https://queue.fal.run/fal-ai/recraft/v4/requests/abc123-def456" \
  -H "Authorization: Key $FAL_KEY"
```

**Response:**
```json
{
  "images": [
    {
      "url": "https://v3.fal.media/files/abc123/output.png",
      "width": 1024,
      "height": 1024,
      "content_type": "image/png"
    }
  ],
  "seed": 12345,
  "timings": {"inference": 2.34}
}
```

### Synchronous Mode (Quick Jobs Only)

For fast models like FLUX.1 Schnell, you can skip the queue:

```bash
curl -s -X POST "https://fal.run/fal-ai/flux/schnell" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Quick test icon concept, flat design", "image_size": "square", "num_images": 1}'
```

This blocks until done and returns the result directly. Only use for models that complete in <5 seconds.

### File Upload (for Image-to-Image / Image-to-Video)

When you need to send a local image (e.g., refining a generated icon):

```bash
# Step 1: Get CDN upload token
TOKEN_RESPONSE=$(curl -s -X POST "https://rest.alpha.fal.ai/storage/auth/token?storage_type=fal-cdn-v3" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" -d '{}')

CDN_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token')
CDN_BASE_URL=$(echo "$TOKEN_RESPONSE" | jq -r '.base_url')

# Step 2: Upload file
UPLOAD_RESPONSE=$(curl -s -X POST "${CDN_BASE_URL}/files/upload" \
  -H "Authorization: Bearer $CDN_TOKEN" \
  -H "Content-Type: image/png" \
  -H "X-Fal-File-Name: my-icon.png" \
  --data-binary "@./my-icon.png")

IMAGE_URL=$(echo "$UPLOAD_RESPONSE" | jq -r '.access_url')
# → https://v3b.fal.media/files/.../my-icon.png
```

Max file size: 100MB. Supported: jpg, png, gif, webp, mp4, mov, webm.

### Model-Specific API Payloads

Different models accept different parameters. Here are the exact payloads for each asset type:

**Recraft V4 (icons, empty states, illustrations):**
```json
{
  "prompt": "...",
  "image_size": {"width": 1024, "height": 1024},
  "style": "vector_illustration",
  "colors": [[66, 133, 244], [52, 168, 83]],
  "background_color": [255, 255, 255],
  "num_images": 1
}
```

**Recraft V4 SVG (icons, logos, badges — true vector output):**
Endpoint: `fal-ai/recraft/v4/svg`
Same payload as above. Response includes SVG file URL.

**Ideogram V3 (logos with text, any asset with text):**
```json
{
  "prompt": "Logo reading 'NEXUS' in bold geometric sans-serif, dark blue #1A237E on white",
  "image_size": "1024x1024",
  "num_images": 1
}
```

**FLUX.2 Flex (splash screens, feature graphics — flexible resolution):**
Endpoint: `fal-ai/flux-2-flex`
```json
{
  "prompt": "...",
  "image_size": {"width": 1125, "height": 2436},
  "num_inference_steps": 20,
  "guidance_scale": 10,
  "num_images": 1,
  "seed": 42
}
```

**FLUX.1 Schnell (rapid prototyping):**
Endpoint: `fal-ai/flux/schnell`
```json
{
  "prompt": "...",
  "image_size": "square",
  "num_images": 4
}
```
Note: Schnell ignores `guidance_scale` and `num_inference_steps` — it uses 1-4 steps internally.

**Nano Banana 2 (onboarding illustrations, character scenes):**
Endpoint: `fal-ai/nano-banana/v2`
```json
{
  "prompt": "...",
  "image_size": {"width": 1080, "height": 1920},
  "num_images": 1
}
```

**Image-to-Image refinement:**
Endpoint: `fal-ai/flux/dev/image-to-image`
```json
{
  "prompt": "Polish this icon, sharpen edges, improve symmetry, clean up artifacts",
  "image_url": "https://v3.fal.media/files/.../generated.png",
  "strength": 0.3,
  "num_inference_steps": 20,
  "guidance_scale": 7.5
}
```

**Background removal (for transparent icons/stickers):**
Endpoint: `fal-ai/bria/rmbg/v2` (general) or `fal-ai/birefnet` (fine detail)
```json
{
  "image_url": "https://v3.fal.media/files/.../icon.png"
}
```

**Upscaling:**
Endpoint: `fal-ai/aura-sr/v2`
```json
{
  "image_url": "https://v3.fal.media/files/.../icon.png"
}
```

**Image-to-Video (animated splash / promo):**
Endpoint: `fal-ai/kling-video/v3/image-to-video`
```json
{
  "prompt": "Gentle floating animation, particles rising slowly, smooth loop",
  "image_url": "https://v3.fal.media/files/.../splash.png",
  "duration": 5
}
```

### Getting Model Schema

When unsure about a model's exact parameters, fetch its OpenAPI schema:

```bash
MODEL="fal-ai/recraft/v4"
ENCODED=$(echo "$MODEL" | sed 's/\//%2F/g')
curl -s "https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=$ENCODED"
```

### Searching for Models

Discover the latest and best models:

```bash
bash scripts/search-models.sh --category "text-to-image"
bash scripts/search-models.sh --query "icon logo"
bash scripts/search-models.sh --query "upscale"
```

## Model Selection Guide

### By Asset Type

| Asset Type | Best Model | Endpoint | Why | Cost |
|---|---|---|---|---|
| App icon (no text) | Recraft V4 SVG | `fal-ai/recraft/v4/svg` | True vector, perfect scaling | $0.08 |
| App icon (with text) | Ideogram V3 | `fal-ai/ideogram/v3` | ~90% text accuracy | ~$0.05 |
| Logo (wordmark) | Ideogram V3 | `fal-ai/ideogram/v3` | Best text rendering | ~$0.05 |
| Logo (symbol) | Recraft V4 SVG | `fal-ai/recraft/v4/svg` | Clean scalable vectors | $0.08 |
| Splash screen | FLUX.2 Flex | `fal-ai/flux-2-flex` | Up to 4MP, flexible aspect | $0.05/MP |
| Onboarding | Nano Banana 2 | `fal-ai/nano-banana/v2` | Character consistency | $0.08 |
| Empty state | Recraft V4 | `fal-ai/recraft/v4` | Clean flat illustration | $0.04 |
| Achievement badge | Recraft V4 SVG | `fal-ai/recraft/v4/svg` | Crisp at small sizes | $0.08 |
| Feature graphic | FLUX.2 Flex | `fal-ai/flux-2-flex` | 1024×500 landscape | $0.05/MP |
| Notification icon | Recraft V4 SVG | `fal-ai/recraft/v4/svg` | White silhouette | $0.08 |
| Tab bar icon | Recraft V4 SVG | `fal-ai/recraft/v4/svg` | Consistent stroke weight | $0.08 |
| Favicon | Recraft V4 SVG | `fal-ai/recraft/v4/svg` | Crisp at 16px | $0.08 |
| Rapid prototyping | FLUX.1 Schnell | `fal-ai/flux/schnell` | Sub-second | $0.025 |
| Photorealistic BG | Nano Banana Pro | `fal-ai/nano-banana/pro` | Premium quality | $0.15 |
| Video splash | Kling 3.0 | `fal-ai/kling-video/v3/image-to-video` | Best video quality | $0.28/sec |

### Text Rendering: Critical Knowledge

**DO use these for any asset with text:**
- **Ideogram V3** — ~90% spelling accuracy, best overall
- **Recraft V4** — excellent design-context typography
- **FLUX.2 Flex** — strongest in Flux family
- **Nano Banana 2** — good multi-language support

**DO NOT use these for text:**
- FLUX.1 Schnell — fast but mangles text
- FLUX.1 Dev — inconsistent text
- SDXL — historically terrible at typography

If the asset has ANY readable text, use Ideogram V3 or Recraft V4.

## Using the Scripts

### Generate Any Asset

```bash
# Generate an app icon (queue mode — default, reliable)
bash scripts/generate.sh \
  --prompt "Minimal flat design camera icon, geometric, blue gradient #4285F4, centered, white background, no text" \
  --model "fal-ai/recraft/v4/svg" \
  --size square

# Generate a splash screen
bash scripts/generate.sh \
  --prompt "Abstract gradient background, deep purple to dark blue, centered glowing orb, minimal" \
  --model "fal-ai/flux-2-flex" \
  --size portrait

# Generate a logo with text
bash scripts/generate.sh \
  --prompt "Modern wordmark logo reading 'NEXUS' in bold geometric sans-serif, dark blue on white" \
  --model "fal-ai/ideogram/v3" \
  --size square

# Quick prototype (sub-second)
bash scripts/generate.sh \
  --prompt "Flat rocket icon concept" \
  --model "fal-ai/flux/schnell" \
  --size square

# Image-to-video (animated splash)
bash scripts/generate.sh \
  --prompt "Gentle floating particles, smooth breathing animation" \
  --model "fal-ai/kling-video/v3/image-to-video" \
  --image-url "https://v3.fal.media/files/.../splash.png"
```

### Generate Platform Bundle (All Sizes)

After generating a master icon, resize it for all platforms:

```bash
python scripts/generate_bundle.py \
  --asset-type app-icon \
  --prompt "Minimal flat rocket icon, blue gradient, centered" \
  --platforms ios android web \
  --output-dir ./assets/
```

Or resize an existing image:

```bash
python scripts/generate_bundle.py \
  --asset-type app-icon \
  --source ./my-icon-1024.png \
  --platforms ios android web \
  --output-dir ./assets/
```

**Output structure:**
```
assets/
├── master_source.png          (1024×1024 generated master)
├── ios/
│   ├── AppStore_1024.png      (1024×1024)
│   ├── iPhone_180@3x.png      (180×180)
│   ├── iPhone_120@2x.png      (120×120)
│   └── ...all iOS sizes
├── android/
│   ├── play_store.png         (512×512)
│   ├── mipmap-xxxhdpi.png     (192×192)
│   ├── mipmap-xxhdpi.png      (144×144)
│   ├── mipmap-xhdpi.png       (96×96)
│   ├── mipmap-hdpi.png        (72×72)
│   ├── mipmap-mdpi.png        (48×48)
│   └── adaptive/              (foreground layers for adaptive icons)
├── web/
│   ├── favicon.ico            (16, 32, 48 bundled)
│   ├── apple-touch-icon.png   (180×180)
│   ├── icon-192.png           (192×192)
│   └── icon-512.png           (512×512)
└── manifest.json              (generation metadata)
```

## Present Results to User

**Images:**
```
![Generated Icon](https://v3.fal.media/files/...)
• 1024×1024 | Model: Recraft V4 SVG | Generated in 2.2s
```

**Videos:**
```
[Click to view animated splash](https://v3.fal.media/files/.../video.mp4)
• Duration: 5s | Model: Kling 3.0 | Generated in 45s
```

## Prompting Strategy

Read `references/prompting.md` for the full prompt library with dozens of copy-paste examples. Core principles:

### Universal Prompt Template
```
[SUBJECT first — what the icon depicts]
[STYLE — flat design, vector, isometric, etc.]
[COLOR — hex codes for brand consistency]
[COMPOSITION — centered, leave space, etc.]
[EXCLUSIONS — no text, no borders, no shadows]
```

### Guidance Scale (CFG) by Asset Type

| Asset Type | CFG | Notes |
|---|---|---|
| Icons | 7-12 | Balance adherence and quality |
| Logos with text | 14-18 | Strict for text legibility |
| Illustrations | 5-10 | Creative freedom |
| Splash screens | 8-12 | Balanced |
| Photorealistic | 3.5-5 | Lower = better realism |
| Flux 2 (short prompt) | 3-5 | Flux-specific default: 4.5 |
| Flux 2 (long prompt) | 1-2 | Detailed Flux prompts |

### Consistency Across Asset Sets

When generating multiple assets for the same app:
1. **Lock your style string** — use the exact same words across all prompts
2. **Use seeds** — note the seed from success, use seed+1, seed+2 for variants
3. **Hex codes always** — "blue" is ambiguous, "#4285F4" is exact
4. **Recraft color arrays** — pass `"colors": [[66,133,244],[52,168,83]]` to enforce palette
5. **Image-to-image** — use approved icon as reference for splash/onboarding

### Image-to-Image Strength Reference

| Strength | Effect | Use Case |
|---|---|---|
| 0.15-0.25 | Touch-ups | Fix artifacts, sharpen edges |
| 0.25-0.35 | Polish | Clean up without major changes |
| 0.35-0.50 | Moderate shift | Style adjustment, composition holds |
| 0.50-0.65 | Transform | Reinterpret while keeping bones |
| 0.65+ | Redesign | Major changes |

## Reference Files

Read these for deeper information:

- **`references/models.md`** — Complete model catalog: every model, endpoint, pricing, capabilities, API parameters
- **`references/platform-specs.md`** — Exact pixel dimensions for every asset type on iOS, Android, Web/PWA
- **`references/prompting.md`** — Full prompt library with copy-paste templates for every asset type, negative prompts, common mistakes

## Extension Points

This skill is designed to grow:

- **LoRA fine-tuning**: Train on your brand style → `fal-ai/flux-2-dev-trainer`
- **Batch generation**: Use `fal_client.submit()` for parallel async generation
- **App category templates**: Pre-built prompt sets for fitness, finance, social, food apps
- **CI/CD integration**: Auto-generate assets in build pipelines
- **A/B testing**: Generate multiple icon variants for user testing
- **Localization**: Text assets in multiple languages via Ideogram V3
- **3D/AR assets**: Extend as Fal.ai adds 3D model generation → `fal-ai/triposr`

## Self-Healing & Reliability

All scripts include built-in resilience features that handle transient failures automatically.

### Automatic Retry

Every HTTP request retries up to 3 times with exponential backoff (1s, 2s, 4s) on:
- Network errors (DNS, connection refused, timeout)
- HTTP 429 (rate limited)
- HTTP 5xx (server errors)

Non-retryable 4xx errors (bad request, auth failure) fail immediately.

### Curl Timeouts

All requests include `--connect-timeout 10` and `--max-time 120` to prevent indefinite hangs. Status polling uses shorter timeouts (`--max-time 30`).

### Model Fallback Chains

When a model fails, `generate.sh` automatically tries alternatives:

| Primary | Fallback 1 | Fallback 2 |
|---------|-----------|-----------|
| `recraft/v4/svg` | `recraft/v4` | `recraft-v3/svg` |
| `recraft/v4` | `recraft-v3` | `flux-2-flex` |
| `ideogram/v3` | `ideogram/v2a` | `recraft/v4` |
| `flux-2-flex` | `flux/dev` | `flux/schnell` |
| `nano-banana/v2` | `nano-banana` | `flux-2-flex` |

Disable with `--no-fallback` to fail on the primary model only.

### API Health Check

Test connectivity before submitting jobs:

```bash
bash scripts/generate.sh --health-check
```

Verifies network reachability and API key validity.

### JSON Safety

Prompts containing quotes, backslashes, and newlines are automatically escaped before JSON embedding. This prevents payload corruption from special characters in user prompts.

### Output Validation

After generation completes, the result is validated to confirm it contains actual media URLs before reporting success.

### Safe `.env` Loading

The `.env` file is parsed line-by-line (matching `KEY=VALUE` patterns only) rather than shell-executed. This prevents arbitrary code execution from malformed `.env` files.

### Cleanup on Failure

Temporary files created during execution are automatically cleaned up on exit, interruption (Ctrl+C), or termination.

## Troubleshooting

### API Key Error
```
Error: FAL_KEY not set
```
Run: `export FAL_KEY=your_key_here` or add to `.env` file.

### Timeout on Video
Video generation takes 30-60+ seconds. Use queue mode (default) or `--async` flag, then poll with `--status`. Increase timeout with `--timeout 900` for very long jobs.

### Rate Limiting (429)
Automatic retry handles transient rate limits. If persistent, wait a few minutes or check your Fal.ai plan limits at https://fal.ai/dashboard.

### Model Unavailable
If a model returns errors, the fallback chain will automatically try alternatives. To force a specific model, use `--no-fallback`. Check model availability with `--health-check`.

### Text Rendering Issues
If text is garbled: switch to Ideogram V3. If text is close but slightly wrong: try again with the exact same prompt (different seed). Keep text to 1-4 words.

### Network Error (claude.ai)
Go to `claude.ai/settings/capabilities` and add `*.fal.ai` to allowed domains.

### Image Too Small
Use upscaling: `fal-ai/aura-sr/v2` for 4× resolution increase with minimal artifacts.

### Icon Rejected by App Store
- iOS: Must be exactly 1024×1024 PNG, no alpha channel, no transparency
- Android: Must be exactly 512×512, no alpha
- Both: No rounded corners baked in (platforms apply their own masks)
