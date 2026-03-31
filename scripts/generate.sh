#!/bin/bash

# App Asset Forge — Asset Generation via Fal.ai Queue API
# Usage: ./generate.sh --prompt "..." [--model MODEL] [options]
# Returns: JSON with generated media URLs
#
# Queue Mode (default): Submits to queue, polls for completion
# Async Mode: Returns request_id immediately
# Sync Mode: Direct request (fast models only)

set -e

FAL_QUEUE_ENDPOINT="https://queue.fal.run"
FAL_SYNC_ENDPOINT="https://fal.run"
FAL_TOKEN_ENDPOINT="https://rest.alpha.fal.ai/storage/auth/token?storage_type=fal-cdn-v3"

# Default values
MODEL="fal-ai/recraft/v4"
PROMPT=""
IMAGE_URL=""
IMAGE_FILE=""
IMAGE_SIZE="square"
NUM_IMAGES=1
MODE="queue"
REQUEST_ID=""
ACTION="generate"
POLL_INTERVAL=2
MAX_POLL_TIME=600
LIFECYCLE=""
SHOW_LOGS=false
STYLE=""
COLORS=""
SEED=""
GUIDANCE_SCALE=""
NUM_STEPS=""
STRENGTH=""

# Asset type presets
declare -A ASSET_PRESETS
# format: "model|size|style"
ASSET_PRESETS=(
    ["icon"]="fal-ai/recraft/v4/svg|square|vector_illustration"
    ["icon-text"]="fal-ai/ideogram/v3|square|"
    ["logo"]="fal-ai/ideogram/v3|square|"
    ["logo-symbol"]="fal-ai/recraft/v4/svg|square|vector_illustration"
    ["splash"]="fal-ai/flux-2-flex|portrait_3_4|"
    ["onboarding"]="fal-ai/nano-banana/v2|portrait_3_4|"
    ["empty-state"]="fal-ai/recraft/v4|square|digital_illustration"
    ["achievement"]="fal-ai/recraft/v4/svg|square|vector_illustration"
    ["notification"]="fal-ai/recraft/v4/svg|square|vector_illustration"
    ["feature-graphic"]="fal-ai/flux-2-flex|landscape_16_9|"
    ["favicon"]="fal-ai/recraft/v4/svg|square|vector_illustration"
    ["tab-icon"]="fal-ai/recraft/v4/svg|square|vector_illustration"
    ["prototype"]="fal-ai/flux/schnell|square|"
    ["badge"]="fal-ai/recraft/v4/svg|square|vector_illustration"
    ["background"]="fal-ai/nano-banana/pro|landscape_16_9|"
)

# Check for --add-fal-key first
for arg in "$@"; do
    if [ "$arg" = "--add-fal-key" ]; then
        shift
        KEY_VALUE=""
        if [[ -n "$1" && ! "$1" =~ ^-- ]]; then
            KEY_VALUE="$1"
        fi
        if [ -z "$KEY_VALUE" ]; then
            echo "Enter your fal.ai API key:" >&2
            read -r KEY_VALUE
        fi
        if [ -n "$KEY_VALUE" ]; then
            grep -v "^FAL_KEY=" .env > .env.tmp 2>/dev/null || true
            mv .env.tmp .env 2>/dev/null || true
            echo "FAL_KEY=$KEY_VALUE" >> .env
            echo "FAL_KEY saved to .env" >&2
        fi
        exit 0
    fi
done

# Load .env if exists
if [ -f ".env" ]; then
    source .env 2>/dev/null || true
fi

