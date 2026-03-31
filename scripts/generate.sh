#!/bin/bash

# App Asset Forge — Asset Generation via Fal.ai Queue API
# Usage: ./generate.sh --prompt "..." [--model MODEL] [options]
# Returns: JSON with generated media URLs
#
# Queue Mode (default): Submits to queue, polls for completion
# Async Mode: Returns request_id immediately
# Sync Mode: Direct request (fast models only)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
register_cleanup

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
NO_FALLBACK=false

# Model fallback chains — try alternatives on failure
get_model_fallbacks() {
    case "$1" in
        fal-ai/recraft/v4/svg) echo "fal-ai/recraft/v4 fal-ai/recraft-v3/svg" ;;
        fal-ai/recraft/v4)     echo "fal-ai/recraft-v3 fal-ai/flux-2-flex" ;;
        fal-ai/ideogram/v3)    echo "fal-ai/ideogram/v2a fal-ai/recraft/v4" ;;
        fal-ai/flux-2-flex)    echo "fal-ai/flux/dev fal-ai/flux/schnell" ;;
        fal-ai/nano-banana/v2) echo "fal-ai/nano-banana fal-ai/flux-2-flex" ;;
        *) echo "" ;;
    esac
}

# Asset type presets — returns "model|size|style"
get_asset_preset() {
    case "$1" in
        icon)            echo "fal-ai/recraft/v4/svg|square|vector_illustration" ;;
        icon-text)       echo "fal-ai/ideogram/v3|square|" ;;
        logo)            echo "fal-ai/ideogram/v3|square|" ;;
        logo-symbol)     echo "fal-ai/recraft/v4/svg|square|vector_illustration" ;;
        splash)          echo "fal-ai/flux-2-flex|portrait_3_4|" ;;
        onboarding)      echo "fal-ai/nano-banana/v2|portrait_3_4|" ;;
        empty-state)     echo "fal-ai/recraft/v4|square|digital_illustration" ;;
        achievement)     echo "fal-ai/recraft/v4/svg|square|vector_illustration" ;;
        notification)    echo "fal-ai/recraft/v4/svg|square|vector_illustration" ;;
        feature-graphic) echo "fal-ai/flux-2-flex|landscape_16_9|" ;;
        favicon)         echo "fal-ai/recraft/v4/svg|square|vector_illustration" ;;
        tab-icon)        echo "fal-ai/recraft/v4/svg|square|vector_illustration" ;;
        prototype)       echo "fal-ai/flux/schnell|square|" ;;
        badge)           echo "fal-ai/recraft/v4/svg|square|vector_illustration" ;;
        background)      echo "fal-ai/nano-banana/pro|landscape_16_9|" ;;
        *) echo "" ;;
    esac
}

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

# Load .env safely (no arbitrary code execution)
safe_load_env

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
        --health-check)
            if [ -z "$FAL_KEY" ]; then
                echo "Error: FAL_KEY not set" >&2; exit 1
            fi
            if check_api_health "$FAL_KEY"; then
                exit 0
            else
                exit 1
            fi ;;
        --no-fallback)
            NO_FALLBACK=true; shift ;;
        --schema)
            SCHEMA_MODEL="${2:-$MODEL}"
            ENCODED=$(echo "$SCHEMA_MODEL" | sed 's/\//%2F/g')
            echo "Fetching schema for $SCHEMA_MODEL..." >&2
            curl_with_retry "https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=$ENCODED"
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
            echo "" >&2
            echo "Reliability:" >&2
            echo "  --health-check    Test API connectivity" >&2
            echo "  --no-fallback     Disable model fallback on failure" >&2
            echo "" >&2
            echo "Other: --schema [MODEL], --add-fal-key, --timeout N" >&2
            exit 0 ;;
        *) shift ;;
    esac
done

