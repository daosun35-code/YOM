#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
FLAG_FILE="YOMUITests/SnapshotBaselines/.record-mode"

SIM_UDID="${SIM_UDID:-$(xcrun simctl list devices available | awk -F '[()]' '/iPhone 17/ {print $2; exit}')}"
if [[ -z "${SIM_UDID}" ]]; then
  echo "No available iPhone 17 simulator found. Set SIM_UDID manually."
  exit 1
fi

echo "Recording snapshot baselines on simulator: ${SIM_UDID}"
xcrun simctl boot "${SIM_UDID}" >/dev/null 2>&1 || true
xcrun simctl bootstatus "${SIM_UDID}" -b

touch "${FLAG_FILE}"
trap 'rm -f "${FLAG_FILE}"' EXIT

if ! xcodebuild -project YOM.xcodeproj -scheme YOM -destination "id=${SIM_UDID}" -showBuildSettings >/dev/null 2>&1; then
  echo "xcodebuild cannot resolve simulator destination id=${SIM_UDID}."
  echo "Check Xcode Components and install the required iOS Simulator platform/runtime (for Xcode 26.3, install iOS 26.2)."
  exit 1
fi

UITEST_RECORD_BASELINES=1 xcodebuild \
  -project YOM.xcodeproj \
  -scheme YOM \
  -sdk iphonesimulator \
  -destination "id=${SIM_UDID}" \
  -only-testing:YOMUITests/YOMUITests/testSnapshotBaselineOnboardingPage \
  -only-testing:YOMUITests/YOMUITests/testSnapshotBaselineMapPage \
  -only-testing:YOMUITests/YOMUITests/testSnapshotBaselineArchivePage \
  -only-testing:YOMUITests/YOMUITests/testSnapshotBaselineSettingsPage \
  -only-testing:YOMUITests/YOMUITests/testSnapshotBaselineRetrievalPage \
  test

echo "Snapshot baseline recording completed."
