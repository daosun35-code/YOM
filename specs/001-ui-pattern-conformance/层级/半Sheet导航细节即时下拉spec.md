# 001 半 Sheet 导航细节即时下拉整改 Spec

> 目的：把“半 Sheet 模式动作缺失 + 顶部导航点击延迟响应”收敛为可分步执行、可回归的整改任务。  
> 文档日期：2026-03-05（America/New_York）  
> 适用范围：`Features/Map/MapTabRootView.swift`、`Shared/Localization/AppStrings.swift`、`YOMUITests/YOMUITests.swift`。

## 0. 检索标签（建议原样复用）

`半sheet细节保留` `半sheet取消保留` `导航栏点击无反应` `延迟弹出详情` `inline detail card` `map_top_navigation_pill_container`

## 1. 问题定义（当前基线）

### HS-NAV-001 半 Sheet 状态下丢失关键动作

1. 现象：预览 Sheet 处于紧凑高度时，只保留主 CTA，`细节` 与 `取消/关闭` 不可见。  
2. 影响：用户在半 Sheet 中无法直接完成“看细节/退出”，交互闭环不完整。  
3. 代码锚点：`MapPreviewSheetView.actionSection` 仅在 `!isCompact` 时渲染 `secondaryActionButton` 与 `closeActionButton`（`Features/Map/MapTabRootView.swift`）。

### HS-NAV-002 顶部导航栏点击后无即时反馈，随后延迟弹详情页

1. 现象：半 Sheet 打开时点击顶部导航栏，短时间无反应；后续点击“更改目的地”或关闭半 Sheet，突然出现导航详情页。  
2. 影响：用户感知为“点击失效 + 随机跳页”，严重破坏可预期性。  
3. 代码锚点：
   - 顶部点击直接触发 `state.openNavigationDetail()` -> `isNavigationDetailPresented = true`。  
   - 同时存在 `.sheet(item: $state.previewPoint)` 与 `.sheet(isPresented: $state.isNavigationDetailPresented)`，形成双 Sheet 竞争（`Features/Map/MapTabRootView.swift`）。

## 2. 目标态（完成标准）

1. 半 Sheet 模式下固定保留 `细节` 与 `取消` 两个动作，且均可点击。  
2. 点击顶部导航栏后，300ms 内从导航栏下方出现“当前行程简洁细节卡”（inline card），而不是无反馈。  
3. 未点击“展开完整详情”前，不进入完整导航详情页。  
4. 关闭半 Sheet、点击更改目的地时，不再出现延迟补弹的详情页。  
5. 关键交互在 UI Test 中可稳定复现并回归。

## 3. 行业对标（交互依据）

1. Google Navigation SDK（iOS）：导航 UI 提供可直接进入 step-by-step directions 的入口，不依赖延迟跳转。  
https://developers.google.com/maps/documentation/navigation/ios-sdk/controls
2. Mapbox Navigation（iOS）：顶部指引栏支持点击/下拉查看指引列表，采用卡片化细节承接。  
https://docs.mapbox.com/ios/navigation/v2/guides/turn-by-turn-navigation/user-interface/
3. Apple Maps：导航中保持可达的详情与退出路径。  
https://support.apple.com/guide/iphone/view-a-route-overview-or-a-list-of-turns-iph1b3553719/ios
4. Android Bottom Sheet：部分展开态应提供明确状态与交互反馈，避免状态悬挂。  
https://developer.android.com/develop/ui/compose/components/bottom-sheets-partial

## 4. 根因拆解（便于实施时对照）

1. 交互缺口：`isCompact` 分支隐藏了次级动作，导致半 Sheet 缺少细节/取消。  
2. 状态冲突：预览 Sheet 与导航详情 Sheet 并行声明，顶部点击在预览 Sheet 存在时被“挂起”。  
3. 反馈缺失：顶部点击后没有即时可见过渡容器（inline 卡片），用户误判为点击失败。  
4. 清理缺失：关闭预览或切换目的地时，未统一清空“待展示详情”的状态，导致延迟补弹。

## 5. 分步骤执行（严格按序）

> 规则：一步一提交；每步只改允许文件；不可跨步夹带。  
> 交付格式：`变更文件` + `验收结果` + `残余风险`。

### Step 1（状态机先行）- 消除双 Sheet 悬挂状态