# Parse arguments
ASSET_TYPE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --prompt|-p)
            PROMPT="$2"; shift 2 ;;
        --model|-m)
            MODEL="$2"; shift 2 ;;
        --asset-type|-t)
            ASSET_TYPE="$2"; shift 2 ;;
        --image-url)
            IMAGE_URL="$2"; shift 2 ;;
        --file|--image)
            IMAGE_FILE="$2"; shift 2 ;;
        --size)
            case $2 in
                square) IMAGE_SIZE="square" ;;
                portrait) IMAGE_SIZE="portrait_3_4" ;;
                landscape) IMAGE_SIZE="landscape_4_3" ;;
                *) IMAGE_SIZE="$2" ;;
            esac
            shift 2 ;;
        --num-images|-n)
            NUM_IMAGES="$2"; shift 2 ;;
        --style)
            STYLE="$2"; shift 2 ;;
        --colors)
            COLORS="$2"; shift 2 ;;
        --seed)
            SEED="$2"; shift 2 ;;
        --cfg|--guidance-scale)
            GUIDANCE_SCALE="$2"; shift 2 ;;
        --steps)
            NUM_STEPS="$2"; shift 2 ;;
        --strength)
            STRENGTH="$2"; shift 2 ;;
        --async)
            MODE="async"; shift ;;
        --sync)
            MODE="sync"; shift ;;
        --logs)
            SHOW_LOGS=true; shift ;;
        --status)
            ACTION="status"; REQUEST_ID="$2"; shift 2 ;;
        --result)
            ACTION="result"; REQUEST_ID="$2"; shift 2 ;;
        --cancel)
            ACTION="cancel"; REQUEST_ID="$2"; shift 2 ;;
        --poll-interval)
            POLL_INTERVAL="$2"; shift 2 ;;
        --timeout)
            MAX_POLL_TIME="$2"; shift 2 ;;
        --lifecycle)
            LIFECYCLE="$2"; shift 2 ;;
        --schema)
            SCHEMA_MODEL="${2:-$MODEL}"
            ENCODED=$(echo "$SCHEMA_MODEL" | sed 's/\//%2F/g')
            echo "Fetching schema for $SCHEMA_MODEL..." >&2
            curl -s "https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=$ENCODED"
            exit 0 ;;
        --help|-h)
            echo "App Asset Forge — Generate App Assets via Fal.ai" >&2
            echo "" >&2
            echo "Usage: ./generate.sh --prompt \"...\" [options]" >&2
            echo "" >&2
            echo "Asset Type Presets (--asset-type):" >&2
            echo "  icon           App icon (Recraft V4 SVG)" >&2
            echo "  icon-text      App icon with text (Ideogram V3)" >&2
            echo "  logo           Logo with text (Ideogram V3)" >&2
            echo "  logo-symbol    Symbolic logo (Recraft V4 SVG)" >&2
            echo "  splash         Splash screen (FLUX.2 Flex)" >&2
            echo "  onboarding     Onboarding illustration (Nano Banana 2)" >&2
            echo "  empty-state    Empty state illustration (Recraft V4)" >&2
            echo "  achievement    Achievement badge (Recraft V4 SVG)" >&2
            echo "  notification   Notification icon (Recraft V4 SVG)" >&2
            echo "  feature-graphic Play Store feature graphic (FLUX.2 Flex)" >&2
            echo "  favicon        Favicon (Recraft V4 SVG)" >&2
            echo "  tab-icon       Tab bar icon (Recraft V4 SVG)" >&2
            echo "  prototype      Quick prototype (FLUX.1 Schnell)" >&2
            echo "  badge          Generic badge (Recraft V4 SVG)" >&2
            echo "  background     Background image (Nano Banana Pro)" >&2
            echo "" >&2
            echo "Generation:" >&2
            echo "  --prompt, -p      Text prompt (required)" >&2
            echo "  --model, -m       Model ID (overrides preset)" >&2
            echo "  --asset-type, -t  Use preset (see above)" >&2
            echo "  --image-url       Input image URL (I2I/I2V)" >&2
            echo "  --file, --image   Local file (auto-uploads)" >&2
            echo "  --size            square, portrait, landscape" >&2
            echo "  --num-images, -n  Number of images (default: 1)" >&2
            echo "  --style           Recraft style preset" >&2
            echo "  --colors          Hex colors: '#4285F4,#34A853'" >&2
            echo "  --seed            Seed for reproducibility" >&2
            echo "  --cfg             Guidance scale" >&2
            echo "  --steps           Inference steps" >&2
            echo "  --strength        I2I strength 0.0-1.0" >&2
            echo "" >&2
            echo "Mode:  (default)=queue, --async, --sync, --logs" >&2
            echo "Queue: --status ID, --result ID, --cancel ID" >&2
            echo "Other: --schema [MODEL], --add-fal-key, --timeout N" >&2
            exit 0 ;;
        *) shift ;;
    esac
