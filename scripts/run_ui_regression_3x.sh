#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SIM_UDID="${SIM_UDID:-$(xcrun simctl list devices available | awk -F '[()]' '/iPhone 17/ {print $2; exit}')}"
if [[ -z "${SIM_UDID}" ]]; then
  echo "No available iPhone 17 simulator found. Set SIM_UDID manually."
  exit 1
fi

echo "Using simulator: ${SIM_UDID}"

if ! xcodebuild -project YOM.xcodeproj -scheme YOM -destination "id=${SIM_UDID}" -showBuildSettings >/dev/null 2>&1; then
  echo "xcodebuild cannot resolve simulator destination id=${SIM_UDID}."
  echo "Check Xcode Components and install the required iOS Simulator platform/runtime (for Xcode 26.3, install iOS 26.2)."
  exit 1
fi

for run in 1 2 3; do
  echo "=== UI regression run ${run}/3 ==="
  xcrun simctl shutdown "${SIM_UDID}" >/dev/null 2>&1 || true
  xcrun simctl erase "${SIM_UDID}" >/dev/null 2>&1 || true
  xcodebuild \
    -project YOM.xcodeproj \
    -scheme YOM \
    -sdk iphonesimulator \
    -destination "id=${SIM_UDID}" \
    -only-testing:YOMUITests/YOMUITests \
    test
done

echo "All 3 UI regression runs passed."
