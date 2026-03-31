#!/bin/bash

# App Asset Forge — Upload local files to Fal.ai CDN
# Usage: ./upload.sh --file "/path/to/image.png"
# Returns: CDN URL that can be used with --image-url in generate.sh
#
# Two-step process:
# 1. Get upload token from Fal.ai
# 2. Upload file to CDN
# Max file size: 100MB

set -e

FAL_TOKEN_ENDPOINT="https://rest.alpha.fal.ai/storage/auth/token?storage_type=fal-cdn-v3"
FILE_PATH=""

# Load .env if exists
if [ -f ".env" ]; then
    source .env 2>/dev/null || true
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --file|-f)
            FILE_PATH="$2"; shift 2 ;;
        --add-fal-key)
            shift
            KEY_VALUE=""
            if [[ -n "$1" && ! "$1" =~ ^-- ]]; then KEY_VALUE="$1"; shift; fi
            if [ -z "$KEY_VALUE" ]; then echo "Enter your fal.ai API key:" >&2; read -r KEY_VALUE; fi
            grep -v "^FAL_KEY=" .env > .env.tmp 2>/dev/null || true
            mv .env.tmp .env 2>/dev/null || true
            echo "FAL_KEY=$KEY_VALUE" >> .env
            echo "FAL_KEY saved to .env" >&2
            exit 0 ;;
        --help|-h)
            echo "Upload files to Fal.ai CDN" >&2
            echo "" >&2
            echo "Usage: ./upload.sh --file /path/to/file.png" >&2
            echo "" >&2
            echo "Supported: jpg, png, gif, webp, svg, mp4, mov, webm" >&2
            echo "Max size: 100MB" >&2
            echo "" >&2
            echo "Returns the CDN URL on stdout." >&2
            echo "Use it with: generate.sh --image-url \"\$(./upload.sh --file img.png)\"" >&2
            exit 0 ;;
        *) shift ;;
    esac
done

# Validate
if [ -z "$FAL_KEY" ]; then
    echo "Error: FAL_KEY not set. Run: export FAL_KEY=your_key" >&2
    exit 1
fi

if [ -z "$FILE_PATH" ]; then
    echo "Error: --file is required" >&2
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH" >&2
    exit 1
fi

FILENAME=$(basename "$FILE_PATH")
EXTENSION="${FILENAME##*.}"
EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')

case "$EXTENSION_LOWER" in
    jpg|jpeg) CONTENT_TYPE="image/jpeg" ;;
    png) CONTENT_TYPE="image/png" ;;
    gif) CONTENT_TYPE="image/gif" ;;
    webp) CONTENT_TYPE="image/webp" ;;
    svg) CONTENT_TYPE="image/svg+xml" ;;
    mp4) CONTENT_TYPE="video/mp4" ;;
    mov) CONTENT_TYPE="video/quicktime" ;;
    webm) CONTENT_TYPE="video/webm" ;;
    *) CONTENT_TYPE="application/octet-stream" ;;
esac

FILE_SIZE=$(wc -c < "$FILE_PATH" | tr -d ' ')
echo "Uploading $FILENAME ($((FILE_SIZE / 1024))KB, $CONTENT_TYPE)..." >&2

# Step 1: Get CDN token
TOKEN_RESPONSE=$(curl -s -X POST "$FAL_TOKEN_ENDPOINT" \
    -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" -d '{}')

CDN_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
CDN_TOKEN_TYPE=$(echo "$TOKEN_RESPONSE" | grep -o '"token_type":"[^"]*"' | cut -d'"' -f4)
CDN_BASE_URL=$(echo "$TOKEN_RESPONSE" | grep -o '"base_url":"[^"]*"' | cut -d'"' -f4)

if [ -z "$CDN_TOKEN" ] || [ -z "$CDN_BASE_URL" ]; then
    echo "Error: Failed to get CDN token" >&2
    echo "$TOKEN_RESPONSE" >&2
    exit 1
fi

# Step 2: Upload file
UPLOAD_RESPONSE=$(curl -s -X POST "${CDN_BASE_URL}/files/upload" \
    -H "Authorization: $CDN_TOKEN_TYPE $CDN_TOKEN" \
    -H "Content-Type: $CONTENT_TYPE" \
    -H "X-Fal-File-Name: $FILENAME" \
    --data-binary "@$FILE_PATH")

if echo "$UPLOAD_RESPONSE" | grep -q '"error"'; then
    ERROR_MSG=$(echo "$UPLOAD_RESPONSE" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "Upload error: $ERROR_MSG" >&2
    exit 1
fi

ACCESS_URL=$(echo "$UPLOAD_RESPONSE" | grep -o '"access_url":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ACCESS_URL" ]; then
    echo "Error: Failed to get access URL" >&2
    echo "$UPLOAD_RESPONSE" >&2
    exit 1
fi

echo "Uploaded: $ACCESS_URL" >&2

# Output just the URL (for piping)
echo "$ACCESS_URL"