done

# Apply asset type preset if specified
if [ -n "$ASSET_TYPE" ] && [ -n "${ASSET_PRESETS[$ASSET_TYPE]}" ]; then
    IFS='|' read -r PRESET_MODEL PRESET_SIZE PRESET_STYLE <<< "${ASSET_PRESETS[$ASSET_TYPE]}"
    # Only override if user didn't explicitly set
    if [ "$MODEL" = "fal-ai/recraft/v4" ]; then
        MODEL="$PRESET_MODEL"
    fi
    if [ "$IMAGE_SIZE" = "square" ] && [ -n "$PRESET_SIZE" ]; then
        IMAGE_SIZE="$PRESET_SIZE"
    fi
    if [ -z "$STYLE" ] && [ -n "$PRESET_STYLE" ]; then
        STYLE="$PRESET_STYLE"
    fi
    echo "Asset type: $ASSET_TYPE → Model: $MODEL | Size: $IMAGE_SIZE" >&2
fi

# Validate FAL_KEY
if [ -z "$FAL_KEY" ]; then
    echo "Error: FAL_KEY not set" >&2
    echo "" >&2
    echo "Run: ./generate.sh --add-fal-key" >&2
    echo "Or:  export FAL_KEY=your_key_here" >&2
    echo "Get key at: https://fal.ai/dashboard/keys" >&2
    exit 1
fi

