# Fal.ai Model Reference — Complete Catalog

## Table of Contents
1. [Text-to-Image Models](#text-to-image-models)
2. [Image-to-Image Models](#image-to-image-models)
3. [Image-to-Video Models](#image-to-video-models)
4. [Enhancement & Utility Models](#enhancement--utility-models)
5. [Pricing Summary](#pricing-summary)
6. [Model Selection Matrix](#model-selection-matrix)

---

## Text-to-Image Models

### FLUX Family (Black Forest Labs)

#### FLUX.2 Series (Latest Generation)

**FLUX.2 Pro** — `fal-ai/flux-pro/v1.1`
- Premium model, maximum quality, exceptional photorealism
- Best for: photorealistic backgrounds, hero images
- Cost: ~$0.05/image

**FLUX.2 Flex** — `fal-ai/flux-2-flex`
- Advanced multi-purpose with full parameter control
- Resolution: 0.5MP to 4MP adaptive scaling
- Output: WebP, JPG, PNG (with transparency)
- Inference steps: 10-50 (configurable)
- Strongest text rendering in Flux family
- Supports up to 10 reference images (14MP combined input)
- Cost: $0.05/MP
- Best for: splash screens, feature graphics, flexible resolution work

**FLUX.2 Dev** — `fal-ai/flux-2-dev`
- Developer-focused, good baseline quality
- Cost: ~$0.025/image

#### FLUX.1 Series

**FLUX.1 Pro v1.1** — `fal-ai/flux-pro/v1.1`
- Enhanced composition and detail
- Cost: ~$0.05/image

**FLUX.1 Dev** — `fal-ai/flux/dev`
- 12B parameter flow transformer
- Good baseline quality, moderate speed
- Cost: $0.025/image

**FLUX.1 Schnell** — `fal-ai/flux/schnell`
- Ultra-fast: sub-second generation
- Inference steps: 1-4 (default: 4)
- Cost: $0.025/image
- Best for: rapid prototyping, iteration, testing prompts

#### FLUX.1 Specialized Tools

| Model | Endpoint | Use Case |
|---|---|---|
| FLUX.1 Pro Fill | `fal-ai/flux-pro/v1/fill` | Inpainting, content completion |
| FLUX.1 Pro Canny | `fal-ai/flux-pro/v1/canny` | Edge-guided composition |
| FLUX.1 Pro Depth | `fal-ai/flux-pro/v1/depth` | Depth-guided generation |
| FLUX.1 Dev Redux | `fal-ai/flux/dev/redux` | Style transfer |
| FLUX.1 Schnell Redux | `fal-ai/flux/schnell/redux` | Fast style transfer |
| FLUX.1 Pro Kontext | `fal-ai/flux-pro/kontext` | Reference image + text editing |

#### FLUX LoRA Support

| Model | Endpoint | Notes |
|---|---|---|
| FLUX.1 Dev + LoRA | `fal-ai/flux-lora` | Merge multiple LoRAs |
| FLUX.2 Dev LoRA | `fal-ai/flux-2-dev-lora` | Text-to-image with LoRA |
| FLUX.2 Dev Trainer | `fal-ai/flux-2-dev-trainer` | Fine-tune on your visual style |
| Z-Image Turbo LoRA | `fal-ai/z-image-turbo-lora` | Ultra-fast, up to 3 style adapters |

---

### Recraft (Best for Design Assets)

**Recraft V4 Text-to-Image** — `fal-ai/recraft/v4`
- Highest-ranked on HuggingFace T2I Benchmark (ELO: 1172+)
- Built specifically for designers: composition, lighting, materials
- Supports color palette constraints (RGB array input)
- Standard: 1024×1024, $0.04/image
- Pro: 2048×2048, $0.25/image
- Best for: empty state illustrations, branded assets, flat design

**Recraft V4 SVG (Vector)** — `fal-ai/recraft/v4/svg`
- Generates TRUE SVG vector files with editable paths
- Not rasterized — actual vector geometry
- Import directly into Figma, Illustrator, Sketch
- Standard: $0.08/image
- Pro: $0.30/image (2048×2048 equivalent)
- Best for: app icons, logos, notification icons, tab bar icons, achievement badges

**Recraft V3** — `fal-ai/recraft-v3`
- Still excellent, lower cost alternative to V4
- Supports style specification: realistic, digital_illustration, vector_illustration
- Good text rendering
- V3 SVG endpoint: `fal-ai/recraft-v3/svg`

**Recraft Parameters**:
```python
{
    "prompt": "...",
    "style": "vector_illustration",  # or "realistic", "digital_illustration"
    "colors": [[44, 62, 80], [231, 76, 60]],  # RGB palette enforcement
    "background_color": [255, 255, 255],  # Background color
    "image_size": {"width": 1024, "height": 1024}
}
```

---

### Ideogram (Best for Text in Images)

**Ideogram V3** — `fal-ai/ideogram/v3`
- Near-perfect spelling accuracy on multi-word phrases (~90%)
- Best model for ANY asset containing readable text
- Excellent for: logos with wordmarks, app names in splash screens, badges with labels
- Cost: ~$0.05/image

**Ideogram V2A** — `fal-ai/ideogram/v2a`
- Faster, more affordable variant
- Still excellent text accuracy
- Good for rapid iteration on text-heavy designs

**Prompting tips for Ideogram text**:
- Quote the text explicitly: `reads 'OPEN'` not `has text saying open`
- Specify font style: "elegant serif", "modern sans-serif", "bold condensed"
- Keep text short: 1-6 words for highest accuracy
- Describe text placement: "text centered below icon, uppercase"

---

### Nano Banana Series (Google Gemini-based)

**Nano Banana 2** — `fal-ai/nano-banana/v2`
- Built on Google Gemini 3.1 Flash Image
- Reasons about composition, lighting, spatial relationships
- Treats prompts as multimodal language (not keyword matching)
- Vibrant output with rich color and punchy contrast
- Strong text rendering and multi-language support
- Character consistency across up to 5 people
- Resolution: 1K/2K/4K
- Cost: $0.08/image
- Best for: onboarding illustrations, character-based screens, vibrant marketing assets

**Nano Banana Pro** — `fal-ai/nano-banana/pro`
- Google Gemini 3 Pro Image (most advanced)
- Production-quality visuals with deep semantic understanding
- Cost: $0.15/image
- Best for: premium commercial work, hero images

**Nano Banana (Original)** — `fal-ai/nano-banana`
- Budget option
- Cost: $0.039/image

---

### Imagen Series (Google DeepMind)

**Imagen3** — `fal-ai/imagen3`
- High-quality photorealistic generation
- Good text rendering (readable signage, typography)
- Diverse art style support including animation
- Cost: $0.05/image

**Imagen3 Fast** — `fal-ai/imagen3/fast`
- Speed-optimized variant
- Cost: $0.03/image

**Imagen4** — `fal-ai/imagen4` (Preview)
- Next generation, capabilities TBD

---

### Other Notable Models

**GPT-Image 1.5** — `fal-ai/gpt-image-1`
- Variable pricing: Low $0.009, Medium $0.034-$0.051
- Strong text rendering
- Good budget option for simple assets

**Z-Image Turbo** — `fal-ai/z-image-turbo`
- 6B parameter model, sub-second generation
- Great for rapid iteration

**Z-Image Turbo LoRA** — `fal-ai/z-image-turbo-lora`
- Cost: $0.0085/MP, 4 images per request
- Cheapest per-image option when doing batch work

---

## Image-to-Image Models

### Standard Image-to-Image

Most text-to-image models have image-to-image variants. Append `/image-to-image` to the endpoint:
- `fal-ai/flux/dev/image-to-image`
- `fal-ai/flux/schnell/image-to-image`

**Key Parameters**:
```python
{
    "prompt": "Refine this icon, sharpen edges",
    "image_url": "https://...",
    "strength": 0.3,  # 0.0 = no change, 1.0 = complete regen
    "num_inference_steps": 20,
    "guidance_scale": 7.5
}
```

### Strength Reference Table

| Strength | Effect | Use Case |
|---|---|---|
| 0.15-0.25 | Minimal touch-ups | Fix small artifacts, sharpen |
| 0.25-0.35 | Polish and clean | Clean up without major changes |
| 0.35-0.50 | Moderate refinement | Style shift, enhance details |
| 0.50-0.65 | Style transformation | Reinterpret while keeping structure |
| 0.65-0.85 | Major redesign | Significant changes |

### ControlNet Models

| Type | Endpoint | Use Case |
|---|---|---|
| Canny (Edge) | `fal-ai/flux-pro/v1/canny` | Preserve line structure of icons |
| Depth | `fal-ai/flux-pro/v1/depth` | Maintain spatial layout |
| IP-Adapter | via FLUX General I2I | Blend style from reference image |

### Inpainting

| Model | Endpoint | Notes |
|---|---|---|
| FLUX Pro Fill | `fal-ai/flux-pro/v1/fill` | High-quality region editing |
| FLUX Dev Inpaint | `fal-ai/flux/dev/inpainting` | Developer-friendly |

**Mask convention**: White = inpaint region, Black = preserve

---

## Image-to-Video Models

### Kling (Kuaishou) — Premium Choice

**Kling 3.0** — `fal-ai/kling-video/v3/image-to-video`
- Duration: 3-15 seconds
- Resolution: up to 1080p
- Native audio generation
- Multi-shot storyboarding
- Cost: $0.224/sec (no audio), $0.28/sec (with audio)
- Best for: app preview videos, animated splash screens

**Kling 2.1 Variants**:
- Standard: `fal-ai/kling-video/v2.1/standard/image-to-video` — budget
- Pro: `fal-ai/kling-video/v2.1/pro/image-to-video` — professional
- Master: `fal-ai/kling-video/v2.1/master/image-to-video` — premium cinematic

### Google Veo

**Veo 3.1** — `fal-ai/veo3.1/image-to-video`
- Resolution: 720p/1080p/4K
- Duration: 4-8 seconds
- Cost: $0.20/sec (720-1080p no audio) to $0.60/sec (4K with audio)
- Character identity maintained frame-to-frame

### Others

| Model | Endpoint | Cost | Notes |
|---|---|---|---|
| Hailuo 2.3 | `fal-ai/hailuo/2.3/image-to-video` | ~$0.49/video | Simple API, good motion |
| Sora 2 Pro | `fal-ai/sora/v2/pro` | $0.30-$0.50/sec | Up to 25 seconds |
| Wan Alpha | `fal-ai/wan/alpha` | Varies | Transparent background video |
| Pixverse v5.5 | `fal-ai/pixverse/v5.5` | Varies | Text + image to video |

---

## Enhancement & Utility Models

### Background Removal

| Model | Endpoint | Best For |
|---|---|---|
| Bria RMBG 2.0 | `fal-ai/bria/rmbg/v2` | General background removal, clean output |
| BiRefNet | `fal-ai/birefnet` | Fine detail (hair, glass, semi-transparent) |
| RemBG | `fal-ai/rembg` | Standard removal |

### Upscaling

| Model | Endpoint | Notes |
|---|---|---|
| AuraSR v2 | `fal-ai/aura-sr/v2` | Fal's proprietary, best quality, fewest artifacts |
| RealESRGAN | `fal-ai/esrgan` | Standard ESRGAN upscaling |

---

## Pricing Summary

### Image Generation (sorted by cost)

| Model | Cost | Speed | Quality |
|---|---|---|---|
| Z-Image Turbo LoRA | $0.0085/MP | Ultra-fast | Good |
| GPT-Image 1.5 (low) | $0.009 | Fast | Basic |
| FLUX.1 Schnell | $0.025 | Sub-second | Good |
| FLUX.1 Dev | $0.025 | Moderate | Good |
| Imagen3 Fast | $0.03 | Fast | Good |
| GPT-Image 1.5 (med) | $0.034-0.051 | Moderate | Good |
| Nano Banana (original) | $0.039 | Fast | Good |
| Recraft V4 Standard | $0.04 | Moderate | Excellent |
| FLUX.2 Flex | $0.05/MP | Variable | Excellent |
| Imagen3 | $0.05 | Moderate | Excellent |
| Ideogram V3 | ~$0.05 | Moderate | Excellent (text) |
| Nano Banana 2 | $0.08 | Moderate | Excellent |
| Recraft V4 SVG | $0.08 | Moderate | Excellent (vector) |
| Nano Banana Pro | $0.15 | Slower | Premium |
| Recraft V4 Pro | $0.25 | Slower | Premium (2048px) |
| Recraft V4 SVG Pro | $0.30 | Slower | Premium (vector) |

### Video Generation (sorted by cost per second)

| Model | Cost | Duration | Max Resolution |
|---|---|---|---|
| Veo 3.1 (no audio) | $0.20/sec | 4-8s | 1080p |
| Kling 3.0 (no audio) | $0.224/sec | 3-15s | 1080p |
| Kling 3.0 (audio) | $0.28/sec | 3-15s | 1080p |
| Sora 2 Pro | $0.30-0.50/sec | Up to 25s | 1080p |
| Veo 3.1 (audio) | $0.40/sec | 4-8s | 1080p |
| Hailuo 2.3 | ~$0.49/video | Standard | 512p-1080p |
| Veo 3.1 4K | $0.40-0.60/sec | 4-8s | 4K |

**Billing**: Pay-as-you-go, no minimums, no subscriptions required.

---

## Model Selection Matrix

### Quick Reference: "Which model for my asset?"

```
Asset has text? ─── YES ──→ Ideogram V3 (or Recraft V4 for design context)
       │
       NO
       │
Need vector/SVG? ── YES ──→ Recraft V4 SVG
       │
       NO
       │
Photorealistic? ─── YES ──→ FLUX.2 Pro or Nano Banana Pro
       │
       NO
       │
Flat/illustration? ─ YES ──→ Recraft V4 Standard
       │
       NO
       │
Budget priority? ─── YES ──→ FLUX.1 Schnell ($0.025)
       │
       NO
       │
Default ──────────────────→ FLUX.2 Flex (most versatile)
```

### API Authentication

All requests require the `FAL_KEY` environment variable or header:

```python
# Option 1: Environment variable (recommended)
import os
os.environ["FAL_KEY"] = "your-key-here"

# Option 2: Direct header
# Authorization: Key YOUR_API_KEY
```

### Common API Call Pattern

```python
import fal_client

# Synchronous (waits for result)
result = fal_client.subscribe(
    "fal-ai/recraft/v4",
    arguments={
        "prompt": "...",
        "image_size": {"width": 1024, "height": 1024},
        "num_images": 1,
    }
)
image_url = result["images"][0]["url"]

# Asynchronous (returns immediately, poll for result)
handler = fal_client.submit(
    "fal-ai/recraft/v4",
    arguments={...}
)
result = handler.get()  # blocks until done
```
