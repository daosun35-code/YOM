# 001 App 本体组件层级与 Token 整改执行 Spec（Round-02）

> 文档日期：2026-03-06（America/New_York）  
> 来源：`检索产物/round-01`（`00/01/02/03` 报告）  
> 目标：把 round-01 中可执行问题转为代码整改与回归闭环，优先清理 P1，再收敛关键 P2。

## 1. Round-01 输入问题（作为本轮待办）

1. P1：`MapTabRootView.searchPanelWidth` 使用全屏宽度口径，iPad 分屏/多窗口场景可能错位。  
2. P2：EndNavigation teardown 动画时长硬编码（`0.16`），缺少 DS Motion token。  
3. P2：caption 图标字号存在 raw `.font(.caption...)`，缺少统一 `DSTypography` 锚点。  
4. P2：Preview Sheet 紧凑高度边界值在页面局部常量，未纳入 DSControl。

## 2. 本轮执行目标（Done 定义）

1. 搜索面板宽度改为容器宽度驱动，不再依赖全屏口径。  
2. EndNavigation teardown 动画接入 `DSMotion`，并兼容 Reduce Motion 分支。  
3. 新增 `DSTypography.iconSmall`，替换活跃组件中的 caption 图标 raw font。  
4. Preview Sheet 紧凑高度边界迁移到 `DSControl`。

## 3. 分步执行

### Step 1（P1）容器宽度口径整改

- 文件：
1. `Features/Map/MapTabRootView.swift`
- 任务：
1. 记录 map 实际容器宽度（`GeometryReader` + 状态同步）。
2. `searchPanelWidth` 改为基于容器宽度计算并做最小值保护。
- DoD：
1. 不使用全屏口径推导搜索面板宽度。
2. 在窗口尺寸变化时宽度可更新。

### Step 2（P2）Motion/Typo token 化

- 文件：
1. `Shared/DesignSystem/DSTokens.swift`
2. `Shared/DesignSystem/DSTypography.swift`
3. `Features/Map/MapTabRootView.swift`
- 任务：
1. `DSMotion` 增加 teardown token 与统一入口函数。
2. `DSTypography` 增加 `iconSmall`。
3. 替换 `MapTabRootView` 中活跃 caption 图标 raw font。
- DoD：
1. teardown 动画不再硬编码。
2. caption 图标有 DS Typography 锚点。

### Step 3（P2）Sheet 高度边界归一

- 文件：
1. `Shared/DesignSystem/DSTokens.swift`
2. `Features/Map/MapTabRootView.swift`
- 任务：
1. `previewSheetCompactMinHeight/MaxHeight` 迁移到 `DSControl`。
2. 页面内读取统一从 `DSControl` 获取。
- DoD：
1. 页面内不再保留重复硬编码边界值。

### Step 4 回归验证（最小集）

- 命令：
```bash
xcodebuild test -project YOM.xcodeproj -scheme YOM -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:YOMUITests/YOMUITests/testSearchButtonPresentsKeyboardImmediately \
  -only-testing:YOMUITests/YOMUITests/testTopNavigationEndActionEndsNavigationImmediately \
  -only-testing:YOMUITests/YOMUITests/testMapPinPreviewLayoutStabilityChangingDestination
```
- DoD：
1. 三条关键用例通过。
2. 若模拟器资源波动导致失败，必须记录失败模式与复现条件。

## 4. 非目标（Round-02 不做）

1. 不处理死代码组件删除（`NavigationInlineDetailCard` / `NavigationDetailSheet` / `NavigationTaskInfoRow`）。  
2. 不调整 `mapPath` 持久化策略。  
3. 不重写全量视觉规范，仅做 Token 化收敛。

## 5. 执行记录

1. 2026-03-06：Round-02 执行 spec 创建。
2. 2026-03-06：Step 1-3 代码已落地。
3. 2026-03-06：Step 4 回归（首轮）结果（Simulator）：
   1. `testSearchButtonPresentsKeyboardImmediately`：Pass。
   2. `testTopNavigationEndActionEndsNavigationImmediately`：Pass。
   3. `testMapPinPreviewLayoutStabilityAndAccessibility`：Fail（`map_locate_me.isHittable` 断言失败，`YOMUITests.swift:488`）。
   4. `testMapPinPreviewLayoutStabilityChangingDestination`：Pass。
