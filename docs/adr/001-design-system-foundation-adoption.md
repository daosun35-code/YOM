# ADR 001: Adopt Minimal SwiftUI Design System Foundation

- Date: 2026-03-03
- Status: Accepted
- Deciders: YOM iOS maintainers

## Context

YOM feature pages had scattered visual constants (colors, spacing, radius, button patterns), which made cross-page UI changes costly and increased the risk of visual drift.

`docs/DesignSystem_spec.md` defines a mandatory migration baseline:
- Tokens as single source of truth
- Feature layer (`Features/`) consumes shared design system only
- CI guard blocks design-system regressions

## Decision

Adopt a minimal, native SwiftUI-first design system under `Shared/DesignSystem`:
- `DSTokens.swift`: semantic colors, spacing, radius, border, motion, layout/control constants
- `DSTypography.swift`: text style mapping to Dynamic Type-friendly SwiftUI styles
- `DSStyles.swift`: reusable CTA/card styles

Enforce the boundary with CI:
- `scripts/design_system_guard.sh`
- `.github/workflows/design-system-guard.yml`

## Consequences

### Positive
- UI tokens and style patterns are centralized and reusable.
- Feature pages are visually decoupled from hardcoded values.
- New regressions in `Features/` are blocked automatically in CI.

### Trade-offs
- Slightly higher upfront abstraction cost for simple views.
- Teams must update tokens/changelog before visual changes across pages.

### Follow-up
- Keep token change history in `docs/design-system-changelog.md`.
- If a token must be removed, keep deprecation for at least one iteration and provide replacement guidance.
