# Prompt Library & Strategies

Complete prompting guide for generating app assets with Fal.ai models.

## Table of Contents
1. [Universal Prompt Structure](#universal-prompt-structure)
2. [App Icon Prompts](#app-icon-prompts)
3. [Logo Prompts](#logo-prompts)
4. [Splash Screen Prompts](#splash-screen-prompts)
5. [Onboarding Screen Prompts](#onboarding-screen-prompts)
6. [Empty State Prompts](#empty-state-prompts)
7. [Achievement Badge Prompts](#achievement-badge-prompts)
8. [Notification Icon Prompts](#notification-icon-prompts)
9. [Feature Graphic Prompts](#feature-graphic-prompts)
10. [Negative Prompt Reference](#negative-prompt-reference)
11. [Parameter Cheat Sheet](#parameter-cheat-sheet)
12. [Consistency Techniques](#consistency-techniques)
13. [Common Mistakes](#common-mistakes)

---

## Universal Prompt Structure

Every asset prompt follows this skeleton. Order matters — Flux models weight earlier tokens more heavily.

```
[1. SUBJECT]    What the image depicts — put this FIRST
[2. STYLE]      Design approach (flat, vector, isometric, etc.)
[3. COLOR]      Specific colors or palette (hex codes when possible)
[4. COMPOSITION] Layout, spacing, centering, empty zones
[5. TECHNICAL]  Resolution, format constraints, exclusions
```

**Golden rules**:
- Subject first, always
- Be specific about style — "flat design" not "nice looking"
- Use hex codes for brand colors
- State what you DON'T want explicitly
- 3-5 sentences is the sweet spot. More causes noise, less causes randomness

---

## App Icon Prompts

### Template
```
Minimal [STYLE] [OBJECT] icon for [APP_TYPE] app,
[SHAPE_DESCRIPTION], [COLOR_PALETTE],
centered on clean [BACKGROUND_COLOR] background,
1024x1024, vector style, no text, no borders, no shadows
```

### Style Variants

**Flat Design** (most common for modern apps):
```
Minimal flat design camera icon for a photography app,
geometric shapes, soft gradient from #4285F4 to #34A853,
centered on clean white background,
1024x1024, no text, no borders, no shadows, no gradients on shapes
```

**3D / Glossy** (for playful/consumer apps):
```
3D glossy shopping bag icon with soft shadows,
rounded corners, vibrant coral #FF6B6B with white highlights,
centered, subtle depth, clean background,
1024x1024, no text, polished render
```

**Outline / Stroke** (for minimalist apps):
```
Minimalist single-line compass icon,
thin 2px stroke, dark navy #1A1A2E,
continuous line art style, centered on white background,
1024x1024, monoline, no fill, no text
```

**Isometric** (for productivity/tech apps):
```
Isometric 3D cube icon with calendar grid pattern,
soft blue #6C63FF and light purple #A29BFE,
gentle shadows, clean geometric style, centered,
1024x1024, no text, subtle depth
```

**Glyph / Silhouette** (for system/utility apps):
```
Solid glyph settings gear icon,
single color white on transparent background,
consistent stroke weight, perfectly centered,
1024x1024, no gradients, no shadows, pure silhouette
```

**Duotone**:
```
Duotone music note icon,
primary #FF6B35 and secondary #004E89,
flat design, geometric, centered on white,
1024x1024, no text, sharp edges, two-tone only
```

### App Category Examples

**Fitness App**:
```
Minimal flat design dumbbell icon with heartbeat line,
vibrant green #00C853 gradient, rounded geometric shapes,
centered on white background, energetic and modern,
1024x1024, no text, no borders
```

**Finance App**:
```
Professional minimal chart icon with upward arrow,
dark blue #0D47A1 and gold #FFD600 accent,
geometric clean lines, centered on white,
1024x1024, no text, corporate style, sharp
```

**Social App**:
```
Friendly speech bubble icon with smile curve,
warm gradient from #FF6B6B to #FFA06B,
rounded corners, playful and inviting, centered,
1024x1024, no text, soft shadows
```

**Food / Recipe App**:
```
Minimal flat design chef hat with fork silhouette,
warm orange #FF8C00 and cream #FFF8E1,
centered, rounded shapes, friendly,
1024x1024, no text, clean background
```

---

## Logo Prompts

### Wordmark (Text-Only Logo)
**Model: Ideogram V3** (required for text accuracy)

```
Elegant wordmark logo reading 'AURA',
modern sans-serif typeface, wide letter-spacing,
pure black text on white background,
sharp edges, minimalist, horizontal layout,
1024x1024, no icons, no decorations
```

### Lettermark (Initials)
**Model: Ideogram V3 or Recraft V4**

```
Professional lettermark logo using initials 'TK',
geometric sans-serif font, interlocking design,
black and gold #C9A84C colors, corporate style,
centered on white background, 1024x1024, clean
```

### Pictorial (Symbol)
**Model: Recraft V4 SVG** (for scalability)

```
Minimalist geometric bird logo,
single continuous line, modern tech company aesthetic,
dark blue #1A237E, circular composition,
centered, vector style, no text, 1024x1024
```

### Abstract Mark
**Model: Recraft V4 SVG**

```
Abstract geometric mark for tech startup,
interlocking circles and curves forming infinity shape,
primary #FF6B35 and secondary #004E89,
flat design, no text, centered, 1024x1024
```

### Combination (Icon + Text)
**Model: Ideogram V3** (for text), then composite

```
Logo combining minimalist coffee cup icon with text 'BREW & CO',
sans-serif font, warm brown #5D4037 and cream #EFEBE9,
horizontal layout, icon left text right,
clean white background, vector-ready, 1024x1024
```

### Logo Tips
- Keep text to 1-4 words maximum for highest accuracy
- Use Ideogram V3 for ANY logo with readable text
- Use Recraft V4 SVG for symbolic logos (no text) — get true vectors
- Specify exact font personality: "bold condensed sans-serif" not just "nice font"
- For combination marks, consider generating icon and text separately, then compositing

---

## Splash Screen Prompts

### App Launch Splash
```
Clean splash screen background with subtle gradient,
from deep purple #1A0030 to dark blue #000033,
centered minimal [APP_ICON_DESCRIPTION] at 40% scale,
leave bottom 25% empty for loading indicator,
1125x2436 vertical, no text, smooth transitions
```

### Illustrated Splash
```
Flat illustration splash screen for wellness app,
serene mountain landscape with sunrise,
soft gradient sky from peach #FFAB91 to light blue #B3E5FC,
leave top 20% blank for logo, bottom 30% for tagline,
1125x2436 vertical, minimal detail, dreamy atmosphere
```

### Geometric / Pattern Splash
```
Abstract geometric pattern splash screen,
overlapping circles and arcs in brand colors #6C63FF and #FF6584,
dark background #1A1A2E, subtle depth,
centered composition with open space for logo overlay,
1125x2436 vertical, no text
```

---

## Onboarding Screen Prompts

### Template
```
[STYLE] illustration for [APP_NAME] onboarding,
showing [SUBJECT/SCENE],
[EMOTIONAL_TONE], color palette [HEX_COLORS],
leave bottom 30% empty for text and CTA button,
1080x1920 vertical, no text elements, clean composition
```

### Onboarding Series (3-screen example)

**Screen 1 — Welcome/Discovery**:
```
Flat illustration for fitness app onboarding screen 1,
happy person discovering a treasure map with exercise icons,
playful and exciting, colors #00BCD4 cyan and #FF7043 coral,
leave bottom 30% empty for text overlay,
1080x1920 vertical, no text, friendly rounded character style
```

**Screen 2 — Core Feature**:
```
Flat illustration for fitness app onboarding screen 2,
person tracking workout progress on floating dashboard,
motivating and clear, colors #00BCD4 cyan and #FF7043 coral,
same character style as previous, leave bottom 30% empty,
1080x1920 vertical, no text
```

**Screen 3 — Call to Action**:
```
Flat illustration for fitness app onboarding screen 3,
person celebrating at finish line with confetti,
triumphant and encouraging, colors #00BCD4 cyan and #FF7043 coral,
same character style, leave bottom 30% empty,
1080x1920 vertical, no text
```

---

## Empty State Prompts

### Template
```
Friendly empty state illustration for [FEATURE],
minimal [STYLE] design, [SUBJECT/SCENE],
[COLOR_PALETTE], simple and clear,
centered composition, 800x800, no text
```

### Common Empty States

**Inbox Empty**:
```
Friendly empty state illustration for email inbox,
minimal flat design, cute mailbox with open door and no letters,
soft blue #90CAF9 and white, simple geometric style,
centered, 800x800, no text, gentle and inviting
```

**No Search Results**:
```
Minimal empty state for search results,
flat illustration of magnifying glass over empty landscape,
muted purple #B39DDB and gray #E0E0E0,
centered, 800x800, no text, clean background
```

**Empty Cart**:
```
Friendly empty state for shopping cart,
flat design shopping bag with dotted outline,
warm peach #FFAB91 and light gray,
centered, 800x800, no text, inviting to browse
```

**No Internet Connection**:
```
Minimal empty state for offline mode,
flat illustration of cloud with disconnected cable,
gray #9E9E9E and light blue #B3E5FC accent,
centered, 800x800, no text, friendly not alarming
```

**First-Time Use / Empty List**:
```
Welcoming empty state illustration,
flat design person planting a seed in empty garden,
green #66BB6A and earth brown #8D6E63,
centered, 800x800, no text, hopeful and encouraging
```

**Error State**:
```
Gentle error state illustration,
flat design robot with apologetic expression and wrench,
warm orange #FFA726 and gray #BDBDBD,
centered, 800x800, no text, approachable not scary
```

---

## Achievement Badge Prompts

### Template
```
Achievement badge icon for [ACHIEVEMENT],
[STYLE] design, [SYMBOL/OBJECT],
[COLOR_PALETTE], circular composition,
192x192, no text, bold and recognizable at small sizes
```

### Examples

**First Workout Complete**:
```
Achievement badge for first workout milestone,
flat design star with flexing arm silhouette,
gold #FFD600 and dark blue #1A237E,
circular composition, bold, 192x192, no text
```

**Streak Achievement**:
```
Achievement badge for 7-day streak,
flame icon with number 7 shape integrated,
vibrant orange #FF6D00 gradient to red #D50000,
circular, bold at small sizes, 192x192, no text
```

**Level Up**:
```
Achievement badge for level completion,
upward arrow breaking through ceiling,
electric purple #7C4DFF and gold #FFD600,
circular, dynamic, 192x192, no text
```

---

## Notification Icon Prompts

**Android notification icons must be white silhouettes on transparent background.**

### Template
```
Simple white silhouette icon of [OBJECT],
solid white #FFFFFF on transparent background,
minimal detail, recognizable at 24x24 pixels,
clean edges, no gradients, no shadows, no color,
96x96 PNG with alpha channel
```

### Examples

**Message Notification**:
```
Simple white silhouette of speech bubble,
solid white on transparent background,
minimal, clean edges, recognizable at 24px,
96x96, no gradients, no shadows
```

**Calendar Reminder**:
```
Simple white silhouette of calendar page,
solid white on transparent background,
minimal detail, bold outline, 96x96,
no gradients, no shadows, clean alpha
```

---

## Feature Graphic Prompts

**Android Play Store: 1024 × 500 px, no alpha**

### Template
```
App feature graphic for [APP_NAME],
[STYLE] design showing [KEY_VISUAL],
brand colors [HEX_CODES], horizontal layout,
1024x500 landscape, space for app name overlay on left,
vibrant, eye-catching, no text
```

### Example
```
Feature graphic for fitness tracking app,
gradient background from #6C63FF to #FF6584,
abstract geometric shapes suggesting movement and progress,
horizontal layout, open space on left third for title,
1024x500, vibrant, modern, no text
```

---

## Negative Prompt Reference

Not all models support negative prompts (Flux doesn't use them — describe what you want instead). For models that do:

### Universal Negative Prompt
```
text, writing, words, letters, typography, watermark, signature,
blurry, out of focus, low resolution, pixelated, jpeg artifacts,
extra details, cluttered, busy, borders, frame, drop shadow
```

### Icon-Specific Negatives
```
text, watermark, realistic photo, complex background,
multiple objects, gradients on shapes, 3D depth,
shadows, glow effects, lens flare
```

### Logo-Specific Negatives
```
photorealistic, complex scene, landscape, people, animals,
busy background, multiple colors beyond palette,
distorted text, misspelled text
```

### Illustration-Specific Negatives
```
photorealistic, uncanny valley, distorted faces,
extra limbs, malformed hands, inconsistent style,
text, watermark, logo, signature
```

---

## Parameter Cheat Sheet

### Guidance Scale (CFG) by Asset Type

| Asset Type | CFG Range | Default | Notes |
|---|---|---|---|
| Icons (no text) | 7-12 | 10 | Balance adherence and quality |
| Logos with text | 14-18 | 15 | Strict for text legibility |
| Illustrations | 5-10 | 7 | Allow creativity |
| Splash screens | 8-12 | 10 | Balance all aspects |
| Photorealistic | 3.5-5 | 4 | Lower = better realism |
| Flux 2 (short prompt) | 3-5 | 4 | Flux-specific |
| Flux 2 (detailed prompt) | 1-2 | 1.5 | Flux-specific |

### Inference Steps by Priority

| Priority | Steps | Speed | Quality |
|---|---|---|---|
| Rapid prototyping | 1-4 | Sub-second | Good enough |
| Standard production | 8-16 | 2-5 sec | Good |
| High quality | 20-30 | 5-15 sec | Excellent |
| Maximum quality | 30-50 | 15-30 sec | Premium |

### Image Size Recommendations

| Asset | Generation Size | Final Size |
|---|---|---|
| App icon | 1024×1024 | 1024×1024 (master) |
| Logo | 1024×1024 or 2048×2048 | Various |
| Splash screen | 1125×2436 or 1080×1920 | Device-specific |
| Feature graphic | 1024×512 | 1024×500 (crop) |
| Empty state | 800×800 | 400×400 dp |
| Achievement badge | 512×512 | 192×192 |
| Notification icon | 256×256 | 96×96 (xxxhdpi) |
| Favicon | 512×512 | 16-512 (various) |

---

## Consistency Techniques

### Same-Style Icon Sets

1. **Create a style string** and reuse it identically:
   ```
   STYLE = "minimal flat design, geometric shapes, 2px visual weight, rounded corners, brand blue #4285F4, clean white background, centered, no text, no shadows"
   ```

2. **Template each icon**:
   ```
   f"{SUBJECT} icon, {STYLE}, 1024x1024"
   ```

3. **Use sequential seeds**: seed=42 for first icon, seed=43 for second, etc.

4. **Image-to-image from reference**: Generate first icon, use it as reference for subsequent ones via IP-Adapter or Redux

### Brand Palette Enforcement

With **Recraft V4**, pass exact RGB values:
```python
{
    "colors": [[66, 133, 244], [52, 168, 83], [251, 188, 4]],
    "background_color": [255, 255, 255]
}
```

With other models, include hex codes in prompt:
```
brand colors #4285F4 blue and #34A853 green, no other colors
```

### Character Consistency (Onboarding Sets)

With **Nano Banana 2**, the model maintains character consistency across up to 5 people. For other models:
1. Generate first character illustration
2. Use image-to-image with low strength (0.2-0.3) for subsequent scenes
3. Reference the same character description in each prompt
4. Use IP-Adapter to maintain facial/body style

---

## Common Mistakes

### 1. Conflicting Style Terms
**Bad**: "Photorealistic flat design minimal icon"
**Good**: "Minimal flat design icon, geometric shapes"

Pick ONE primary style and stick with it.

### 2. Over-Detailed Prompts
**Bad**: "A beautiful, gorgeous, stunning, amazing, incredible flat design icon showing a breathtaking camera with extraordinary detail..."
**Good**: "Minimal flat design camera icon, blue gradient, centered, clean background"

Adjective soup confuses the model.

### 3. Using Wrong Model for Text
**Bad**: Generating "ACME Corp" logo with FLUX.1 Schnell
**Good**: Using Ideogram V3 for any asset with readable text

### 4. Forgetting Negative Constraints
**Bad**: "Camera icon" (might get text, borders, shadows, complex backgrounds)
**Good**: "Camera icon, no text, no borders, no shadows, clean background"

### 5. Wrong Aspect Ratio
**Bad**: Generating a splash screen at 1:1 square
**Good**: Specifying 9:16 vertical (1080×1920) for splash screens

### 6. Not Leaving Space for Text
**Bad**: Onboarding illustration that fills the entire frame
**Good**: "leave bottom 30% empty for text overlay and CTA button"

### 7. Baking in Corner Radius for iOS Icons
**Bad**: "rounded corners icon with iOS style border radius"
**Good**: "square icon, full bleed" (iOS applies masking automatically)

### 8. Generating at Too Low Resolution
**Bad**: 256×256 for an app icon
**Good**: 1024×1024 minimum for app icons, scale down as needed
