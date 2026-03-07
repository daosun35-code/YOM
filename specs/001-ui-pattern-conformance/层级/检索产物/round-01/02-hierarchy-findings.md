# 02 Hierarchy Findings — Round-01

> 执行日期：2026-03-06
> 执行 Spec：App本体组件层级与Token深度检索总控spec.md § Step 2
> 审计范围：`App/`、`Features/`、`Shared/`
> 方法：规则匹配（§4.2 扫描命令）+ 人工代码复核

---

## 汇总

| Severity | 条目数 |
|---|---|
| P0 | 0 |
| P1 | 1 |
| P2 | 1 |
| Pass | 6 |

**整体判定：Conditional Pass（无 P0，存在 P1）**

---

## 详细清单

| Rule ID | Finding | Severity | Evidence | Fix Owner |
|---|---|---|---|---|
| HIER-001 | NavigationStack 真源唯一：三个 Tab 各有且仅有一个 `NavigationStack(path:)`，真源均为 `AppShellState`（`@EnvironmentObject`） | ✅ Pass | `ArchiveTabRootView.swift:45` `MapTabRootView.swift:206` `SettingsTabRootView.swift:23` `AppShellState.swift:35-51` | — |
| HIER-002 | `navigationDestination` 放置点合规：Archive 挂在 `List` modifier（:141）、Settings 挂在 `Form` modifier（:70），均为懒容器整体的修饰器而非内容闭包内——符合 Apple WWDC22 建议 | ✅ Pass | `ArchiveTabRootView.swift:141` `SettingsTabRootView.swift:70` | — |
| HIER-003 | Push/Modal 语义分离正确：Archive 用 `archivePath.append()` 下钻 `RetrievalView`；Settings 用 `NavigationLink(value:)` 下钻 `AboutView`；Map Preview 用 `sheet(item:)` 自包含任务；Onboarding 用 `Group { if/else }` + opacity 过渡（App 级全屏替换，非叠加 Modal） | ✅ Pass | `AppRootView.swift:12-37` `ArchiveTabRootView.swift:66` `SettingsTabRootView.swift:37` `MapTabRootView.swift:209` | — |
| HIER-004 | Sheet 状态源唯一：全 App 仅一处 `sheet`，绑定 `$state.previewPoint`（`MapScreenState.@Published previewPoint: PointOfInterest?`） | ✅ Pass | `MapTabRootView.swift:209` | — |
| HIER-005 | Sheet 关闭路径收敛：所有关闭路径（`onClose` 回调、系统拖拽 dismiss、`handleNavigationAction()`、UI 测试注入）均归结为 `previewPoint = nil`，无二义性分支 | ✅ Pass | `MapScreenState:89-90,94-102` `MapTabRootView.swift:230,898` | — |
| HIER-006 | `safeAreaInset` 与背景层覆盖责任分离：Map 背景层（`Map`/`DSColor.surfaceSecondary`）使用 `.ignoresSafeArea(edges: [.top, .bottom])` 延伸至屏幕边缘；导航 Pill 通过 `mapCanvas.safeAreaInset(edge: .top)` 正确推入 safe area；悬浮按钮（search trigger、locateMe）通过 `overlay + padding(.top, floatingControlsTopInset)` 在 safe area 坐标系内偏移 | ✅ Pass | `MapTabRootView.swift:286-305` `:406` `:459` | — |
| HIER-007 | **`UIScreen.main.bounds` 弃用 API + iPad Split View 布局错位**：`searchPanelWidth`（:476）使用 `UIScreen.main.bounds.width`，该 API 在 iOS 16+ 标记 deprecated；`TARGETED_DEVICE_FAMILY = "1,2"` 声明支持 iPad，在 iPad Split View / Stage Manager 下将取全屏宽度而非窗口宽度，导致搜索面板宽度溢出容器。应替换为 `GeometryReader` 或 SwiftUI `containerRelativeFrame` 读取实际容器宽度 | **P1** | `MapTabRootView.swift:476` `YOM.xcodeproj:TARGETED_DEVICE_FAMILY=1,2` | Map feature owner |
| HIER-008 | **`mapPath` 持久化但无 `navigationDestination` 注册**：`AppShellState` 将 `mapPath: NavigationPath` 持久化至 UserDefaults（:41-45），而 `MapTabRootView` 没有注册任何 `navigationDestination`，mapPath 也从未被 append。若未来添加 Map push 导航但忘记注册 destination，SwiftUI 会静默丢弃路由项，无运行时警告。当前无实际损坏，属架构层隐患 | P2 | `AppShellState.swift:41-45` `MapTabRootView.swift:206`（无 navigationDestination） | Map feature owner |

---

## 各维度评述

### 维度 B1：NavigationStack 真源
全部合规。AppShellState 持有三条 NavigationPath，Tab Root View 各持一条，无额外 @State NavigationStack 嵌套。

### 维度 B2：navigationDestination 放置点
Archive 与 Settings 均将 `navigationDestination` 挂在懒容器（List/Form）的**外部** modifier 链上，与容器内部行闭包隔离，符合规范。Map Tab 不使用 push 导航，无 navigationDestination 需注册（HIER-008 是可维护性隐患，非当前功能错误）。

### 维度 B3：Push/Modal 语义
- 层级钻取（Archive → Retrieval，Settings → About）：push ✅
- 自包含预览（Map Pin → Preview Sheet）：sheet ✅
- App 级首次运行 gate（Onboarding）：inline Group 替换 + opacity ✅（不叠加 modal，语义正确）

### 维度 B4：Sheet 状态
全局唯一 sheet，状态由 MapScreenState 持有，绑定双向同步，所有关闭路径收敛一致。

### 维度 B5：safeAreaInset 责任分离
Map 层级：
- 地图渲染背景：`ignoresSafeArea` → 延伸至屏幕四角 ✅
- 导航 Pill（active navigation 时）：`safeAreaInset(edge: .top)` → 正确占据 safe area slot ✅
- 悬浮 FAB 按钮：`overlay + floatingControlsTopInset` → 在 safe area 坐标内偏移，无白条/覆盖问题 ✅
- Archive 子菜单：`safeAreaInset(edge: .top, spacing: 0)` → 正确推入 List 内容 ✅

---

## 修复优先级

### P1 — HIER-007（建议本轮修复）

**文件**：`Features/Map/MapTabRootView.swift:476`

**当前**：
```swift
private var searchPanelWidth: CGFloat {
    min(DSControl.searchPanelMaxWidth, UIScreen.main.bounds.width - DSSpacing.space24)
}
```

**建议**：从 `GeometryReader` 或 `@Environment(\.containerSize)` / `.containerRelativeFrame` 读取实际可用宽度，避免 iPad Split View 取全屏宽度的错误。示例方向（具体实现由 owner 决定）：
```swift
// 方案 A：在 mapCanvas 外层或合适位置通过 GeometryReader 捕获宽度并传入
// 方案 B：使用 .containerRelativeFrame (iOS 17+)
```

### P2 — HIER-008（下轮清理）

若 Map 未来计划添加 push 导航，应在同轮补全 `navigationDestination` 注册；若确认 Map 永久不使用 push，可考虑移除 `mapPath` 的持久化逻辑，避免 UserDefaults 噪音。

---

## 下一步（Step 3 准备）

- 本轮 Step 2 产物：✅ `02-hierarchy-findings.md`（本文件）
- 建议 Step 3 重点：视觉一致性审计，重点关注 Token 覆盖率（HIER-007 的 `searchPanelWidth` 修复可与 Step 3 同步落地）
- HIER-007 P1 应在 Step 3 视觉审计前落地，避免 iPad 截图基准错位