# Handle local file upload
if [ -n "$IMAGE_FILE" ]; then
    if [ ! -f "$IMAGE_FILE" ]; then
        echo "Error: File not found: $IMAGE_FILE" >&2
        exit 1
    fi

    FILENAME=$(basename "$IMAGE_FILE")
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
        *) CONTENT_TYPE="application/octet-stream" ;;
    esac

    echo "Uploading $FILENAME..." >&2

    TOKEN_RESPONSE=$(curl -s -X POST "$FAL_TOKEN_ENDPOINT" \
        -H "Authorization: Key $FAL_KEY" \
        -H "Content-Type: application/json" -d '{}')

    CDN_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    CDN_TOKEN_TYPE=$(echo "$TOKEN_RESPONSE" | grep -o '"token_type":"[^"]*"' | cut -d'"' -f4)
    CDN_BASE_URL=$(echo "$TOKEN_RESPONSE" | grep -o '"base_url":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$CDN_TOKEN" ] || [ -z "$CDN_BASE_URL" ]; then
        echo "Error: Failed to get CDN token" >&2
        exit 1
    fi

    UPLOAD_RESPONSE=$(curl -s -X POST "${CDN_BASE_URL}/files/upload" \
        -H "Authorization: $CDN_TOKEN_TYPE $CDN_TOKEN" \
        -H "Content-Type: $CONTENT_TYPE" \
        -H "X-Fal-File-Name: $FILENAME" \
        --data-binary "@$IMAGE_FILE")

    if echo "$UPLOAD_RESPONSE" | grep -q '"error"'; then
        ERROR_MSG=$(echo "$UPLOAD_RESPONSE" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "Upload error: $ERROR_MSG" >&2
        exit 1
    fi

    IMAGE_URL=$(echo "$UPLOAD_RESPONSE" | grep -o '"access_url":"[^"]*"' | cut -d'"' -f4)
    if [ -z "$IMAGE_URL" ]; then
        echo "Error: Failed to get URL from upload response" >&2
        exit 1
    fi
    echo "Uploaded: $IMAGE_URL" >&2
fi

# Build headers
HEADERS=(-H "Authorization: Key $FAL_KEY" -H "Content-Type: application/json")
if [ -n "$LIFECYCLE" ]; then
    HEADERS+=(-H "X-Fal-Object-Lifecycle-Preference: {\"expiration_duration_seconds\": $LIFECYCLE}")
fi

# Handle queue operations (status, result, cancel)
case $ACTION in
    status)
        [ -z "$REQUEST_ID" ] && echo "Error: Request ID required for --status" >&2 && exit 1
        LOGS_PARAM=""; [ "$SHOW_LOGS" = true ] && LOGS_PARAM="?logs=1"
        echo "Checking status for $REQUEST_ID..." >&2
        RESPONSE=$(curl -s -X GET "$FAL_QUEUE_ENDPOINT/$MODEL/requests/$REQUEST_ID/status$LOGS_PARAM" "${HEADERS[@]}")
        STATUS=$(echo "$RESPONSE" | grep -oE '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//')
        echo "Status: $STATUS" >&2
        if [ "$STATUS" = "IN_QUEUE" ]; then
            POSITION=$(echo "$RESPONSE" | grep -o '"queue_position":[0-9]*' | cut -d':' -f2)
            [ -n "$POSITION" ] && echo "Queue position: $POSITION" >&2
        fi
        echo "$RESPONSE"; exit 0 ;;
    result)
        [ -z "$REQUEST_ID" ] && echo "Error: Request ID required for --result" >&2 && exit 1
        echo "Getting result for $REQUEST_ID..." >&2
        RESPONSE=$(curl -s -X GET "$FAL_QUEUE_ENDPOINT/$MODEL/requests/$REQUEST_ID" "${HEADERS[@]}")
        if echo "$RESPONSE" | grep -q '"error"'; then
            ERROR_MSG=$(echo "$RESPONSE" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
            echo "Error: $ERROR_MSG" >&2; exit 1
        fi
        if echo "$RESPONSE" | grep -q '"video"'; then
            URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
            echo "Video URL: $URL" >&2
        elif echo "$RESPONSE" | grep -q '"images"'; then
            URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
            echo "Image URL: $URL" >&2
        fi
        echo "$RESPONSE"; exit 0 ;;
    cancel)
        [ -z "$REQUEST_ID" ] && echo "Error: Request ID required for --cancel" >&2 && exit 1
        echo "Cancelling request $REQUEST_ID..." >&2
        RESPONSE=$(curl -s -X PUT "$FAL_QUEUE_ENDPOINT/$MODEL/requests/$REQUEST_ID/cancel" "${HEADERS[@]}")
        echo "$RESPONSE"; exit 0 ;;
esac

# Generate action requires prompt
if [ -z "$PROMPT" ]; then
    echo "Error: --prompt is required" >&2
    exit 1
fi

