# Accessibility & Localization

> Active spec — a11y requirements and internationalization rules.

---

## 1. Color Contrast

- Body text on any background: contrast ratio ≥ 4.5:1 (WCAG AA).
- Large text (≥ 18 pt regular or ≥ 14 pt bold) and interactive elements: ≥ 3:1.
- Never rely on color alone to convey meaning; pair with icons or labels.

---

## 2. VoiceOver

- Every interactive element must declare an accessibility **label** and **trait**.
- Map annotations must include a semantic description (year, place name, distance).
- Decorative images and icons are hidden from the accessibility tree.
- Photos in content pages carry descriptive alt text.

---

## 3. Dynamic Type

- All text styles must support iOS Dynamic Type scaling.
- Layouts must not truncate critical information at the largest accessibility sizes.
- At extreme sizes secondary details may be collapsed or hidden, but primary content remains legible.
- Minimum rendered font size: 11 pt.

---

## 4. Reduce Motion

- When the system "Reduce Motion" preference is enabled, all spring and slide animations are replaced with a simple 200 ms fade transition.
- Hero transitions (e.g., photo thumbnail to gallery) fall back to crossfade.

---

## 5. Touch Targets

- All tappable elements must have a hit area of at least 44 × 44 pt.
- Core actions are reachable with one hand during outdoor walking use.

---

## 6. Three-Language Support

### 6.1 Supported Languages

| Code | Display | Audio |
|------|---------|-------|
| `.en` | English | English |
| `.zhHans` | 简体中文 | Mandarin |
| `.yue` | 粵語（繁體） | Cantonese |

### 6.2 Text Length Planning

- English is the longest variant and serves as the upper-bound for layout testing.
- Chinese variants are approximately 50–70 % of English length.
- All directions are LTR.

### 6.3 Formatting Rules

| Dimension | English | Chinese / Cantonese |
|-----------|---------|---------------------|
| Dates | "Mar 15, 1935" | "1935年3月15日" |
| Distance | feet / miles | meters / km |
| Numerals & punctuation | Half-width | Half-width |

- Button labels must never truncate; use `lineLimit(1)` with a minimum scale factor.
- Numbers and punctuation are always half-width regardless of language.

### 6.4 Runtime Switching

- Language changes take effect instantly without an app restart.
- All user-facing strings are centralized in a single string registry that switches on the current language.
- The current language is persisted to `UserDefaults` and injected as an observable environment value so all views react automatically.

---

## 7. Content Tone

- Warm, narrative, respectful — the experience should feel like leafing through community archives, not browsing a database.
- Avoid overly academic language; use friendly second-person guidance.
