#!/usr/bin/env python3
"""
App Asset Forge — Platform Bundle Generator

Generates ALL required asset sizes for iOS, Android, and Web/PWA from a single
high-res source image (or generates one first via Fal.ai).

Usage:
    # Generate from prompt and create all platform bundles
    python generate_bundle.py --asset-type app-icon \
        --prompt "Minimal flat rocket icon, blue gradient" \
        --platforms ios android web \
        --output-dir ./assets/

    # Resize an existing image into all platform sizes
    python generate_bundle.py --asset-type app-icon \
        --source ./my-icon-1024.png \
        --platforms ios android \
        --output-dir ./assets/

Environment:
    FAL_KEY: Your Fal.ai API key (required if generating from prompt)
"""

import argparse
import json
import os
import struct
import sys
import urllib.request
from io import BytesIO
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow not installed. Run: pip install Pillow --break-system-packages")
    sys.exit(1)


# ──────────────────────────────────────────────
# Platform Size Definitions
# ──────────────────────────────────────────────

# iOS: Generate 1024x1024 master. Xcode handles the rest,
# but we provide common sizes for manual workflows.
IOS_APP_ICON_SIZES = {
    "AppStore_1024": (1024, 1024),
    "iPhone_180@3x": (180, 180),
    "iPhone_120@2x": (120, 120),
    "iPad_Pro_167":  (167, 167),
    "iPad_152":      (152, 152),
    "Spotlight_120@3x": (120, 120),
    "Spotlight_80@2x":  (80, 80),
    "Settings_87@3x":   (87, 87),
    "Settings_58@2x":   (58, 58),
    "Notification_60@3x": (60, 60),
    "Notification_40@2x": (40, 40),
}

# Android: Standard launcher + adaptive icon layers
ANDROID_APP_ICON_SIZES = {
    "play_store":    (512, 512),
    "mipmap-xxxhdpi": (192, 192),
    "mipmap-xxhdpi":  (144, 144),
    "mipmap-xhdpi":   (96, 96),
    "mipmap-hdpi":    (72, 72),
    "mipmap-mdpi":    (48, 48),
}

ANDROID_ADAPTIVE_SIZES = {
    "mipmap-xxxhdpi": (432, 432),
    "mipmap-xxhdpi":  (324, 324),
    "mipmap-xhdpi":   (216, 216),
    "mipmap-hdpi":    (162, 162),
    "mipmap-mdpi":    (108, 108),
}

# Web: Favicons and PWA icons
WEB_FAVICON_SIZES = {
    "favicon-16":  (16, 16),
    "favicon-32":  (32, 32),
    "favicon-48":  (48, 48),
    "apple-touch-icon": (180, 180),
    "icon-192": (192, 192),
    "icon-512": (512, 512),
}

# Android notification icons
ANDROID_NOTIFICATION_SIZES = {
    "mipmap-xxxhdpi": (96, 96),
    "mipmap-xxhdpi":  (72, 72),
    "mipmap-xhdpi":   (48, 48),
    "mipmap-hdpi":    (36, 36),
    "mipmap-mdpi":    (24, 24),
}

# Tab bar icons
IOS_TAB_SIZES = {
    "tab_75@3x": (75, 75),
    "tab_50@2x": (50, 50),
    "tab_25@1x": (25, 25),
}

ANDROID_NAV_SIZES = {
    "drawable-xxxhdpi": (96, 96),
    "drawable-xxhdpi":  (72, 72),
    "drawable-xhdpi":   (48, 48),
    "drawable-hdpi":    (36, 36),
    "drawable-mdpi":    (24, 24),
}

# Asset type configurations
BUNDLE_CONFIGS = {
    "app-icon": {
        "source_size": (1024, 1024),
        "model": "recraft-v4",
        "platforms": {
            "ios": ("ios", IOS_APP_ICON_SIZES, "ic_launcher"),
            "android": ("android", ANDROID_APP_ICON_SIZES, "ic_launcher"),
            "web": ("web", WEB_FAVICON_SIZES, "favicon"),
        },
        "generate_adaptive": True,
    },
    "notification-icon": {
        "source_size": (256, 256),
        "model": "recraft-v4-svg",
        "platforms": {
            "android": ("android/notification", ANDROID_NOTIFICATION_SIZES, "ic_notification"),
        },
        "generate_adaptive": False,
    },
    "tab-icon": {
        "source_size": (256, 256),
        "model": "recraft-v4-svg",
        "platforms": {
            "ios": ("ios/tab", IOS_TAB_SIZES, "tab_icon"),
            "android": ("android/nav", ANDROID_NAV_SIZES, "ic_nav"),
        },
        "generate_adaptive": False,
    },
    "favicon": {
        "source_size": (512, 512),
        "model": "recraft-v4",
        "platforms": {
            "web": ("web", WEB_FAVICON_SIZES, "favicon"),
        },
        "generate_adaptive": False,
    },
}


