#!/usr/bin/env python3
"""
App Asset Forge — Single Asset Generator

Generates a single app asset using Fal.ai's API with intelligent model routing,
parameter defaults, and automatic file saving.

Usage:
    python generate.py --asset-type icon --prompt "Minimal flat camera icon" --output ./icon.png
    python generate.py --asset-type logo --prompt "Tech startup logo 'NEXUS'" --model ideogram-v3 --output ./logo.png
    python generate.py --asset-type splash --prompt "Mountain sunset splash" --output ./splash.png

Environment:
    FAL_KEY: Your Fal.ai API key (required)
"""

import argparse
import json
import os
import sys
import urllib.request
from pathlib import Path

try:
    import fal_client
except ImportError:
    print("Error: fal_client not installed. Run: pip install fal_client --break-system-packages")
    sys.exit(1)


# ──────────────────────────────────────────────
# Model Registry
# ──────────────────────────────────────────────

MODELS = {
    # Text-to-Image
    "flux-schnell":     "fal-ai/flux/schnell",
    "flux-dev":         "fal-ai/flux/dev",
    "flux-pro":         "fal-ai/flux-pro/v1.1",
    "flux2-flex":       "fal-ai/flux-2-flex",
    "flux2-dev":        "fal-ai/flux-2-dev",
    "recraft-v4":       "fal-ai/recraft/v4",
    "recraft-v4-svg":   "fal-ai/recraft/v4/svg",
    "recraft-v4-pro":   "fal-ai/recraft/v4",  # same endpoint, different params
    "recraft-v3":       "fal-ai/recraft-v3",
    "recraft-v3-svg":   "fal-ai/recraft-v3/svg",
    "ideogram-v3":      "fal-ai/ideogram/v3",
    "ideogram-v2a":     "fal-ai/ideogram/v2a",
    "nano-banana-2":    "fal-ai/nano-banana/v2",
    "nano-banana-pro":  "fal-ai/nano-banana/pro",
    "nano-banana":      "fal-ai/nano-banana",
    "imagen3":          "fal-ai/imagen3",
    "imagen3-fast":     "fal-ai/imagen3/fast",
    "gpt-image":        "fal-ai/gpt-image-1",
    "z-image-turbo":    "fal-ai/z-image-turbo",
    # Image-to-Image
    "flux-dev-i2i":     "fal-ai/flux/dev/image-to-image",
    "flux-schnell-i2i": "fal-ai/flux/schnell/image-to-image",
    # Enhancement
    "bg-remove":        "fal-ai/bria/rmbg/v2",
    "bg-remove-detail": "fal-ai/birefnet",
    "upscale":          "fal-ai/aura-sr/v2",
    # Video
    "kling-3":          "fal-ai/kling-video/v3/image-to-video",
    "veo-3.1":          "fal-ai/veo3.1/image-to-video",
    "hailuo-2.3":       "fal-ai/hailuo/2.3/image-to-video",
}

# ──────────────────────────────────────────────
# Asset Type Defaults
# ──────────────────────────────────────────────