- 目标：消除“点击顶部后延迟弹详情页”的状态根因。  
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
- 必做事项：
1. 增加“顶部简洁细节卡”独立状态（如 `isInlineNavigationCardPresented`）。  
2. 顶部导航栏点击在半 Sheet 场景不再直接置 `isNavigationDetailPresented = true`。  
3. 在关闭预览/切换目的地/结束导航时，统一清理 inline 卡与待展示详情状态。  
- DoD：
1. 半 Sheet 开启时点击顶部导航栏，不再触发延迟打开 `NavigationDetailSheet`。  
2. 状态切换路径无循环依赖与悬挂。

### Step 2（交互补齐）- 半 Sheet 常驻“细节 + 取消”

- 目标：在紧凑态恢复完整基础动作。  
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
2. `Shared/Localization/AppStrings.swift`（仅在文案需要区分“关闭/取消”时）
- 必做事项：
1. `isCompact == true` 时也渲染 `map_preview_secondary_details` 与 `map_preview_close_action`。  
2. 动作区在紧凑态下保持可读与可点（必要时改成竖排或文本按钮）。  
3. 保证 `细节` 行为与“展开详情层级”一致，`取消` 行为明确关闭当前预览。  
- DoD：
1. 半 Sheet 下 `细节`、`取消` 始终可见。  
2. 三个动作（主 CTA/细节/取消）点击区域满足可达性。

### Step 3（视觉反馈）- 顶部导航栏下拉简洁当前行程卡

- 目标：把顶部点击改成“即时可见反馈”。  
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
2. `Shared/Localization/AppStrings.swift`
- 必做事项：
1. 在 `map_top_navigation_pill_container` 下方新增 inline 细节卡（例如 `map_navigation_inline_detail_card`）。  
2. 卡片最小信息集：下一动作/距离（可用占位）、目的地简名、当前状态。  
3. 卡片内提供“展开完整详情”动作，才进入 `NavigationDetailSheet`。  
4. 卡片支持显式收起，且与半 Sheet 并存不冲突。  
- DoD：
1. 点击顶部导航栏后 300ms 内可见 inline 卡。  
2. 未点击“展开完整详情”不会进入完整详情页。

### Step 4（回归加固）- 用例改造与防回退

- 目标：把问题固化为自动化断言，避免回归。  
- 允许改动文件：
1. `YOMUITests/YOMUITests.swift`
- 必做事项：
1. 新增：半 Sheet 下 `map_preview_secondary_details`、`map_preview_close_action` 存在且可点击。  
2. 新增：半 Sheet 下点击 `map_top_navigation_pill_container` 后，`map_navigation_inline_detail_card` 出现。  
3. 新增：关闭半 Sheet 或点击更改目的地后，不出现“延迟弹出的导航详情页”。  
4. 更新旧用例：需要进入完整详情页时，改为“顶部点击 -> inline 卡 -> 展开完整详情”。  
- DoD：
1. 新旧测试在本地稳定通过。  
2. 核心链路（导航、改目的地、结束导航）不回退。

## 6. 每步统一验收模板

1. 功能：是否满足本步目标交互。  
2. 反馈时延：点击后是否在预期时间内出现可见反馈。  
3. 可访问性：关键入口是否具备可读标签和足够触控面积。  
4. 回归：是否新增/更新至少 1 条 UI 自动化断言。

## 7. 非目标（本轮不做）

1. 不改路线规划算法与导航 ETA 计算逻辑。  
2. 不重做 Map 页面整体视觉风格。  
3. 不扩展到 Archive/Settings 等非地图页面。

## 8. 可复制执行指令（给后续窗口）

### 窗口 A 指令（Step 1）
“按 `半Sheet导航细节即时下拉spec.md` 的 Step 1 执行，只改允许文件，回传状态机变更与风险。”

### 窗口 B 指令（Step 2）
“按 Step 2 执行，确保半 Sheet 始终保留‘细节/取消’，回传前后交互对比。”

### 窗口 C 指令（Step 3）
“按 Step 3 执行，实现顶部点击后从导航栏下拉简洁细节卡，回传关键标识与动画策略。”

### 窗口 D 指令（Step 4）
“按 Step 4 执行，补齐 UI Test 并迁移旧用例到新链路，回传测试清单与结果。”

