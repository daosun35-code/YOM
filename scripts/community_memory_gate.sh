#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

GATE_ID="${1:-}"
PROJECT="${PROJECT:-YOM.xcodeproj}"
SCHEME="${SCHEME:-YOM}"
SPEC_PATH="specs/002-community-memory-backend/后端实装spec.md"

usage() {
  cat <<'EOF'
Usage:
  scripts/community_memory_gate.sh <GATE-ID>

Environment:
  DEST      Optional xcodebuild destination string
  SIM_UDID  Optional simulator UDID fallback (translated to DEST=id=<SIM_UDID>)
  PROJECT   Optional project path (default: YOM.xcodeproj)
  SCHEME    Optional scheme (default: YOM)
EOF
}

resolve_destination() {
  if [[ -n "${DEST:-}" ]]; then
    echo "${DEST}"
    return 0
  fi

  if [[ -n "${SIM_UDID:-}" ]]; then
    echo "id=${SIM_UDID}"
    return 0
  fi

  local auto_udid
  auto_udid="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone 17 Pro|iPhone 17|iPhone 16 Pro|iPhone 16|iPhone/ {print $2; exit}')"
  if [[ -n "${auto_udid}" ]]; then
    echo "id=${auto_udid}"
    return 0
  fi

  return 1
}

require_destination() {
  local resolved
  if ! resolved="$(resolve_destination)"; then
    echo "No iPhone simulator destination found. Set DEST or SIM_UDID explicitly."
    exit 1
  fi
  echo "${resolved}"
}

run_xcodebuild_with_dest() {
  local destination="$1"
  shift
  xcodebuild \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -sdk iphonesimulator \
    -destination "${destination}" \
    "$@"
}

require_test_method() {
  local method_name="$1"
  rg -n "func ${method_name}\\(" YOMUITests >/dev/null
}

require_test_class() {
  local class_name="$1"
  rg -n "final class ${class_name}" YOMUITests >/dev/null
}

run_gate_config_plist_keys() {
  local settings
  settings="$(xcodebuild -project "${PROJECT}" -target YOM -showBuildSettings)"
  echo "${settings}" | rg -n "INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription = .+"
  echo "${settings}" | rg -n "INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription = .+"
}

run_gate_module_0b0c_implemented() {
  test -f Features/Memory/ExplorationStore.swift
  test -f Features/Memory/CardRenderer.swift
  test -f Features/Memory/GeofenceMonitor.swift
  test -f Features/Memory/NotificationOrchestrator.swift
  rg -n "protocol ExplorationStoreProtocol" Features/Memory/ExplorationStore.swift
  rg -n "protocol CardRendererProtocol" Features/Memory/CardRenderer.swift
  rg -n "protocol GeofenceMonitorProtocol" Features/Memory/GeofenceMonitor.swift
  rg -n "protocol NotificationOrchestratorProtocol" Features/Memory/NotificationOrchestrator.swift
  rg -n "final class ExplorationStoreTests|final class CardRendererTests|final class GeofenceMonitorTests|final class NotificationOrchestratorTests" YOMUITests
}

run_gate_owner_placeholder() {
  ! rg -q "^\| T-PR[0-9]-[0-9]{2} \|.*@TBD \|" "${SPEC_PATH}"
}

if [[ -z "${GATE_ID}" ]]; then
  usage
  exit 1
fi

