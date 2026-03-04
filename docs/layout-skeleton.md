# Layout Skeleton

> Region structure, layer hierarchy, visibility rules, and system container mapping.

## 1. Layer Model

| Layer | Role | Placement |
|-------|------|-----------|
| 4 — System | Status bar, Dynamic Island, Home Indicator | OS-rendered |
| 3 — Bottom Fixed | Primary bottom widget (one state at a time) | `.overlay(.bottom)` + `.ignoresSafeArea` |
| 2 — Floating | Action buttons, navigation pill, toast, tracking badge | `.overlay` |
| 1 — Content | Scrollable body — lists, cards, carousel, settings | Standard layout |
| 0 — Canvas | Full-bleed background — map, AR camera, solid fill | `.ignoresSafeArea` |

## 2. Bottom Widget Constraint

Exactly **one** of three mutually exclusive states at any time:

| State | Purpose |
|-------|---------|
| Tab bar | Global navigation |
| One-third card | Point preview |
| Full card | Content retrieval |

- **Long-term visual goal (non-blocking for first shell spec):** transitions may later animate as a single container morph.
- **`000-app-shell-routine` first-round rule:** treat the constraint above as a **state exclusivity rule**, not a custom animation requirement. Use system container semantics (`TabView`, `.sheet`, `.fullScreenCover`) and accept default transitions.
- Any future custom morphing container/animation must be defined in a later spec and follow ADR approval if it drops below the official API policy baseline.

## 3. Per-Screen Skeleton

| Screen | L0 Canvas | L1 Content | L2 Floating | L3 Bottom | Status Bar |
|--------|-----------|-----------|-------------|-----------|------------|
| Onboarding ×2 | Solid surface | Centered (dots, logo, buttons) | — | Hidden | Standard |
| Map Default | Full-bleed map | Pins, user position | Search + locate buttons | Tab bar | Standard |
| Map Preview | Map (recentered) | Selected pin | Search + locate | One-third card | Standard |
| Map Navigation | Map + route | Route overlay | Nav pill; buttons conditional | Tab bar | Standard |
| AR | Camera feed | Guide prompt | Back, badge, player | Hidden | Light-on-dark |
| Retrieval | Map background | (inside full card) | — | Full card | Standard |
| Photo Gallery | Black | Photo carousel | Close, counter, label | Hidden | Hidden |
| Settings | Solid surface | Scrollable list | — | Tab bar | Standard |
| Archive | Solid surface | Arc carousel, header | — | Tab bar | Standard |
| About | Solid surface | Centered info | — | Hidden | Standard |

## 4. Visibility Summary

| Screen | Tab Bar | Status Bar |
|--------|---------|------------|
| Onboarding | Hidden | Standard |
| Map Default / Navigation | Visible | Standard |
| Map Preview | Replaced by preview card (system sheet in first round) | Standard |
| AR | Hidden | Light-on-dark |
| Retrieval | Replaced by full card (system sheet / fullScreenCover in first round) | Standard |
| Photo Gallery | Hidden | Hidden |
| Settings / Archive | Visible | Standard |
| About | Hidden | Standard |