# Build the request payload
build_payload() {
    local payload="{"
    payload+="\"prompt\": \"$PROMPT\""

    # Image-to-video / image-to-image
    if [ -n "$IMAGE_URL" ]; then
        payload+=", \"image_url\": \"$IMAGE_URL\""
    fi

    # Strength (for I2I)
    if [ -n "$STRENGTH" ]; then
        payload+=", \"strength\": $STRENGTH"
    fi

    # Image size (skip for video-only models)
    if [[ "$MODEL" != *"video"* ]] && [[ "$MODEL" != *"veo"* ]] && [[ "$MODEL" != *"kling"* ]]; then
        if [[ "$MODEL" == *"recraft"* ]]; then
            # Recraft uses object format
            case $IMAGE_SIZE in
                square) payload+=", \"image_size\": {\"width\": 1024, \"height\": 1024}" ;;
                portrait_3_4) payload+=", \"image_size\": {\"width\": 1024, \"height\": 1365}" ;;
                landscape_4_3) payload+=", \"image_size\": {\"width\": 1365, \"height\": 1024}" ;;
                landscape_16_9) payload+=", \"image_size\": {\"width\": 1536, \"height\": 864}" ;;
                *) payload+=", \"image_size\": {\"width\": 1024, \"height\": 1024}" ;;
            esac
        else
            payload+=", \"image_size\": \"$IMAGE_SIZE\""
        fi
        payload+=", \"num_images\": $NUM_IMAGES"
    fi

    # Recraft-specific: style and colors
    if [[ "$MODEL" == *"recraft"* ]]; then
        if [ -n "$STYLE" ]; then
            payload+=", \"style\": \"$STYLE\""
        fi
        if [ -n "$COLORS" ]; then
            # Convert "#4285F4,#34A853" to [[66,133,244],[52,168,83]]
            local color_array="["
            local first=true
            IFS=',' read -ra COLOR_LIST <<< "$COLORS"
            for hex in "${COLOR_LIST[@]}"; do
                hex=$(echo "$hex" | tr -d ' #')
                local r=$((16#${hex:0:2}))
                local g=$((16#${hex:2:2}))
                local b=$((16#${hex:4:2}))
                [ "$first" = true ] && first=false || color_array+=","
                color_array+="[$r,$g,$b]"
            done
            color_array+="]"
            payload+=", \"colors\": $color_array"
        fi
    fi

    # Optional parameters
    if [ -n "$SEED" ]; then
        payload+=", \"seed\": $SEED"
    fi
    if [ -n "$GUIDANCE_SCALE" ]; then
        payload+=", \"guidance_scale\": $GUIDANCE_SCALE"
    fi
    if [ -n "$NUM_STEPS" ]; then
        payload+=", \"num_inference_steps\": $NUM_STEPS"
    fi

    payload+="}"
    echo "$payload"
}

PAYLOAD=$(build_payload)

echo "Model: $MODEL" >&2
echo "Prompt: ${PROMPT:0:80}..." >&2

# Synchronous mode
if [ "$MODE" = "sync" ]; then
    echo "Generating (sync mode)..." >&2
    RESPONSE=$(curl -s -X POST "$FAL_SYNC_ENDPOINT/$MODEL" "${HEADERS[@]}" -d "$PAYLOAD")
    if echo "$RESPONSE" | grep -q '"error"'; then
        ERROR_MSG=$(echo "$RESPONSE" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "Error: $ERROR_MSG" >&2; exit 1
    fi
    echo "Generation complete!" >&2
    if echo "$RESPONSE" | grep -q '"video"'; then
        URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "Video URL: $URL" >&2
    elif echo "$RESPONSE" | grep -q '"images"'; then
        URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "Image URL: $URL" >&2
    fi
    echo "$RESPONSE"; exit 0
fi

# Queue mode — submit
echo "Submitting to queue..." >&2
SUBMIT_RESPONSE=$(curl -s -X POST "$FAL_QUEUE_ENDPOINT/$MODEL" "${HEADERS[@]}" -d "$PAYLOAD")

if echo "$SUBMIT_RESPONSE" | grep -q '"error"'; then
    ERROR_MSG=$(echo "$SUBMIT_RESPONSE" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "Error: $ERROR_MSG" >&2; exit 1
fi

REQUEST_ID=$(echo "$SUBMIT_RESPONSE" | grep -oE '"request_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//')
STATUS_URL=$(echo "$SUBMIT_RESPONSE" | grep -oE '"status_url"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//')
RESPONSE_URL=$(echo "$SUBMIT_RESPONSE" | grep -oE '"response_url"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//')

if [ -z "$REQUEST_ID" ]; then
    echo "Error: Failed to get request_id" >&2
    echo "$SUBMIT_RESPONSE" >&2; exit 1
fi

echo "Request ID: $REQUEST_ID" >&2

# Async mode — return immediately
if [ "$MODE" = "async" ]; then
    echo "" >&2
    echo "Request submitted. Use these commands to check:" >&2
    echo "  Status: ./generate.sh --status \"$REQUEST_ID\" --model \"$MODEL\"" >&2
    echo "  Result: ./generate.sh --result \"$REQUEST_ID\" --model \"$MODEL\"" >&2
    echo "  Cancel: ./generate.sh --cancel \"$REQUEST_ID\" --model \"$MODEL\"" >&2
    echo "$SUBMIT_RESPONSE"; exit 0
fi

# Queue mode — poll until complete
echo "Waiting for completion..." >&2
ELAPSED=0
LAST_STATUS=""

while [ $ELAPSED -lt $MAX_POLL_TIME ]; do
    sleep $POLL_INTERVAL
    ELAPSED=$((ELAPSED + POLL_INTERVAL))

    LOGS_PARAM=""
    [ "$SHOW_LOGS" = true ] && LOGS_PARAM="?logs=1"

    STATUS_RESPONSE=$(curl -s -X GET "${STATUS_URL}${LOGS_PARAM}" "${HEADERS[@]}")
    STATUS=$(echo "$STATUS_RESPONSE" | grep -oE '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//')

    if [ "$STATUS" != "$LAST_STATUS" ]; then
        case $STATUS in
            IN_QUEUE)
                POSITION=$(echo "$STATUS_RESPONSE" | grep -o '"queue_position":[0-9]*' | cut -d':' -f2)
                echo "Status: IN_QUEUE (position: ${POSITION:-?})" >&2 ;;
            IN_PROGRESS) echo "Status: IN_PROGRESS" >&2 ;;
            COMPLETED) echo "Status: COMPLETED" >&2 ;;
            *) echo "Status: $STATUS" >&2 ;;
        esac
        LAST_STATUS="$STATUS"
    fi

    if [ "$SHOW_LOGS" = true ]; then
        LOGS=$(echo "$STATUS_RESPONSE" | grep -o '"logs":\[[^]]*\]' | head -1)
        if [ -n "$LOGS" ] && [ "$LOGS" != "[]" ]; then
            echo "$LOGS" | tr ',' '\n' | grep -o '"message":"[^"]*"' | cut -d'"' -f4 | while read -r log; do
                echo "  > $log" >&2
            done
        fi
    fi

    [ "$STATUS" = "COMPLETED" ] && break
    if [ "$STATUS" = "FAILED" ]; then
        echo "Error: Generation failed" >&2
        echo "$STATUS_RESPONSE"; exit 1
    fi
done

if [ "$STATUS" != "COMPLETED" ]; then
    echo "Error: Timeout after ${MAX_POLL_TIME}s" >&2
    echo "Request ID: $REQUEST_ID" >&2
    echo "Check: ./generate.sh --status \"$REQUEST_ID\" --model \"$MODEL\"" >&2
    exit 1
fi

# Get final result
echo "Fetching result..." >&2
RESULT=$(curl -s -X GET "$RESPONSE_URL" "${HEADERS[@]}")

if echo "$RESULT" | grep -q '"error"'; then
    ERROR_MSG=$(echo "$RESULT" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "Error: $ERROR_MSG" >&2; exit 1
fi

echo "" >&2
echo "Generation complete!" >&2

if echo "$RESULT" | grep -q '"video"'; then
    URL=$(echo "$RESULT" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "Video URL: $URL" >&2
elif echo "$RESULT" | grep -q '"images"'; then
    URL=$(echo "$RESULT" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "Image URL: $URL" >&2
fi

SEED_VAL=$(echo "$RESULT" | grep -o '"seed":[0-9]*' | cut -d':' -f2)
[ -n "$SEED_VAL" ] && echo "Seed: $SEED_VAL (reuse for consistency)" >&2

echo "$RESULT"
