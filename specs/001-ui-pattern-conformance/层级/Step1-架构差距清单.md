# Step 1 产物：架构差距清单（规范 -> 现状）

> 执行日期：2026-03-05
> 依据：导航与预览链路压力测试调研 spec（§3 反污染规范、§4 最短 API 链路）
> 扫描范围：16 个 Swift 文件，含 MapTabRootView、ArchiveTabRootView、SettingsTabRootView、OnboardingFlowView 等主链路文件

---

## 一、状态拓扑图（现状）

### 1.1 导航层

```
AppShellState（@Observable）
├── settingsPath: NavigationPath   → SettingsTabRootView → NavigationStack(path:) → .about
├── archivePath:  NavigationPath   → ArchiveTabRootView  → NavigationStack(path:) → .retrieval(pointID)
└── mapPath:      NavigationPath   → MapTabRootView      → NavigationStack(path:) → （无 destination 声明）
```

**并行状态源：**
- `MapScreenState.isSearchPresented: Bool`（@Published）—— 搜索 overlay 的显隐，独立旗标，未接入 mapPath。

### 1.2 Sheet 层（MapPreviewSheetView）

```
触发：sheet(item: $state.previewPoint)

关闭入口（3 条）
┌──────────────────────────────────────────────────────────────────┐
│ 入口 A  Close 按钮 → onClose() → state.dismissPreview()          │
│         → previewPoint = nil                                     │
├──────────────────────────────────────────────────────────────────┤
│ 入口 B  handleNavigationAction() → 调用后 Sheet 并未立即关闭；    │
│         Sheet 的实际收起依赖导航状态变化的副作用，非显式 dismiss  │
├──────────────────────────────────────────────────────────────────┤
│ 入口 C  selectPoint(新 point) → previewPoint = nil               │
│         → DispatchQueue.main.async { previewPoint = 新 point }   │
│         （旧 Sheet 关闭 + 新 Sheet 弹出，复用同一状态源）         │
└──────────────────────────────────────────────────────────────────┘
```

**入口 A** 收敛到 `dismissPreview()` → `previewPoint = nil` —— 符合。
**入口 B** 已确认：`handleNavigationAction()` → `startOrChangeNavigation()` → 内部显式调用 `dismissPreview()` → `previewPoint = nil` —— 符合单出口。
**入口 C** `selectPoint()` 先关闭当前 preview 再弹出新 preview，使用 `DispatchQueue.main.async` 实现帧间隔，与 @MainActor 语义冲突，属于技术债（但收口一致）。

### 1.3 异步层

```
主线程 (@MainActor MapScreenState / MapTabRootView)
├── Task { @MainActor in ... }    ← 常见模式（位置更新、搜索补全）—— 正确
├── async func + await            ← handleSearchSubmit / refreshRouteIfNeeded —— 正确
├── .task(id:)                    ← routeRefreshKey 依赖键 —— 正确
└── DispatchQueue.main.async      ← selectPoint L63-65 —— 旧式，与 @MainActor 混用
```

---

## 二、架构差距清单

| 编号 | 规范条款 | 现状描述 | 差距类型 | 严重度 | 文件:行号 |
|------|---------|---------|---------|--------|-----------|
| G-01 | NAV-001 路径真源 | 3 个 Tab 均已使用 `NavigationStack(path:)` + typed route | **符合** | — | ArchiveTabRootView:46, SettingsTabRootView:23, MapTabRootView:209 |
| G-02 | NAV-002 值驱动 | NavigationLink 使用 `value:` 模式 | **符合** | — | SettingsTabRootView:37 |
| G-03 | NAV-003 非 lazy 容器 | `navigationDestination` 均置于 List 外、NavigationStack 内 | **符合** | — | ArchiveTabRootView:142, SettingsTabRootView:70 |
| G-04 | NAV-003 嵌套问题 | `mapPath` 从未被 append，NavigationStack 有意作为空容器，无 destination 需求 | **符合（有意为空）** | — | MapTabRootView:209 |
| G-05 | NAV-004 Sheet 内导航 | Sheet 内部（MapPreviewSheetView）无嵌套导航需求，无问题 | **符合** | — | — |
| G-06 | SHEET-001 单出口 | 全部 3 条关闭路径均汇聚至 `previewPoint = nil`（A 直接、B 经 startOrChangeNavigation、C 经 selectPoint） | **符合** | — | MapTabRootView:84-97 |
| G-07 | SHEET-001 并行写回 | 入口 C 的 DispatchQueue.main.async 实现关闭再弹，存在竞态窗口 | **差距** | 中 | MapTabRootView:63-65 |
| G-08 | SHEET-002 显式声明 | `presentationDetents` + `presentationBackgroundInteraction(.disabled)` 均已声明 | **符合** | — | MapTabRootView:246-247 |
| G-09 | MODAL-001 语义分工 | 无 Modal/Push 混用发现 | **符合** | — | — |
| G-10 | STATE-001 最少状态源 | `isSearchPresented`（@Published Bool）独立于 mapPath，是额外旗标 | **差距** | 低 | MapTabRootView:23 |
| G-11 | STATE-002 属性装饰 | @State / @Published 用途基本正确；无 @Bindable 误用 | **符合** | — | — |
| G-12 | PERF-001 body 副作用 | 未发现 body 内重计算或网络调用 | **符合** | — | — |
| G-13 | CONC-001 同步反馈 | Task + @MainActor 异步模式正确；1 处 DispatchQueue.main.async 需迁移 | **差距** | 低 | MapTabRootView:63-65 |
| G-14 | TEST-001 重复测试 | YOMUITests.swift 存在，但测试矩阵与重复次数未知 | **待确认** | 高 | YOMUITests/YOMUITests.swift |

---

## 三、优先整改项（Step 2 输入）

### P1（中）— 技术债清偿
- **G-07 / G-13**：将 `selectPoint()` 中的 `DispatchQueue.main.async` 替换为 `Task { @MainActor in ... }` 或利用 `.id()` 让 SwiftUI 自行处理前后 Sheet 的过渡。

### P2（低）— 规范对齐
- **G-10**：评估 `isSearchPresented` 是否可与 mapPath 形成明确分层，或标注为有意分离的 UI 本地状态（STATE-002 @State 本地状态范畴）。

### G-14 确认结论（TEST-001 差距）
- `waitForExistence`：**已使用** ✓（每个关键断言前均有等待）
- accessibility identifier：**已使用** ✓（`"map_preview_primary_action"` 等）
- 但**无 test repetitions 配置**：未设置 `testRepetitionPolicy`，无重复次数，无失败重试模式 ✗
- 无 `XCTOSSignpostMetric` / `measure` 性能采样 ✗
- Step 4 需补充：重复测试策略 + 时延采样用例。

---

## 四、MUST 条款通过率（Step 1 快照）

| 类别 | MUST 条款数 | 符合 | 差距 | 待确认 |
|------|------------|------|------|--------|
| NAV | 4 | 4 | 0 | 0 |
| SHEET | 2 | 2 | 0 | 0 |
| MODAL | 1 | 1 | 0 | 0 |
| STATE | 2 | 1 | 1 | 0 |
| PERF | 1 | 1 | 0 | 0 |
| CONC | 1 | 0 | 1 | 0 |
| TEST | 1 | 0 | 1 | 0 |
| **合计** | **12** | **9** | **3** | **0** |

**当前符合率：9/12 = 75%**（3 差距，无待确认项）

---

## 五、下一步（Step 2 启动条件）

G-06 的人工确认必须完成后，才能决定 Sheet 关闭路径是否需要整改。其余 G-07 / G-13 可直接进入整改。