case "${GATE_ID}" in
  GATE-BUILD)
    DEST_RESOLVED="$(require_destination)"
    run_xcodebuild_with_dest "${DEST_RESOLVED}" build
    ;;
  GATE-DATA-INTEGRITY)
    DEST_RESOLVED="$(require_destination)"
    require_test_class "LocalMemoryDataIntegrityTests"
    run_xcodebuild_with_dest "${DEST_RESOLVED}" -only-testing:YOMUITests/LocalMemoryDataIntegrityTests test
    ;;
  GATE-UI-MAP-PIN-TEST)
    DEST_RESOLVED="$(require_destination)"
    require_test_method "testMapPointPinVisibleAfterOnboarding"
    run_xcodebuild_with_dest "${DEST_RESOLVED}" -only-testing:YOMUITests/YOMUITests/testMapPointPinVisibleAfterOnboarding test
    ;;
  GATE-UI-MEMORY-TITLE-TEST)
    DEST_RESOLVED="$(require_destination)"
    require_test_method "testMemoryDetailTitleAssertion"
    run_xcodebuild_with_dest "${DEST_RESOLVED}" -only-testing:YOMUITests/YOMUITests/testMemoryDetailTitleAssertion test
    ;;
  GATE-CONFIG-PLIST-KEYS)
    run_gate_config_plist_keys
    ;;
  GATE-MODULE-0B0C-IMPLEMENTED)
    run_gate_module_0b0c_implemented
    ;;
  GATE-SNAPSHOT-BASELINE-TESTS)
    DEST_RESOLVED="$(require_destination)"
    require_test_method "testSnapshotBaselineRetrievalPage"
    run_xcodebuild_with_dest "${DEST_RESOLVED}" -only-testing:YOMUITests/YOMUITests/testSnapshotBaselineRetrievalPage test
    ;;
  GATE-SNAPSHOT-THRESHOLD-CONFIG)
    rg -n "snapshotDiffTolerance: Double = 0.01|snapshotChannelDeltaTolerance: Int = 8" YOMUITests/YOMUITests.swift
    ;;
  GATE-BG-REFRESH-GUARD-TEST)
    DEST_RESOLVED="$(require_destination)"
    require_test_method "testBackgroundRefreshUnavailableShowsGuidance"
    run_xcodebuild_with_dest "${DEST_RESOLVED}" -only-testing:YOMUITests/YOMUITests/testBackgroundRefreshUnavailableShowsGuidance test
    ;;
  GATE-OWNER-PLACEHOLDER)
    run_gate_owner_placeholder
    ;;
  GATE-I18N)
    DEST_RESOLVED="$(require_destination)"
    rg -n "case en|case zhHans|case yue" Shared/Localization/AppLanguage.swift
    require_test_method "testMemoriesJSONDecodesAndUsesValidUniqueIDs"
    run_xcodebuild_with_dest "${DEST_RESOLVED}" -only-testing:YOMUITests/LocalMemoryDataIntegrityTests/testMemoriesJSONDecodesAndUsesValidUniqueIDs test
    ;;
  GATE-EXPLORATIONSTORE-TESTS)
    DEST_RESOLVED="$(require_destination)"
    require_test_class "ExplorationStoreTests"
    run_xcodebuild_with_dest "${DEST_RESOLVED}" -only-testing:YOMUITests/ExplorationStoreTests test
    ;;
  GATE-CARDRENDERER-TESTS)
    DEST_RESOLVED="$(require_destination)"
    require_test_class "CardRendererTests"
    run_xcodebuild_with_dest "${DEST_RESOLVED}" -only-testing:YOMUITests/CardRendererTests test
    ;;
  GATE-GEOFENCE-TESTS)
    DEST_RESOLVED="$(require_destination)"
    require_test_class "GeofenceMonitorTests"
    run_xcodebuild_with_dest "${DEST_RESOLVED}" -only-testing:YOMUITests/GeofenceMonitorTests test
    ;;
  GATE-NOTIFICATION-TESTS)
    DEST_RESOLVED="$(require_destination)"
    require_test_class "NotificationOrchestratorTests"
    run_xcodebuild_with_dest "${DEST_RESOLVED}" -only-testing:YOMUITests/NotificationOrchestratorTests test
    ;;
  GATE-PR1-COMPOSITE)
    "$0" GATE-BUILD
    "$0" GATE-DATA-INTEGRITY
    "$0" GATE-UI-MAP-PIN-TEST
    "$0" GATE-UI-MEMORY-TITLE-TEST
    "$0" GATE-SNAPSHOT-BASELINE-TESTS
    "$0" GATE-SNAPSHOT-THRESHOLD-CONFIG
    "$0" GATE-BG-REFRESH-GUARD-TEST
    "$0" GATE-CONFIG-PLIST-KEYS
    "$0" GATE-OWNER-PLACEHOLDER
    ;;
  *)
    echo "Unknown gate: ${GATE_ID}"
    usage
    exit 1
    ;;
esac

echo "${GATE_ID} PASS"
