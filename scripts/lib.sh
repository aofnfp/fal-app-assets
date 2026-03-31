#!/bin/bash
# App Asset Forge — Shared utility library
# Source this file at the top of other scripts: source "$(dirname "$0")/lib.sh"

# ──────────────────────────────────────────────
# Safe .env loading (no arbitrary code execution)
# ──────────────────────────────────────────────

safe_load_env() {
    local env_file="${1:-.env}"
    [ -f "$env_file" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        # Strip leading whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        # Skip comments and blank lines
        [[ "$line" =~ ^# ]] && continue
        [[ -z "$line" ]] && continue
        # Only export lines matching KEY=VALUE (no command substitution)
        if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*= ]]; then
            local key="${line%%=*}"
            local val="${line#*=}"
            # Strip surrounding quotes (common .env format)
            val="${val#\"}" ; val="${val%\"}"
            val="${val#\'}" ; val="${val%\'}"
            export "$key=$val"
        fi
    done < "$env_file"
}

# ──────────────────────────────────────────────
# JSON string escaping
# ──────────────────────────────────────────────

json_escape() {
    local str="$1"
    # Escape backslashes first, then quotes, then control characters
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    str="${str//$'\b'/\\b}"
    str="${str//$'\f'/\\f}"
    printf '%s' "$str"
}

# ──────────────────────────────────────────────
# Curl with retry and timeouts
# ──────────────────────────────────────────────

# curl_with_retry [curl_args...]
# Wraps curl with connect-timeout, max-time, and retry on 429/5xx/network errors.
# Set CURL_MAX_RETRIES (default 3), CURL_CONNECT_TIMEOUT (default 10),
# CURL_MAX_TIME (default 120) to override.
curl_with_retry() {
    local max_retries="${CURL_MAX_RETRIES:-3}"
    local connect_timeout="${CURL_CONNECT_TIMEOUT:-10}"
    local max_time="${CURL_MAX_TIME:-120}"
    local attempt=0
    local wait_time=1
    local response=""
    local http_code=""
    local tmpfile

    tmpfile=$(mktemp "${TMPDIR:-/tmp}/curl_retry.XXXXXX")
    _register_tmpfile "$tmpfile"

    while [ $attempt -lt $max_retries ]; do
        attempt=$((attempt + 1))

        http_code=$(curl --connect-timeout "$connect_timeout" \
            --max-time "$max_time" \
            -s -o "$tmpfile" -w "%{http_code}" \
            "$@" 2>/dev/null) || http_code="000"

        # Success: 2xx
        if [[ "$http_code" =~ ^2 ]]; then
            cat "$tmpfile"
            rm -f "$tmpfile" 2>/dev/null
            return 0
        fi

        # Non-retryable client errors: 4xx except 429
        if [[ "$http_code" =~ ^4 ]] && [ "$http_code" != "429" ]; then
            cat "$tmpfile"
            rm -f "$tmpfile" 2>/dev/null
            return 0
        fi

        # Retryable: 429, 5xx, or network error (000)
        if [ $attempt -lt $max_retries ]; then
            echo "Request failed (HTTP $http_code), retrying in ${wait_time}s (attempt $attempt/$max_retries)..." >&2
            sleep "$wait_time"
            wait_time=$((wait_time * 2))
        else
            echo "Request failed after $max_retries attempts (HTTP $http_code)" >&2
            cat "$tmpfile"
            rm -f "$tmpfile" 2>/dev/null
            return 1
        fi
    done
}

# ──────────────────────────────────────────────
# API health check
# ──────────────────────────────────────────────

check_api_health() {
    local fal_key="$1"
    echo "Checking Fal.ai API connectivity..." >&2
    local response
    response=$(curl --connect-timeout 10 --max-time 15 -s -o /dev/null \
        -w "%{http_code}" \
        -H "Authorization: Key $fal_key" \
        "https://queue.fal.run" 2>/dev/null) || response="000"

    case "$response" in
        000)
            echo "Error: Cannot reach Fal.ai API (network error)" >&2
            return 1 ;;
        401|403)
            echo "Error: Invalid FAL_KEY (HTTP $response)" >&2
            return 1 ;;
        404|405)
            # Expected — the base URL returns 404/405 but proves connectivity
            echo "Fal.ai API reachable (auth OK)" >&2
            return 0 ;;
        2*|3*)
            echo "Fal.ai API reachable (auth OK)" >&2
            return 0 ;;
        429)
            echo "Warning: Rate limited — API reachable but throttled" >&2
            return 0 ;;
        5*)
            echo "Warning: Fal.ai API returned server error (HTTP $response)" >&2
            return 1 ;;
        *)
            echo "Warning: Unexpected response (HTTP $response)" >&2
            return 0 ;;
    esac
}

# ──────────────────────────────────────────────
# Robust JSON error detection
# ──────────────────────────────────────────────

# check_error_response <json_string>
# Returns 0 if an error was detected, 1 otherwise.
# Checks for "error" as a JSON key (not as part of prompt text).
check_error_response() {
    local json="$1"
    # Match "error" as a top-level JSON key (not as part of prompt/content text)
    if echo "$json" | grep -qE '^\s*\{?\s*"error"\s*:' || \
       echo "$json" | grep -qE ',\s*"error"\s*:'; then
        return 0
    fi
    # Match "detail" only when it looks like an error (short response, no images/video)
    if echo "$json" | grep -qE '"detail"\s*:' && \
       ! echo "$json" | grep -q '"images"\|"video"\|"url"'; then
        return 0
    fi
    return 1
}

# Extract error message from JSON response
get_error_message() {
    local json="$1"
    local msg
    msg=$(echo "$json" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -z "$msg" ]; then
        msg=$(echo "$json" | grep -o '"detail":"[^"]*"' | head -1 | cut -d'"' -f4)
    fi
    if [ -z "$msg" ]; then
        msg="Unknown error"
    fi
    echo "$msg"
}

# ──────────────────────────────────────────────
# Temp file cleanup
# ──────────────────────────────────────────────

_LIB_TMPFILES=()

_register_tmpfile() {
    _LIB_TMPFILES+=("$1")
}

cleanup_on_exit() {
    for f in "${_LIB_TMPFILES[@]}"; do
        rm -f "$f" 2>/dev/null
    done
}

register_cleanup() {
    trap cleanup_on_exit EXIT INT TERM
}
