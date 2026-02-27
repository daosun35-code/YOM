# App Routine

> Page-level flow, navigation transitions, and error paths.

## 1. Launch & Onboarding

| Step | Screen | Transition |
|------|--------|------------|
| First launch | Language → Permission → Map | push chain |
| Subsequent | Map (default tab) | direct |

- Language defaults to system locale; takes effect immediately.
- Push permission outcome does not gate map entry.

## 2. Tab Navigation

Three persistent tabs (fixed order): **Archive · Map · Settings**.
Switching preserves each tab's internal state; active indicator slides on tap.

## 3. Map State Machine

| State | Enter | Exit |
|-------|-------|------|
| **Default** | Launch / dismiss preview | — |
| **Preview** | Tap map pin | Tap outside / navigate |
| **Navigation** | Tap "Go" | Arrival CTA / confirm end |

- **Default → Preview**: card rises from bottom; map recenters pin. Card offers "Go" and "Details".
- **Preview → Navigation**: card dismisses; compact pill at top; route overlay. Pill expands to turn-by-turn detail on tap. Tapping another pin during navigation shows "Change Destination".
- **Arrival**: adaptive CTA — AR points: "Immerse" + "Retrieve"; others: "Retrieve" only. Proximity triple-pulse haptic.

## 4. Search

Available in map default state only. Shows text field with recommendations + recent queries.
Result tap → map centers + preview card. Dismiss: cancel / tap outside / swipe down.

## 5. Content Pages

| Page | Entry | Exit | Tab Bar |
|------|-------|------|---------|
| AR | Arrival CTA / retrieval "Immerse" | Back | No |
| Retrieval | "Details" / "Retrieve" / archive card | Pop to root | No |
| Photo Gallery | Tap photo in retrieval | Close | No |
| Settings | Tab | Tab switch | Yes |
| About | Settings → About | Back | No |
| Archive | Tab | Tab switch | Yes |

**Retrieval modes**: (1) Audio-driven — text + photos reveal in sync with narration. (2) Static — scroll freely, all content visible.

## 6. Error Paths

| Scenario | Handling |
|----------|----------|
| Network offline | Toast; cached content accessible |
| Location unavailable | Position hidden; navigation disabled |
| Camera unavailable | Prompt + auto-return |
| Content loading | Skeleton placeholder |
| Content / audio failure | Retry; degrades to static mode |
| Background / foreground | Nav + audio continue; AR pauses/resumes |

## 7. Flow Summary

```
Launch → [First: Language → Permission →] Map
Tabs: Archive ↔ Map ↔ Settings
Map pin → Preview → Go → Navigation → Arrival CTA
  ├─ Immerse → AR (push)    └─ Retrieve → Retrieval (push)
  └─ Details → Retrieval (push) → Photo (hero)
Settings → About (push)
Archive → Card → Retrieval (push)
```
