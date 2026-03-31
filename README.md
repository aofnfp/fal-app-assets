# App Asset Forge

One-stop AI skill for generating production-ready app assets using [Fal.ai](https://fal.ai) — icons, logos, splash screens, onboarding illustrations, empty states, achievement badges, favicons, notification icons, tab bar icons, feature graphics, and more.

Covers **iOS**, **Android**, and **Web/PWA** with platform-correct sizes and formats.

## What's Inside

```
app-asset-forge/
├── SKILL.md                    — Main skill (model selection, API calls, asset education)
├── references/
│   ├── models.md               — Full Fal.ai model catalog with pricing & endpoints
│   ├── platform-specs.md       — Exact pixel dimensions for iOS/Android/Web
│   └── prompting.md            — Prompt library with copy-paste templates
├── scripts/
│   ├── generate.sh             — Generate any asset via Fal.ai queue API
│   ├── generate_bundle.py      — Resize master image into all platform sizes
│   ├── upload.sh               — Upload local files to Fal CDN
│   └── search-models.sh        — Discover Fal.ai models
└── app-asset-forge.skill       — Packaged skill file for one-click install
```

## Supported Asset Types

| Asset Type | Best Model | Output |
|---|---|---|
| App icon (no text) | Recraft V4 SVG | True vector SVG |
| App icon (with text) | Ideogram V3 | PNG |
| Logo (wordmark) | Ideogram V3 | PNG |
| Logo (symbol) | Recraft V4 SVG | SVG |
| Splash screen | FLUX.2 Flex | PNG up to 4MP |
| Onboarding illustration | Nano Banana 2 | PNG |
| Empty state | Recraft V4 | PNG |
| Achievement badge | Recraft V4 SVG | SVG |
| Notification icon | Recraft V4 SVG | White silhouette SVG |
| Feature graphic | FLUX.2 Flex | PNG 1024x500 |
| Tab bar icon | Recraft V4 SVG | SVG |
| Favicon | Recraft V4 SVG | SVG + ICO bundle |

## Quick Start

1. Get a Fal.ai API key at https://fal.ai/dashboard/keys
2. `export FAL_KEY=your_key_here`
3. Generate an icon:

```bash
bash scripts/generate.sh \
  --asset-type icon \
  --prompt "Minimal flat design rocket icon, blue gradient, centered, no text"
```

4. Generate all platform sizes:

```bash
pip install Pillow --break-system-packages
python scripts/generate_bundle.py \
  --asset-type app-icon \
  --source ./master_icon.png \
  --platforms ios android web \
  --output-dir ./assets/
```

## Installation

**Claude Code:** `claude install-skill ./app-asset-forge.skill`

**Claude.ai Projects:** Upload `SKILL.md` + reference files as Project Knowledge

**Manual:** Copy the `app-asset-forge/` folder into `.claude/skills/` in your project

## License

MIT