# Apply asset type preset if specified
PRESET_VALUE=$(get_asset_preset "$ASSET_TYPE")
if [ -n "$ASSET_TYPE" ] && [ -n "$PRESET_VALUE" ]; then
    IFS='|' read -r PRESET_MODEL PRESET_SIZE PRESET_STYLE <<< "$PRESET_VALUE"
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

    TOKEN_RESPONSE=$(curl_with_retry -X POST "$FAL_TOKEN_ENDPOINT" \
        -H "Authorization: Key $FAL_KEY" \
        -H "Content-Type: application/json" -d '{}')

    CDN_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    CDN_TOKEN_TYPE=$(echo "$TOKEN_RESPONSE" | grep -o '"token_type":"[^"]*"' | cut -d'"' -f4)
    CDN_BASE_URL=$(echo "$TOKEN_RESPONSE" | grep -o '"base_url":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$CDN_TOKEN" ] || [ -z "$CDN_BASE_URL" ]; then
        echo "Error: Failed to get CDN token" >&2
        exit 1
    fi

    UPLOAD_RESPONSE=$(curl_with_retry -X POST "${CDN_BASE_URL}/files/upload" \
        -H "Authorization: $CDN_TOKEN_TYPE $CDN_TOKEN" \
        -H "Content-Type: $CONTENT_TYPE" \
        -H "X-Fal-File-Name: $FILENAME" \
        --data-binary "@$IMAGE_FILE")

    if check_error_response "$UPLOAD_RESPONSE"; then
        echo "Upload error: $(get_error_message "$UPLOAD_RESPONSE")" >&2
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
        RESPONSE=$(curl_with_retry -X GET "$FAL_QUEUE_ENDPOINT/$MODEL/requests/$REQUEST_ID/status$LOGS_PARAM" "${HEADERS[@]}")
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
        RESPONSE=$(curl_with_retry -X GET "$FAL_QUEUE_ENDPOINT/$MODEL/requests/$REQUEST_ID" "${HEADERS[@]}")
        if check_error_response "$RESPONSE"; then
            echo "Error: $(get_error_message "$RESPONSE")" >&2; exit 1
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
        RESPONSE=$(curl_with_retry -X PUT "$FAL_QUEUE_ENDPOINT/$MODEL/requests/$REQUEST_ID/cancel" "${HEADERS[@]}")
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
    payload+="\"prompt\": \"$(json_escape "$PROMPT")\""

    # Image-to-video / image-to-image
    if [ -n "$IMAGE_URL" ]; then
        payload+=", \"image_url\": \"$(json_escape "$IMAGE_URL")\""
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
            payload+=", \"image_size\": \"$(json_escape "$IMAGE_SIZE")\""
        fi
        payload+=", \"num_images\": $NUM_IMAGES"
    fi

    # Recraft-specific: style and colors
    if [[ "$MODEL" == *"recraft"* ]]; then
        if [ -n "$STYLE" ]; then
            payload+=", \"style\": \"$(json_escape "$STYLE")\""
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

# ──────────────────────────────────────────────
# try_generate — submit, poll, fetch with a single model
# Returns 0 on success (result in TRY_RESULT), 1 on failure
# ──────────────────────────────────────────────
TRY_RESULT=""

try_generate() {
    local try_model="$1"
    local try_payload="$2"
    TRY_RESULT=""

    # Synchronous mode
    if [ "$MODE" = "sync" ]; then
        echo "Generating with $try_model (sync mode)..." >&2
        local response
        response=$(curl_with_retry -X POST "$FAL_SYNC_ENDPOINT/$try_model" "${HEADERS[@]}" -d "$try_payload")
        if check_error_response "$response"; then
            echo "Error with $try_model: $(get_error_message "$response")" >&2
            return 1
        fi
        TRY_RESULT="$response"
        return 0
    fi

    # Queue mode — submit
    echo "Submitting to queue ($try_model)..." >&2
    local submit_response
    submit_response=$(curl_with_retry -X POST "$FAL_QUEUE_ENDPOINT/$try_model" "${HEADERS[@]}" -d "$try_payload")

    if check_error_response "$submit_response"; then
        echo "Error with $try_model: $(get_error_message "$submit_response")" >&2
        return 1
    fi

    local req_id status_url response_url
    req_id=$(echo "$submit_response" | grep -oE '"request_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//')
    status_url=$(echo "$submit_response" | grep -oE '"status_url"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//')
    response_url=$(echo "$submit_response" | grep -oE '"response_url"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//')

    if [ -z "$req_id" ]; then
        echo "Error: Failed to get request_id from $try_model" >&2
        return 1
    fi

    echo "Request ID: $req_id" >&2

    # Async mode — return immediately
    if [ "$MODE" = "async" ]; then
        echo "" >&2
        echo "Request submitted. Use these commands to check:" >&2
        echo "  Status: ./generate.sh --status \"$req_id\" --model \"$try_model\"" >&2
        echo "  Result: ./generate.sh --result \"$req_id\" --model \"$try_model\"" >&2
        echo "  Cancel: ./generate.sh --cancel \"$req_id\" --model \"$try_model\"" >&2
        TRY_RESULT="$submit_response"
        return 0
    fi

    # Queue mode — poll until complete
    echo "Waiting for completion..." >&2
    local elapsed=0 last_status="" status=""

    while [ $elapsed -lt $MAX_POLL_TIME ]; do
        sleep $POLL_INTERVAL
        elapsed=$((elapsed + POLL_INTERVAL))

        local logs_param=""
        [ "$SHOW_LOGS" = true ] && logs_param="?logs=1"

        local status_response
        status_response=$(curl --connect-timeout 10 --max-time 30 -s -X GET \
            "${status_url}${logs_param}" "${HEADERS[@]}" 2>/dev/null) || status_response=""
        status=$(echo "$status_response" | grep -oE '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//')

        if [ "$status" != "$last_status" ]; then
            case $status in
                IN_QUEUE)
                    local position
                    position=$(echo "$status_response" | grep -o '"queue_position":[0-9]*' | cut -d':' -f2)
                    echo "Status: IN_QUEUE (position: ${position:-?})" >&2 ;;
                IN_PROGRESS) echo "Status: IN_PROGRESS" >&2 ;;
                COMPLETED) echo "Status: COMPLETED" >&2 ;;
                *) echo "Status: $status" >&2 ;;
            esac
            last_status="$status"
        fi

        if [ "$SHOW_LOGS" = true ]; then
            local logs
            logs=$(echo "$status_response" | grep -o '"logs":\[[^]]*\]' | head -1)
            if [ -n "$logs" ] && [ "$logs" != "[]" ]; then
                echo "$logs" | tr ',' '\n' | grep -o '"message":"[^"]*"' | cut -d'"' -f4 | while read -r log; do
                    echo "  > $log" >&2
                done
            fi
        fi

        [ "$status" = "COMPLETED" ] && break
        if [ "$status" = "FAILED" ]; then
            echo "Error: Generation failed with $try_model" >&2
            return 1
        fi
    done

    if [ "$status" != "COMPLETED" ]; then
        echo "Error: Timeout after ${MAX_POLL_TIME}s with $try_model" >&2
        return 1
    fi

    # Get final result
    echo "Fetching result..." >&2
    local result
    result=$(curl_with_retry -X GET "$response_url" "${HEADERS[@]}")

    if check_error_response "$result"; then
        echo "Error fetching result from $try_model: $(get_error_message "$result")" >&2
        return 1
    fi

    TRY_RESULT="$result"
    return 0
}