ASSET_DEFAULTS = {
    "icon": {
        "model": "recraft-v4-svg",
        "width": 1024, "height": 1024,
        "guidance_scale": 10,
        "num_inference_steps": 20,
        "suffix": ".svg",
    },
    "icon-text": {
        "model": "ideogram-v3",
        "width": 1024, "height": 1024,
        "guidance_scale": 15,
        "num_inference_steps": 25,
        "suffix": ".png",
    },
    "logo": {
        "model": "ideogram-v3",
        "width": 1024, "height": 1024,
        "guidance_scale": 15,
        "num_inference_steps": 25,
        "suffix": ".png",
    },
    "logo-symbol": {
        "model": "recraft-v4-svg",
        "width": 1024, "height": 1024,
        "guidance_scale": 10,
        "num_inference_steps": 20,
        "suffix": ".svg",
    },
    "splash": {
        "model": "flux2-flex",
        "width": 1125, "height": 2436,
        "guidance_scale": 10,
        "num_inference_steps": 20,
        "suffix": ".png",
    },
    "onboarding": {
        "model": "nano-banana-2",
        "width": 1080, "height": 1920,
        "guidance_scale": 8,
        "num_inference_steps": 20,
        "suffix": ".png",
    },
    "empty-state": {
        "model": "recraft-v4",
        "width": 800, "height": 800,
        "guidance_scale": 8,
        "num_inference_steps": 20,
        "suffix": ".png",
    },
    "achievement": {
        "model": "recraft-v4-svg",
        "width": 512, "height": 512,
        "guidance_scale": 10,
        "num_inference_steps": 20,
        "suffix": ".svg",
    },
    "notification": {
        "model": "recraft-v4-svg",
        "width": 256, "height": 256,
        "guidance_scale": 10,
        "num_inference_steps": 20,
        "suffix": ".svg",
    },
    "feature-graphic": {
        "model": "flux2-flex",
        "width": 1024, "height": 512,
        "guidance_scale": 10,
        "num_inference_steps": 20,
        "suffix": ".png",
    },
    "favicon": {
        "model": "recraft-v4-svg",
        "width": 512, "height": 512,
        "guidance_scale": 10,
        "num_inference_steps": 20,
        "suffix": ".svg",
    },
    "tab-icon": {
        "model": "recraft-v4-svg",
        "width": 256, "height": 256,
        "guidance_scale": 10,
        "num_inference_steps": 20,
        "suffix": ".svg",
    },
    "prototype": {
        "model": "flux-schnell",
        "width": 1024, "height": 1024,
        "guidance_scale": 4,
        "num_inference_steps": 4,
        "suffix": ".png",
    },
}


def build_arguments(prompt, defaults, args):
    """Build the API arguments dict based on model and asset type."""
    model_key = args.model or defaults["model"]
    endpoint = MODELS.get(model_key, model_key)

    arguments = {"prompt": prompt}

    # Image size
    width = args.width or defaults["width"]
    height = args.height or defaults["height"]

    # Recraft uses a specific image_size format
    if "recraft" in model_key:
        arguments["image_size"] = {"width": width, "height": height}
        if args.style:
            arguments["style"] = args.style
        if args.colors:
            # Parse color string like "#4285F4,#34A853" into RGB arrays
            colors = []
            for hex_color in args.colors.split(","):
                hex_color = hex_color.strip().lstrip("#")
                colors.append([int(hex_color[i:i+2], 16) for i in (0, 2, 4)])
            arguments["colors"] = colors
    elif "ideogram" in model_key:
        arguments["image_size"] = f"{width}x{height}"
    else:
        arguments["image_size"] = {"width": width, "height": height}

    # Guidance and steps (not all models use these)
    if "schnell" not in model_key and "recraft" not in model_key:
        arguments["guidance_scale"] = args.cfg or defaults.get("guidance_scale", 7)
        arguments["num_inference_steps"] = args.steps or defaults.get("num_inference_steps", 20)

    # Seed for reproducibility
    if args.seed is not None:
        arguments["seed"] = args.seed

    # Number of images
    arguments["num_images"] = args.num_images or 1

    return endpoint, arguments


def download_result(result, output_path, is_svg=False):
    """Download the generated image/SVG to disk."""
    if "images" in result and result["images"]:
        url = result["images"][0]["url"]
    elif "image" in result:
        url = result["image"]["url"] if isinstance(result["image"], dict) else result["image"]
    else:
        print("Error: No image found in API response")
        print(f"Response keys: {list(result.keys())}")
        return False

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Downloading to {output_path}...")
    urllib.request.urlretrieve(url, str(output_path))

    # Report result
    size_kb = output_path.stat().st_size / 1024
    print(f"Saved: {output_path} ({size_kb:.1f} KB)")

    if "seed" in result:
        print(f"Seed: {result['seed']} (use this for consistency)")
    if "timings" in result:
        inference_time = result["timings"].get("inference", "unknown")
        print(f"Inference time: {inference_time}s")

    return True