4. 2026-03-06：BUG-001 修复 — 根因：`.presentationBackgroundInteraction(.disabled)` 屏蔽了 sheet 背景层所有交互，包括视觉上未被遮挡的 `map_locate_me` 按钮。
   修复：改为 `.presentationBackgroundInteraction(.enabled(upThrough: previewSheetCompactDetent))`。
   语义：compact detent 时背景可交互（locateMe 可点击）；sheet 展开至 `.large` 时背景禁止交互（保留原 UX）。
   文件：`Features/Map/MapTabRootView.swift:250`。
5. 2026-03-06：Step 4 回归（终轮）结果（Simulator，iPhone 17 Pro）：
   - 4 tests, 0 failures。
   - `testSearchButtonPresentsKeyboardImmediately`：✅ Pass。
   - `testTopNavigationEndActionEndsNavigationImmediately`：✅ Pass。
   - `testMapPinPreviewLayoutStabilityAndAccessibility`：✅ Pass（`map_locate_me.isHittable` 现已通过）。
   - `testMapPinPreviewLayoutStabilityChangingDestination`：✅ Pass。
   - **整体判定：Pass（Round-02 全部 DoD 满足）**。

## 7. 补充回归结果（2026-03-08）

### 背景
BUG-001 修复（`.presentationBackgroundInteraction(.disabled)` → `.enabled(upThrough: compact)`）在首轮回归后发现引入了新的交互回归：
tap-outside-to-dismiss 失效（BUG-002）。

### BUG-002 根因
`.enabled(upThrough: previewSheetCompactDetent)` 使 tap 穿透 scrim 到 `mapCanvas`，
但 `mapCanvas` 无显式 dismiss handler，sheet 不再响应背景区域单击关闭。

### BUG-002 修复
文件：`Features/Map/MapTabRootView.swift`，紧接 `.accessibilityIdentifier("map_interaction_surface")` 后新增：
```swift
.onTapGesture {
    if state.previewPoint != nil {
        withAnimation(shellAnimation) {
            state.dismissPreview()
        }
    }
}
```
语义：`mapCanvas` 在 preview 激活时响应单击 → dismiss；子视图（Map annotation Button）因手势优先级更高，pin 点击不受影响。

### 补充回归测试结果（Simulator，iPhone 17 Pro，2026-03-08）

命令：
```bash
xcodebuild test -project YOM.xcodeproj -scheme YOM \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:YOMUITests/YOMUITests/testPreviewTapOutsideDismissesSheet \
  -only-testing:YOMUITests/YOMUITests/testPreviewCloseAndTapOutsideDismissConsistently \
  -only-testing:YOMUITests/YOMUITests/testPinSwitchDoesNotFlickerOrShowBothSheets \
  -only-testing:YOMUITests/YOMUITests/testMapPinPreviewLayoutStabilityAndAccessibility \
  -only-testing:YOMUITests/YOMUITests/testTopNavigationEndActionEndsNavigationImmediately
```

| 用例 | 结果 |
|---|---|
| testPreviewTapOutsideDismissesSheet | ✅ Pass |
| testPreviewCloseAndTapOutsideDismissConsistently | ✅ Pass |
| testPinSwitchDoesNotFlickerOrShowBothSheets | ✅ Pass |
| testMapPinPreviewLayoutStabilityAndAccessibility | ✅ Pass |
| testTopNavigationEndActionEndsNavigationImmediately | ✅ Pass |

**5 tests，0 failures。**

### 补充回归最终判定：Pass

**剩余风险（最多3条）：**
1. `map_locate_me` + tap-outside-dismiss 在真机真实 Map 视图（非静态快照）的组合行为尚未覆盖——模拟器静态快照测试通过，真机 MapKit 渲染需人工验证 `onTapGesture` 不与 Map 的双击缩放手势形成竞态。
2. 真机 YOMStressTests A/B 链路时延门禁（P95/P99）仍未采样，属 Round-02 遗留 MUST 项。
3. Pin Switch 链路 C 在真机的稳定性/skip ratio 未验证（MapKit 渲染依赖）。

## 6. 剩余问题（Round-02 范围外，留下一轮）

| ID | 描述 | 优先级 | 说明 |
|---|---|---|---|
| HIER-008 | `mapPath` 持久化但无 `navigationDestination` 注册 | P2 | 架构层隐患，无当前功能损坏 |
| VCNS-001 | Archive(16pt) vs Settings(24pt) 水平 padding 无统一 DSLayout 命名 | P2 | iPad 适配前处理 |
| 真机门禁 | YOMStressTests 链路 A/B P50/P95/P99 需真机采样 | MUST | 模拟器时延为工具开销，不反映实际性能 |
