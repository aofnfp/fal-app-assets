#!/bin/bash

# App Asset Forge — Search Fal.ai Models
# Usage: ./search-models.sh --category "text-to-image"
#        ./search-models.sh --query "icon logo"
#
# Discovers the best models for your asset generation needs.

set -e

CATEGORY=""
QUERY=""

# Load .env if exists
if [ -f ".env" ]; then
    source .env 2>/dev/null || true
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --category|-c)
            CATEGORY="$2"; shift 2 ;;
        --query|-q)
            QUERY="$2"; shift 2 ;;
        --help|-h)
            echo "Search Fal.ai Models" >&2
            echo "" >&2
            echo "Usage:" >&2
            echo "  ./search-models.sh --category \"text-to-image\"" >&2
            echo "  ./search-models.sh --query \"upscale\"" >&2
            echo "" >&2
            echo "Categories:" >&2
            echo "  text-to-image    Image generation from text" >&2
            echo "  image-to-image   Image editing/transformation" >&2
            echo "  text-to-video    Video generation from text" >&2
            echo "  image-to-video   Animate an image" >&2
            echo "  text-to-speech   Voice generation" >&2
            echo "  speech-to-text   Transcription" >&2
            echo "" >&2
            echo "Examples:" >&2
            echo "  ./search-models.sh --category \"text-to-image\"" >&2
            echo "  ./search-models.sh --query \"flux\"" >&2
            echo "  ./search-models.sh --query \"background removal\"" >&2
            echo "  ./search-models.sh --query \"recraft svg\"" >&2
            exit 0 ;;
        *) shift ;;
    esac
done

if [ -z "$CATEGORY" ] && [ -z "$QUERY" ]; then
    echo "Error: Provide --category or --query" >&2
    echo "Run: ./search-models.sh --help" >&2
    exit 1
fi

BASE_URL="https://api.fal.ai/v1/models"

if [ -n "$CATEGORY" ]; then
    echo "Searching models in category: $CATEGORY..." >&2
    ENCODED_CAT=$(echo "$CATEGORY" | sed 's/ /%20/g')
    RESPONSE=$(curl -s -X GET "${BASE_URL}?category=${ENCODED_CAT}" \
        -H "Authorization: Key ${FAL_KEY:-}" \
        -H "Content-Type: application/json")
elif [ -n "$QUERY" ]; then
    echo "Searching models for: $QUERY..." >&2
    ENCODED_QUERY=$(echo "$QUERY" | sed 's/ /%20/g')
    RESPONSE=$(curl -s -X GET "${BASE_URL}?query=${ENCODED_QUERY}" \
        -H "Authorization: Key ${FAL_KEY:-}" \
        -H "Content-Type: application/json")
fi

echo "$RESPONSE"