def generate_source_image(prompt, model, size, seed=None):
    """Generate the master image using Fal.ai."""
    try:
        import fal_client
    except ImportError:
        print("Error: fal_client not installed. Run: pip install fal_client --break-system-packages")
        sys.exit(1)

    if not os.environ.get("FAL_KEY"):
        print("Error: FAL_KEY environment variable not set.")
        sys.exit(1)

    # Map short model names to endpoints
    MODEL_MAP = {
        "recraft-v4":     "fal-ai/recraft/v4",
        "recraft-v4-svg": "fal-ai/recraft/v4/svg",
        "recraft-v3":     "fal-ai/recraft-v3",
        "ideogram-v3":    "fal-ai/ideogram/v3",
        "flux2-flex":     "fal-ai/flux-2-flex",
        "flux-schnell":   "fal-ai/flux/schnell",
        "nano-banana-2":  "fal-ai/nano-banana/v2",
    }

    endpoint = MODEL_MAP.get(model, model)
    arguments = {
        "prompt": prompt,
        "image_size": {"width": size[0], "height": size[1]},
        "num_images": 1,
    }
    if seed is not None:
        arguments["seed"] = seed

    print(f"Generating source image with {model}...")
    result = fal_client.subscribe(endpoint, arguments=arguments)

    if "images" in result and result["images"]:
        url = result["images"][0]["url"]
    elif "image" in result:
        url = result["image"]["url"] if isinstance(result["image"], dict) else result["image"]
    else:
        print(f"Error: Unexpected API response: {list(result.keys())}")
        sys.exit(1)

    # Download to memory
    with urllib.request.urlopen(url) as response:
        img_data = response.read()

    img = Image.open(BytesIO(img_data))

    if "seed" in result:
        print(f"Seed: {result['seed']}")

    return img


def resize_and_save(source_img, size, output_path, resample=Image.LANCZOS):
    """Resize an image and save it."""
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    resized = source_img.resize(size, resample)

    # Ensure no alpha for formats that don't support it
    if output_path.suffix.lower() in (".jpg", ".jpeg"):
        if resized.mode == "RGBA":
            background = Image.new("RGB", resized.size, (255, 255, 255))
            background.paste(resized, mask=resized.split()[3])
            resized = background

    resized.save(str(output_path), quality=95 if output_path.suffix in (".jpg", ".jpeg") else None)
    return output_path


def create_ico(source_img, output_path, sizes=None):
    """Create a multi-size ICO file."""
    if sizes is None:
        sizes = [(16, 16), (32, 32), (48, 48)]

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Pillow can save ICO directly
    imgs = []
    for size in sizes:
        resized = source_img.resize(size, Image.LANCZOS)
        if resized.mode != "RGBA":
            resized = resized.convert("RGBA")
        imgs.append(resized)

    # Save using the first image with additional sizes
    imgs[0].save(str(output_path), format="ICO", sizes=[s for s in sizes])
    return output_path


def generate_adaptive_icon(source_img, output_dir, densities):
    """Generate Android adaptive icon layers (foreground on transparent canvas)."""
    output_dir = Path(output_dir)

    for density_name, canvas_size in densities.items():
        density_dir = output_dir / density_name
        density_dir.mkdir(parents=True, exist_ok=True)

        # Foreground: icon centered in inner 2/3 of canvas
        canvas = Image.new("RGBA", (canvas_size[0], canvas_size[1]), (0, 0, 0, 0))
        safe_zone = int(canvas_size[0] * 2 / 3)
        icon_resized = source_img.resize((safe_zone, safe_zone), Image.LANCZOS)

        # Center the icon
        offset = (canvas_size[0] - safe_zone) // 2
        canvas.paste(icon_resized, (offset, offset), icon_resized if icon_resized.mode == "RGBA" else None)
        canvas.save(str(density_dir / "ic_launcher_foreground.png"))

    print(f"  Adaptive icon foregrounds → {output_dir}/")