def main():
    parser = argparse.ArgumentParser(
        description="Generate a single app asset using Fal.ai",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Asset types: icon, icon-text, logo, logo-symbol, splash, onboarding,
             empty-state, achievement, notification, feature-graphic,
             favicon, tab-icon, prototype

Examples:
  %(prog)s --asset-type icon --prompt "Flat camera icon, blue" -o icon.svg
  %(prog)s --asset-type logo --prompt "Logo reading 'NEXUS'" -o logo.png
  %(prog)s --asset-type splash --prompt "Mountain sunset" -o splash.png
  %(prog)s --asset-type prototype --prompt "Quick test icon" -o test.png
        """
    )

    parser.add_argument("--asset-type", "-t", required=True,
                        choices=list(ASSET_DEFAULTS.keys()),
                        help="Type of asset to generate")
    parser.add_argument("--prompt", "-p", required=True,
                        help="Generation prompt")
    parser.add_argument("--model", "-m", default=None,
                        help=f"Override model. Options: {', '.join(MODELS.keys())}")
    parser.add_argument("--output", "-o", default=None,
                        help="Output file path")
    parser.add_argument("--width", type=int, default=None,
                        help="Override width in pixels")
    parser.add_argument("--height", type=int, default=None,
                        help="Override height in pixels")
    parser.add_argument("--cfg", type=float, default=None,
                        help="Guidance scale (CFG)")
    parser.add_argument("--steps", type=int, default=None,
                        help="Number of inference steps")
    parser.add_argument("--seed", type=int, default=None,
                        help="Seed for reproducibility")
    parser.add_argument("--num-images", "-n", type=int, default=1,
                        help="Number of variants to generate")
    parser.add_argument("--style", default=None,
                        help="Style preset (Recraft: vector_illustration, digital_illustration, realistic)")
    parser.add_argument("--colors", default=None,
                        help="Brand colors as hex, comma-separated: '#4285F4,#34A853'")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show API call without executing")

    args = parser.parse_args()

    # Check API key
    if not os.environ.get("FAL_KEY"):
        print("Error: FAL_KEY environment variable not set.")
        print("Get your key at: https://fal.ai/dashboard/keys")
        sys.exit(1)

    defaults = ASSET_DEFAULTS[args.asset_type]
    model_key = args.model or defaults["model"]

    # Default output path
    if args.output is None:
        suffix = defaults["suffix"]
        if args.model and "svg" not in (args.model or ""):
            suffix = ".png"
        args.output = f"{args.asset_type}_output{suffix}"

    endpoint, arguments = build_arguments(args.prompt, defaults, args)

    print(f"Asset type: {args.asset_type}")
    print(f"Model: {model_key} → {endpoint}")
    print(f"Size: {args.width or defaults['width']}×{args.height or defaults['height']}")
    print(f"Prompt: {args.prompt[:80]}{'...' if len(args.prompt) > 80 else ''}")
    print()

    if args.dry_run:
        print("DRY RUN — API call that would be made:")
        print(json.dumps({"endpoint": endpoint, "arguments": arguments}, indent=2))
        return

    # Generate
    print("Generating...")
    try:
        result = fal_client.subscribe(endpoint, arguments=arguments)
    except Exception as e:
        print(f"API Error: {e}")
        sys.exit(1)

    # Handle multiple images
    if args.num_images > 1 and "images" in result:
        base = Path(args.output)
        for i, img in enumerate(result["images"]):
            out_path = base.parent / f"{base.stem}_{i+1}{base.suffix}"
            temp_result = {"images": [img], "seed": result.get("seed")}
            download_result(temp_result, out_path)
    else:
        is_svg = args.output.endswith(".svg")
        download_result(result, args.output, is_svg=is_svg)

    print("\nDone!")


if __name__ == "__main__":
    main()