# ──────────────────────────────────────────────
# Output validation
# ──────────────────────────────────────────────
validate_result() {
    local result="$1"
    if echo "$result" | grep -q '"url":"https://'; then
        return 0
    fi
    echo "Warning: Result may not contain valid media URLs" >&2
    return 1
}

# ──────────────────────────────────────────────
# Generate with fallback chain
# ──────────────────────────────────────────────

# Build list of models to try
MODELS_TO_TRY="$MODEL"
if [ "$NO_FALLBACK" = false ]; then
    FALLBACK_LIST=$(get_model_fallbacks "$MODEL")
    if [ -n "$FALLBACK_LIST" ]; then
        MODELS_TO_TRY="$MODEL $FALLBACK_LIST"
    fi
fi

GENERATION_SUCCESS=false

for CURRENT_MODEL in $MODELS_TO_TRY; do
    if [ "$CURRENT_MODEL" != "$MODEL" ]; then
        echo "" >&2
        echo "Falling back to $CURRENT_MODEL..." >&2
        # Rebuild payload for the fallback model (model-specific format may differ)
        SAVED_MODEL="$MODEL"
        MODEL="$CURRENT_MODEL"
        PAYLOAD=$(build_payload)
        MODEL="$SAVED_MODEL"
    fi

    if try_generate "$CURRENT_MODEL" "$PAYLOAD"; then
        GENERATION_SUCCESS=true
        if [ "$CURRENT_MODEL" != "$MODEL" ]; then
            echo "Succeeded with fallback model: $CURRENT_MODEL" >&2
        fi
        break
    fi

    if [ "$NO_FALLBACK" = true ]; then
        break
    fi
done

if [ "$GENERATION_SUCCESS" = false ]; then
    echo "Error: Generation failed with all models" >&2
    exit 1
fi

# Display result
echo "" >&2
echo "Generation complete!" >&2

if echo "$TRY_RESULT" | grep -q '"video"'; then
    URL=$(echo "$TRY_RESULT" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "Video URL: $URL" >&2
elif echo "$TRY_RESULT" | grep -q '"images"'; then
    URL=$(echo "$TRY_RESULT" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "Image URL: $URL" >&2
fi

validate_result "$TRY_RESULT"

SEED_VAL=$(echo "$TRY_RESULT" | grep -o '"seed":[0-9]*' | cut -d':' -f2)
[ -n "$SEED_VAL" ] && echo "Seed: $SEED_VAL (reuse for consistency)" >&2

echo "$TRY_RESULT"
