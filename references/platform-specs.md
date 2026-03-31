# Platform Asset Specifications

Exact pixel dimensions and format requirements for iOS, Android, and Web/PWA assets.

## Table of Contents
1. [iOS App Icons](#ios-app-icons)
2. [Android App Icons](#android-app-icons)
3. [Splash Screens](#splash-screens)
4. [Favicons & PWA Icons](#favicons--pwa-icons)
5. [Tab Bar & Navigation Icons](#tab-bar--navigation-icons)
6. [Notification Icons](#notification-icons)
7. [App Store Assets](#app-store-assets)
8. [Other App Assets](#other-app-assets)
9. [Resizing Reference Tables](#resizing-reference-tables)

---

## iOS App Icons

### Master Icon
- **Dimensions**: 1024 × 1024 px
- **Format**: PNG only
- **Alpha**: NO transparency, NO alpha channel
- **Design**: Fill entire frame, no drop shadows or effects

Xcode automatically generates all smaller sizes from this master icon.

### Auto-Generated Sizes (from 1024×1024 master)

| Context | Size (px) | Scale |
|---|---|---|
| App Store | 1024 × 1024 | - |
| iPhone Home Screen | 180 × 180 | @3x |
| iPhone Home Screen | 120 × 120 | @2x |
| iPad Pro | 167 × 167 | @2x |
| iPad | 152 × 152 | @2x |
| Spotlight Search | 120 × 120 | @3x |
| Spotlight Search | 80 × 80 | @2x |
| Settings | 87 × 87 | @3x |
| Settings | 58 × 58 | @2x |
| Notification | 60 × 60 | @3x |
| Notification | 40 × 40 | @2x |

### Design Guidelines
- Fill entire frame with no padding
- Opaque PNG — no transparency anywhere
- Consistent stroke weight and perspective
- iOS auto-applies corner radius masking (don't bake it in)
- Simple, recognizable at small sizes

---

## Android App Icons

### Play Store Icon
- **Dimensions**: 512 × 512 px
- **Format**: JPEG or PNG
- **Alpha**: No transparency

### Launcher Icons by Density

| Density | Scale | Icon Size (px) |
|---|---|---|
| mdpi | 1.0x | 48 × 48 |
| hdpi | 1.5x | 72 × 72 |
| xhdpi | 2.0x | 96 × 96 |
| xxhdpi | 3.0x | 144 × 144 |
| xxxhdpi | 4.0x | 192 × 192 |

### Adaptive Icons (Android 8.0+)

Adaptive icons use separate foreground and background layers:

- **Canvas**: 108 × 108 dp
- **Safe zone**: 72 × 72 dp (inner two-thirds — always visible regardless of mask shape)
- **Foreground layer**: 432 × 432 px (at xxxhdpi)
- **Background layer**: 432 × 432 px (at xxxhdpi)
- System applies various mask shapes (circle, squircle, rounded square, etc.)

**File structure**:
```
res/mipmap-anydpi-v26/ic_launcher.xml   ← XML wrapper
res/mipmap-xxxhdpi/ic_launcher_foreground.png
res/mipmap-xxxhdpi/ic_launcher_background.png
```

**Generation strategy**: Generate the foreground icon centered in the inner 72dp safe zone of a 108dp canvas. Generate or specify a solid/gradient background separately.

---

## Splash Screens

### iOS Launch Screen
- **Modern approach**: Xcode Storyboard with Auto Layout (not fixed images)
- **Design principle**: Make it look nearly identical to the app's first screen
- **No fixed pixel dimensions** — storyboard adapts to all devices
- If generating a splash illustration, target **1125 × 2436 px** (iPhone 14 Pro equivalent) and center the content

### Android Splash Screen (Android 12+ API)

| Element | Specification |
|---|---|
| Icon canvas | 432 dp |
| Visible icon area | 288 dp (inner ⅔) |
| Icon type | VectorDrawable (static or animated) |
| Animation duration | Max 1,000 ms |
| Branded image | 200 × 80 dp (optional) |
| Window background | Single opaque color |

**Generation strategy**: Create a centered icon/illustration within a 288dp circle. The outer area (to 432dp) may be clipped by the system.

### Safe Areas

| Platform | Top | Bottom | Notes |
|---|---|---|---|
| iOS (notch devices) | 44 pt | 34 pt | Portrait orientation |
| iOS (older devices) | 20 pt | 0 pt | Status bar only |
| Android | ~24 dp | Varies | Status bar height |

---

## Favicons & PWA Icons

### ICO Bundle (Traditional)
Bundle these sizes into one `.ico` file:
- 16 × 16 px
- 32 × 32 px
- 48 × 48 px

### Individual Favicon Files

| Purpose | Size (px) | Format | Filename |
|---|---|---|---|
| Browser tab | 32 × 32 | PNG | favicon-32x32.png |
| Apple Touch Icon | 180 × 180 | PNG | apple-touch-icon.png |
| Android Chrome | 192 × 192 | PNG | android-chrome-192x192.png |
| PWA Manifest | 512 × 512 | PNG | android-chrome-512x512.png |
| SVG Favicon | Scalable | SVG | favicon.svg |

### PWA Manifest Requirements
Minimum icons required:
```json
{
  "icons": [
    { "src": "icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

For best coverage, also include: 72, 96, 128, 144, 152, 384 px sizes.

---

## Tab Bar & Navigation Icons

### iOS Tab Bar Icons

| Scale | Points | Pixels |
|---|---|---|
| @1x | 25 × 25 pt | 25 × 25 px |
| @2x | 25 × 25 pt | 50 × 50 px |
| @3x | 25 × 25 pt | 75 × 75 px |

**Design rules**:
- Two versions: selected and unselected states
- iOS uses the alpha channel to define shape — color is system-applied
- Solid silhouette with transparency
- No drop shadows

### iOS Navigation Bar Icons
- Standard height: 44 px
- UIBarButtonItem max height: 30 px
- Toolbar icons: outlined style, 1-1.5pt stroke width

### Android Navigation/Action Bar Icons
- Standard: 24 × 24 dp

| Density | Size (px) |
|---|---|
| mdpi | 24 × 24 |
| hdpi | 36 × 36 |
| xhdpi | 48 × 48 |
| xxhdpi | 72 × 72 |
| xxxhdpi | 96 × 96 |

---

## Notification Icons

### Android Notification Small Icon
- **Base size**: 24 × 24 dp
- **Color**: Solid WHITE (#FFFFFF) only — system applies tint
- **Background**: Transparent
- **Format**: PNG-32 with alpha channel
- **No**: gradients, shadows, colors (all ignored by system)

| Density | Size (px) |
|---|---|
| mdpi | 24 × 24 |
| hdpi | 36 × 36 |
| xhdpi | 48 × 48 |
| xxhdpi | 72 × 72 |
| xxxhdpi | 96 × 96 |

**File naming**: `ic_stat_[notification_name].png`
**Location**: `res/mipmap-[density]/`

**Generation strategy**: Generate a simple white silhouette icon on transparent background. Must be recognizable at 24×24 dp.

---

## App Store Assets

### iOS App Store Screenshots

**Primary size** (upload one, Apple auto-scales the rest):

| Device | Portrait (px) | Landscape (px) |
|---|---|---|
| 6.9" iPhone (primary) | 1290 × 2796 | 2796 × 1290 |
| 13" iPad (primary) | 2064 × 2752 | 2752 × 2064 |

Auto-scales to 6.7", 6.1", 5.5" iPhones and smaller iPads.

### Android Play Store

**Screenshots**:

| Device | Portrait (px) | Landscape (px) |
|---|---|---|
| Phone | 1080 × 1920 | 1920 × 1080 |
| 7" Tablet | 1200 × 1920 | 1920 × 1200 |
| 10" Tablet | 1600 × 2560 | 2560 × 1600 |

Min: 320px per side. Max: 3840px per side.

**Feature Graphic**:
- **Dimensions**: 1024 × 500 px
- **Format**: JPEG or 24-bit PNG, no alpha
- Displayed at top of Play Store listing

**Promotional Graphic**:
- **Dimensions**: 180 × 120 px

---

## Other App Assets

### Onboarding Screens

No fixed dimensions — use responsive layouts. For generation, target:
- **iPhone**: 1125 × 2436 px (or 1290 × 2796 for latest)
- **Android phone**: 1080 × 1920 px
- **Tablet**: 1600 × 2560 px
- Always leave bottom 30% for text/CTA buttons

### Empty State Illustrations
- Typical size: 200-400 dp/pt square
- Generate at 800 × 800 px and scale down
- PNG with transparency or SVG
- Keep simple — must be recognizable at small sizes

### Achievement Badges
- Base size: 192 × 192 px (xxxhdpi)
- Format: PNG-32, non-interlaced
- Displayed in a circle with masked corners on Android
- Design at high res, scale down
- Avoid text (localization issues)

### In-App Button Icons
- **iOS minimum touch target**: 44 × 44 pt
- **Android minimum touch target**: 48 × 48 dp
- Standard UI icons: 24 × 24 dp (Android)
- Small icons: 16 × 16 dp
- Large icons: 48 × 48 dp

---

## Resizing Reference Tables

### iOS Scale Factors

| Scale | Multiplier | Example (25pt icon) |
|---|---|---|
| @1x | 1× | 25 × 25 px |
| @2x | 2× | 50 × 50 px |
| @3x | 3× | 75 × 75 px |

### Android Density Scale Factors

| Density | Multiplier | Example (24dp icon) | Example (48dp icon) |
|---|---|---|---|
| mdpi | 1.0× | 24 × 24 px | 48 × 48 px |
| hdpi | 1.5× | 36 × 36 px | 72 × 72 px |
| xhdpi | 2.0× | 48 × 48 px | 96 × 96 px |
| xxhdpi | 3.0× | 72 × 72 px | 144 × 144 px |
| xxxhdpi | 4.0× | 96 × 96 px | 192 × 192 px |

### Quick Size Calculator

To convert from dp to px: `px = dp × density_multiplier`

Example: 48dp icon at xxhdpi = 48 × 3.0 = 144px