def generate_bundle(source_img, config, platforms, output_dir):
    """Generate all platform-specific sizes from a source image."""
    output_dir = Path(output_dir)
    generated_files = []

    for platform in platforms:
        if platform not in config["platforms"]:
            print(f"Warning: Platform '{platform}' not configured for this asset type. Skipping.")
            continue

        subdir, sizes, prefix = config["platforms"][platform]
        platform_dir = output_dir / subdir

        print(f"\n--- {platform.upper()} ---")

        for name, size in sizes.items():
            if platform == "web" and name.startswith("favicon-"):
                # These go into the ICO bundle
                continue

            filename = f"{name}.png"
            out_path = resize_and_save(source_img, size, platform_dir / filename)
            generated_files.append(str(out_path))
            print(f"  {size[0]}×{size[1]} → {out_path}")

        # Generate ICO bundle for web
        if platform == "web":
            ico_path = create_ico(source_img, platform_dir / "favicon.ico")
            generated_files.append(str(ico_path))
            print(f"  ICO bundle (16,32,48) → {ico_path}")

    # Generate adaptive icon layers for Android
    if config.get("generate_adaptive") and "android" in platforms:
        print(f"\n--- ANDROID ADAPTIVE ICONS ---")
        adaptive_dir = output_dir / "android" / "adaptive"
        generate_adaptive_icon(source_img, adaptive_dir, ANDROID_ADAPTIVE_SIZES)
        generated_files.append(str(adaptive_dir))

    return generated_files


def main():
    parser = argparse.ArgumentParser(
        description="Generate platform-ready asset bundles for iOS, Android, and Web",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Asset types: app-icon, notification-icon, tab-icon, favicon

Examples:
  # Generate icon from prompt for all platforms
  %(prog)s --asset-type app-icon \\
      --prompt "Minimal flat rocket icon, blue gradient" \\
      --platforms ios android web \\
      --output-dir ./assets/

  # Resize existing image for Android
  %(prog)s --asset-type app-icon \\
      --source ./icon-1024.png \\
      --platforms android \\
      --output-dir ./assets/
        """
    )

    parser.add_argument("--asset-type", "-t", required=True,
                        choices=list(BUNDLE_CONFIGS.keys()),
                        help="Type of asset bundle to generate")
    parser.add_argument("--prompt", "-p", default=None,
                        help="Generation prompt (if not using --source)")
    parser.add_argument("--source", "-s", default=None,
                        help="Path to existing source image to resize")
    parser.add_argument("--model", "-m", default=None,
                        help="Override generation model")
    parser.add_argument("--platforms", nargs="+", default=["ios", "android", "web"],
                        help="Target platforms (default: ios android web)")
    parser.add_argument("--output-dir", "-o", default="./asset-bundle",
                        help="Output directory (default: ./asset-bundle)")
    parser.add_argument("--seed", type=int, default=None,
                        help="Seed for reproducibility")

    args = parser.parse_args()
    config = BUNDLE_CONFIGS[args.asset_type]

    # Get or generate source image
    if args.source:
        print(f"Loading source image: {args.source}")
        source_img = Image.open(args.source)
        if source_img.mode not in ("RGB", "RGBA"):
            source_img = source_img.convert("RGBA")
    elif args.prompt:
        model = args.model or config["model"]
        source_img = generate_source_image(
            args.prompt, model, config["source_size"], seed=args.seed
        )
        # Save the master image
        master_path = Path(args.output_dir) / "master_source.png"
        master_path.parent.mkdir(parents=True, exist_ok=True)
        source_img.save(str(master_path))
        print(f"Master image saved: {master_path}")
    else:
        print("Error: Provide either --prompt or --source")
        sys.exit(1)

    print(f"\nSource image: {source_img.size[0]}×{source_img.size[1]} ({source_img.mode})")
    print(f"Generating bundles for: {', '.join(args.platforms)}")

    # Generate all sizes
    files = generate_bundle(source_img, config, args.platforms, args.output_dir)

    # Summary
    print(f"\n{'='*50}")
    print(f"Generated {len(files)} files in {args.output_dir}/")
    print(f"Asset type: {args.asset_type}")
    print(f"Platforms: {', '.join(args.platforms)}")

    # Generate manifest for reference
    manifest = {
        "asset_type": args.asset_type,
        "source_size": list(config["source_size"]),
        "platforms": args.platforms,
        "files": files,
        "prompt": args.prompt,
        "seed": args.seed,
    }
    manifest_path = Path(args.output_dir) / "manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"\nManifest: {manifest_path}")
    print("\nDone!")


if __name__ == "__main__":
    main()
