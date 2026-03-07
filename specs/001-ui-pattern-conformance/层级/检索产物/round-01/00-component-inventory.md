# Round-01 Component Inventory

> 生成日期：2026-03-06
> 执行人：Claude (Step 1 静态清点)
> 覆盖范围：`App/`、`Features/`、`Shared/`
> 框架栈：SwiftUI + UIKit + MapKit + CoreLocation（无第三方 UI 依赖）

---

## L0 App Shell

| Component | File | Line | Layer | NativeTag | Start | End | Switch |
|---|---|---|---|---|---|---|---|
| YOMApp | App/YOMApp.swift | — | L0 Shell | NativeDirect | app launch | — | — |
| AppRootView | App/AppRootView.swift | 3 | L0 Shell | NativeDirect | onAppear / `languageStore.hasCompletedOnboarding` 驱动 | — | tab switch via `AppShellState.selectedTab` |

**备注**
- `AppRootView` 内通过 `TabView(selection:)` 持有三个 tab；
- 当 `!hasCompletedOnboarding` 时以 `fullScreenCover` 弹出 `OnboardingFlowView`；
- 动画由 `DSMotion.shell(reduceMotion:)` 控制（已 Token 化）。

---

## L1 Feature Root

| Component | File | Line | Layer | NativeTag | Start | End | Switch |
|---|---|---|---|---|---|---|---|
| ArchiveTabRootView | Features/Archive/ArchiveTabRootView.swift | 4 | L1 Root | NativeDirect | tab select | tab deselect | NavigationStack path push (`ArchiveRoute`) |
| MapTabRootView | Features/Map/MapTabRootView.swift | 140 | L1 Root | NativeDirect | tab select | tab deselect | pin tap / search submit |
| SettingsTabRootView | Features/Settings/SettingsTabRootView.swift | 3 | L1 Root | NativeDirect | tab select | tab deselect | NavigationLink push (`SettingsRoute`) |
| OnboardingFlowView | Features/Onboarding/OnboardingFlowView.swift | 4 | L1 Root | NativeDirect | `!hasCompletedOnboarding`（fullScreenCover） | `hasCompletedOnboarding = true` | step enum 切换（`.language` → `.permission`） |
| RetrievalView | Features/Retrieval/RetrievalView.swift | 3 | L1 Root | NativeDirect | modal present（sheet/fullScreenCover，调用方决定） | modal dismiss | — |
| AboutView | Features/Settings/SettingsTabRootView.swift | 86 | L1 Child (Settings 子页) | NativeDirect | NavigationLink push | back pop | — |

**备注**
- 三个 Tab Root 各持有一个 `NavigationStack(path:)` 真源，挂点均在 root body 直接子层（合规）；
- `navigationDestination` 均直接挂在 `NavigationStack` 直接子 view 上，未放入 `List/LazyVStack`（合规）；
- `OnboardingFlowView` 无自有 NavigationStack；
- `RetrievalView` 的 NavigationStack 层级由调用方决定，需在 Step 2 确认。

---

## L2 Map 子组件

| Component | File | Line | Layer | NativeTag | Start | End | Switch |
|---|---|---|---|---|---|---|---|
| MapPreviewSheetView | Features/Map/MapTabRootView.swift | 1039 | L2 Map Sheet | NativeDirect | `sheet(item: $state.previewPoint)` — pin tap 触发 | `previewPoint = nil`（Close/下滑/Go） | 新 pin tap 时 `previewPoint` 替换（`id` 变更重置 detent） |
| PreviewMetadataChip | Features/Map/MapTabRootView.swift | 1217 | L2 Map Atom | NativeDirect | `MapPreviewSheetView` body 内渲染 | — | — |
| NavigationPillView | Features/Map/MapTabRootView.swift | 1246 | L2 Map Overlay | NativeDirect | `state.navigationPoint != nil`（`safeAreaInset` 条件渲染） | `endNavigation()` → `navigationPoint = nil` | — |
| NavigationInlineDetailCard | Features/Map/MapTabRootView.swift | 1292 | L2 Map Card | NativeDirect | ⚠️ **DEAD CODE**（定义但无调用方） | — | — |
| NavigationDetailSheet | Features/Map/MapTabRootView.swift | 1442 | L2 Map Sheet | NativeDirect | ⚠️ **DEAD CODE**（定义但无调用方） | — | — |
| NavigationTaskInfoRow | Features/Map/MapTabRootView.swift | 1598 | L2 Map Atom | NativeDirect | `NavigationDetailSheet` 内部渲染（死代码上下文） | — | — |
| SearchOverlayCard | Features/Map/MapTabRootView.swift | 1628 | L2 Map Overlay | NativeDirect | `state.isMapDefaultState && state.isSearchPresented`（overlay 条件渲染） | `isSearchPresented = false` | — |

**备注**
- `NavigationInlineDetailCard` 与 `NavigationDetailSheet` 在文件内仅有 struct 定义，**全文无调用点**，属于死代码。其中 `NavigationDetailSheet` 内部嵌套了一个 `NavigationStack`，若被激活将违反"每个 Tab Root 仅一个 NavigationStack 真源"规则（P1），但当前无实际影响。
- 死代码条目应在 Step 2 / Step 5 中决定删除或补齐。

---

## L3 平台桥接 / 服务

| Component | File | Line | Layer | NativeTag | 桥接原因 | Start | End |
|---|---|---|---|---|---|---|---|
| NativeSearchTextField | Features/Map/MapTabRootView.swift | 910 | L3 Bridge | NativeBridge（UIViewRepresentable） | 需要精确控制 `becomeFirstResponder` 时机（键盘焦点延迟策略）；SwiftUI TextField 无等效 API | `state.isSearchPresented = true`（搜索栏渲染） | `isSearchFieldFirstResponder = false`（搜索关闭） |
| DeferredFirstResponderTextField | Features/Map/MapTabRootView.swift | 988 | L3 Bridge | NativeBridge（UITextField 子类） | `NativeSearchTextField` 内部实现，提供延迟 `becomeFirstResponder` 行为 | `makeUIView` 创建时 | dealloc |
| MapSearchModel | Features/Map/MapTabRootView.swift | 1778 | L3 Service | NativeDirect（MKLocalSearchCompleter） | — | `@StateObject` 初始化 | 随 `MapTabRootView` 生命周期结束 |
| UserLocationProvider | Features/Map/MapTabRootView.swift | 1833 | L3 Service | NativeDirect（CLLocationManager） | — | `@StateObject` 初始化 | 随 `MapTabRootView` 生命周期结束 |

---

## 统计摘要

| 分类 | 数量 |
|---|---|
| 总组件数（含死代码） | 18 |
| NativeDirect | 15 |
| NativeBridge | 2 |
| NonNative | 0 ✅ |
| 死代码组件 | 3（NavigationInlineDetailCard、NavigationDetailSheet、NavigationTaskInfoRow） |
| 桥接理由完整 | 2/2 ✅ |
