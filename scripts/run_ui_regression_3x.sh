#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# ---------------------------------------------------------------------------
# Configurable via environment
#   SIM_UDID              – explicit simulator UDID (skips auto-detection)
#   RUNS                  – number of regression rounds (default: 3)
#   RESULT_BUNDLE_PATH    – xcresult output path (optional; CI artifact upload)
# ---------------------------------------------------------------------------
RUNS="${RUNS:-3}"

# --- Simulator resolution (fallback chain) ---------------------------------
if [[ -z "${SIM_UDID:-}" ]]; then
  for model in "iPhone 17 Pro" "iPhone 17" "iPhone 16 Pro" "iPhone 16" "iPhone 15 Pro" "iPhone"; do
    SIM_UDID=$(xcrun simctl list devices available \
      | awk -v m="$model" -F '[()]' '$0 ~ m {print $2; exit}')
    if [[ -n "$SIM_UDID" ]]; then
      echo "Auto-detected simulator: $model ($SIM_UDID)"
      break
    fi
  done
fi

if [[ -z "${SIM_UDID:-}" ]]; then
  echo "No available iPhone simulator found. Set SIM_UDID manually."
  exit 1
fi

echo "Using simulator: ${SIM_UDID}"
echo "Regression rounds: ${RUNS}"

# --- Ensure .xcodeproj is up-to-date (XcodeGen) ----------------------------
if command -v xcodegen &>/dev/null && [[ -f project.yml ]]; then
  echo "Regenerating Xcode project from project.yml..."
  xcodegen generate
fi

# --- Validate destination ---------------------------------------------------
if ! xcodebuild -project YOM.xcodeproj -scheme YOM -destination "id=${SIM_UDID}" -showBuildSettings >/dev/null 2>&1; then
  echo "xcodebuild cannot resolve simulator destination id=${SIM_UDID}."
  echo "Check Xcode Components and install the required iOS Simulator platform/runtime."
  exit 1
fi

# --- Build xcresult args ----------------------------------------------------
RESULT_BUNDLE_ARGS=()
if [[ -n "${RESULT_BUNDLE_PATH:-}" ]]; then
  rm -rf "${RESULT_BUNDLE_PATH}"
  RESULT_BUNDLE_ARGS=(-resultBundlePath "${RESULT_BUNDLE_PATH}")
fi

# --- Run regression rounds --------------------------------------------------
for run in $(seq 1 "$RUNS"); do
  echo "=== UI regression run ${run}/${RUNS} ==="
  xcrun simctl shutdown "${SIM_UDID}" >/dev/null 2>&1 || true
  xcrun simctl erase "${SIM_UDID}" >/dev/null 2>&1 || true
  xcodebuild \
    -project YOM.xcodeproj \
    -scheme YOM \
    -sdk iphonesimulator \
    -destination "id=${SIM_UDID}" \
    -only-testing:YOMUITests/YOMUITests \
    "${RESULT_BUNDLE_ARGS[@]}" \
    test
done

echo "All ${RUNS} UI regression runs passed."
