# UI Snapshot Baselines

This directory stores baseline screenshots required by `YOMUITests` for the five core pages:

- `onboarding.png`
- `map.png`
- `archive.png`
- `settings.png`
- `retrieval.png`

If you see `*.placeholder.png` files, they are invalid seed placeholders and are intentionally ignored by tests. Regenerate real `*.png` baselines before running snapshot assertions.

## Map baseline scope (ND-T019)

- `map.png` is captured from `testSnapshotBaselineMapPage`.
- This baseline represents the default map shell state after onboarding (`UITEST_FORCE_STATIC_MAP_SNAPSHOT` + no active navigation sheet).
- Navigation-detail hierarchy changes from ND-T017/ND-T018 are validated by dedicated UI tests instead of this baseline:
  - `testNavigationDetailShowsTaskInfoBeforePointSummary`
  - `testEndNavigationRequiresConfirmation`

## Record / refresh baselines

Preferred: run the helper script, which auto-picks an available `iPhone 17` simulator by UDID:

```bash
scripts/record_snapshot_baselines.sh
```

The helper script preflights `xcodebuild` destination resolution. If it reports missing platform/runtime, install the matching iOS Simulator component in Xcode first (for Xcode 26.3, this is iOS 26.2).

Manual command (if you need explicit destination):

```bash
SIM_UDID="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone 17/ {print $2; exit}')"
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
```

If you must pin by OS name, use a runtime that is actually installed and visible to `xcodebuild -showdestinations` on your machine.

## Record-mode fallback

If shell environment variables are not propagated to the UI test process on your machine, use the local record-mode marker:

```bash
touch YOMUITests/SnapshotBaselines/.record-mode
xcodebuild \
  -project YOM.xcodeproj \
  -scheme YOM \
  -destination "id=${SIM_UDID}" \
  -only-testing:YOMUITests/YOMUITests/testSnapshotBaselineMapPage \
  test
rm YOMUITests/SnapshotBaselines/.record-mode
```
