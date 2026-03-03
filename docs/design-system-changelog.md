# Design System Changelog

## 2026-03-03

### Added
- `Shared/DesignSystem/DSTokens.swift`
  - Colors: `surfacePrimary`, `surfaceSecondary`, `surfaceElevated`, `textPrimary`, `textSecondary`, `textInverse`, `accentPrimary`, `accentOnPrimary`, `borderSubtle`, `borderStrong`, `statusSuccess`, `statusWarning`, `statusError`
  - Spacing: `space4`, `space8`, `space12`, `space16`, `space24`, `space32`
  - Radius: `r8`, `r12`, `r16`
  - Border widths: `bw1`, `bw2`
  - Motion: `durationFast`, `durationNormal`, `shell(reduceMotion:)`, `routeTransition(reduceMotion:)`
  - Layout/Control: `readableContentMaxWidth`, `onboardingContentMaxWidth`, `minTouchTarget`, `largeButtonHeight`, `listThumbnailSize`, `listItemMinHeight`, `navigationBannerHeight`, `floatingActionTopInsetWithBanner`, `detailHeroHeight`, `overlayPanelMaxHeight`
- `Shared/DesignSystem/DSTypography.swift`
  - Text styles: `display`, `title`, `headline`, `body`, `caption`
  - Helpers: `brandDisplay`, `iconLarge`, `iconMedium`, `View.dsTextStyle(_:weight:)`
- `Shared/DesignSystem/DSStyles.swift`
  - Reusable styles: `DSPrimaryCTAButtonStyle`, `DSSecondaryCTAButtonStyle`, `DSSurfaceCardModifier`
  - Helpers: `dsPrimaryCTAStyle()`, `dsSecondaryCTAStyle()`, `dsSurfaceCard(isSelected:)`

### Changed
- Migrated `Features/Onboarding`, `Features/Map`, `Features/Archive`, `Features/Settings`, `Features/Retrieval` to consume `Shared/DesignSystem` tokens/styles.
- Expanded opacity semantics in `Shared/DesignSystem/DSTokens.swift` and removed magic opacity decimals from style consumers:
  - Added `DSOpacity.controlDisabled`, `primaryPressed`, `secondaryPressed`, `secondaryBorderEnabled`, `secondaryBorderDisabled`
  - Updated `DSColor.borderStrong` to consume `DSOpacity.controlDisabled`
  - Added `DSBorder.routeLine` and replaced page-layer `DSBorder.bw2 * 3`
- Replaced implicit default padding with explicit token consumption:
  - `OnboardingFlowView`: `.padding(.horizontal)` -> `.padding(.horizontal, DSSpacing.space16)`
- Connected reusable style APIs on remaining core pages:
  - `ArchiveTabRootView`: `dsSurfaceCard()`
  - `SettingsTabRootView`: `dsSecondaryCTAStyle()`
  - `RetrievalView`: `dsSurfaceCard()`
- Added CI design-system guard:
  - Workflow: `.github/workflows/design-system-guard.yml`
  - Script: `scripts/design_system_guard.sh`
  - Rule extensions: implicit default axis padding ban, DSBorder arithmetic-with-literal ban in `Features/`, and decimal opacity literal ban in `Shared/DesignSystem/`
- Removed page-scoped naming from control tokens and replaced with semantic role names:
  - `archiveThumbnailSize` -> `listThumbnailSize`
  - `archiveCardMinHeight` -> `listItemMinHeight`
  - `routeBannerHeight` -> `navigationBannerHeight`
  - `locateTopInsetWhenNavigating` -> `floatingActionTopInsetWithBanner`
  - `retrievalHeroHeight` -> `detailHeroHeight`
  - `searchOverlayMaxHeight` -> `overlayPanelMaxHeight`
- Added UI snapshot baseline harness and baseline assets for core pages:
  - Tests: `YOMUITests/YOMUITests.swift`
  - Baselines: `YOMUITests/SnapshotBaselines/*.png`

### Removed
- None.

### Deprecation Policy
- Any token removal requires at least one iteration deprecation period.
- During deprecation, changelog must include replacement token and affected feature list.
