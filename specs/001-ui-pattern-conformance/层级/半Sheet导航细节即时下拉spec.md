# 001 半 Sheet 导航交互精简整改 Spec

> 目的：把“半 Sheet 动作缺失 + 更改目的地提示文案冗余 + 顶部导航延迟弹详情”收敛为可分步执行、可回归的整改任务。  
> 文档日期：2026-03-05（America/New_York）  
> 适用范围：`Features/Map/MapTabRootView.swift`、`Shared/Localization/AppStrings.swift`、`YOMUITests/YOMUITests.swift`。

## 0. 检索标签（建议原样复用）

`半sheet细节保留` `半sheet取消保留` `changeDestinationHint 删除` `导航pill极简箭头` `延迟弹出详情` `map_top_navigation_pill_container`

## 1. 问题定义（当前基线）

### HS-NAV-001 半 Sheet 状态下丢失关键动作

1. 现象：预览 Sheet 处于紧凑高度时，只保留主 CTA，`细节` 与 `取消/关闭` 不可见。  
2. 影响：用户在半 Sheet 中无法直接完成“看细节/退出”，交互闭环不完整。  
3. 代码锚点：`MapPreviewSheetView.actionSection` 仅在 `!isCompact` 时渲染 `secondaryActionButton` 与 `closeActionButton`（`Features/Map/MapTabRootView.swift`）。

### HS-NAV-002 更改目的地模式下文案冗余

1. 现象：更改目的地模式显示“这个将会替代……”提示文案（`changeDestinationHint`），挤占紧凑高度可用空间。  
2. 影响：动作区可达性下降，且文案信息价值低于操作本身。  
3. 代码锚点：`if isChangingDestination { Text(changeDestinationHint) }`（`Features/Map/MapTabRootView.swift`）。

### HS-NAV-003 顶部导航点击触发延迟弹详情

1. 现象：半 Sheet 打开时点击顶部导航栏，短时间无反馈；后续点击“更改目的地”或关闭半 Sheet，突然弹出导航详情页。  
2. 影响：用户感知为“点击失效 + 随机跳页”，可预期性差。  
3. 代码锚点：
   - 顶部点击直接触发 `state.openNavigationDetail()` -> `isNavigationDetailPresented = true`。  
   - 同时存在 `.sheet(item: $state.previewPoint)` 与 `.sheet(isPresented: $state.isNavigationDetailPresented)`，形成双 Sheet 竞争（`Features/Map/MapTabRootView.swift`）。

## 2. 目标态（完成标准）

1. 半 Sheet 模式下固定保留 `细节` 与 `取消` 两个动作，且均可点击。  
2. 更改目的地模式下删除“这个将会替代……”提示文案，不再渲染 `changeDestinationHint`。  
3. 顶部导航 pill 不再承担“打开导航细节”功能，不再触发详情 Sheet/inline 卡。  
4. 顶部导航 pill 右侧仅保留一个极简箭头提示（视觉提示，不新增详情层级）。  
5. 关闭半 Sheet、点击更改目的地时，不再出现延迟补弹的详情页。  
6. 导航中点击“当前正在导航的 pin”仍可打开预览 Sheet，但不显示主按钮（`map_preview_primary_action`），仅保留 `细节/取消`。  
7. 关键交互在 UI Test 中可稳定复现并回归。

## 3. 行业对标（交互依据）

1. Apple（WWDC 2021）：Bottom Sheet 应依据内容与任务复杂度控制展示层级，避免在紧凑态堆叠低价值内容。  
https://developer.apple.com/videos/play/wwdc2021/10063/
2. Android Bottom Sheet（Compose）：部分展开态应优先保证核心动作可达，避免状态悬挂。  
https://developer.android.com/develop/ui/compose/components/bottom-sheets-partial
3. NN/g Progressive Disclosure：低优先信息应延后暴露，避免与主任务竞争注意力。  
https://www.nngroup.com/articles/progressive-disclosure/
4. Apple（WWDC 2022）：`chevron` 属于层级/披露提示语义，应避免“可点但无结果”的误导交互。  
https://developer.apple.com/videos/play/wwdc2022/10001/

## 4. 根因拆解（便于实施时对照）

1. 交互缺口：`isCompact` 分支隐藏了次级动作，导致半 Sheet 缺少细节/取消。  
2. 内容冗余：`changeDestinationHint` 在紧凑态消耗高度预算，放大排版压力。  
3. 状态冲突：预览 Sheet 与导航详情 Sheet 并行声明，顶部点击在预览 Sheet 存在时被挂起。  
4. 清理缺失：关闭预览或切换目的地时，未统一清空待展示详情状态，导致延迟补弹。

## 5. 分步骤执行（严格按序）

> 规则：一步一提交；每步只改允许文件；不可跨步夹带。  
> 交付格式：`变更文件` + `验收结果` + `残余风险`。

### Step 1（状态机先行）- 下线顶部导航细节触发链路

- 目标：消除“顶部点击后延迟弹详情页”的状态根因。  
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
- 必做事项：
1. 顶部导航 pill 点击不再触发 `isNavigationDetailPresented = true`。  
2. 清理或收敛与顶部点击详情相关的挂起状态，避免“延迟补弹”。  
3. 在关闭预览/切换目的地/结束导航时统一清理待展示详情状态。  
- DoD：
1. 半 Sheet 开启时点击顶部导航 pill，不会打开导航详情页。  
2. 状态切换路径无循环依赖与悬挂。

### Step 2（交互补齐）- 半 Sheet 常驻“细节 + 取消”并移除替代提示

- 目标：在紧凑态恢复基础动作并删除冗余文案。  
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
2. `Shared/Localization/AppStrings.swift`（仅当 `changeDestinationHint` 无消费后清理）
- 必做事项：
1. `isCompact == true` 时也渲染 `map_preview_secondary_details` 与 `map_preview_close_action`。  
2. 删除 `isChangingDestination` 下 `changeDestinationHint` 的 UI 渲染。  
3. 保证 `细节`、`取消` 行为与当前链路一致且可达。  
- DoD：
1. 半 Sheet 下 `细节`、`取消` 始终可见。  
2. 更改目的地模式下不再出现“这个将会替代……”提示文案。

### Step 3（视觉提示）- 顶部导航 pill 右侧极简箭头

- 目标：保留轻量状态提示，不引入详情层。  
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
- 必做事项：
1. 在 `map_top_navigation_pill_container` 右侧加入极简箭头（建议 `chevron.down`，低对比、12-14pt）。  
2. 箭头不设置独立点击行为，不新增详情弹层入口。  
3. 可访问性语义避免误导：箭头不被朗读为独立按钮。  
- DoD：
1. 导航 pill 右侧可见极简箭头提示。  
2. 点击 pill 或箭头均不会触发导航详情页。

### Step 4（回归加固）- 用例改造与防回退

- 目标：把问题固化为自动化断言，避免回归。  
- 允许改动文件：
1. `YOMUITests/YOMUITests.swift`
- 必做事项：
1. 新增：半 Sheet 下 `map_preview_secondary_details`、`map_preview_close_action` 存在且可点击。  
2. 新增：更改目的地模式下，“这个将会替代……”文案不存在。  
3. 新增：点击 `map_top_navigation_pill_container` 后，不出现导航详情 Sheet。  
4. 新增：导航 pill 右侧箭头提示存在（可用独立 identifier：`map_top_navigation_pill_chevron`）。  
5. 新增：导航中点击当前导航目标 pin，预览 Sheet 出现且 `map_preview_primary_action` 不存在。  
- DoD：
1. 新旧测试在本地稳定通过。  
2. 核心链路（导航、改目的地、结束导航）不回退。

## 6. 每步统一验收模板

1. 功能：是否满足本步目标交互。  
2. 可访问性：关键入口是否具备可读标签和足够触控面积。  
3. 一致性：是否彻底移除“顶部导航细节触发”旧链路。  
4. 回归：是否新增/更新至少 1 条 UI 自动化断言。

## 7. 非目标（本轮不做）

1. 不改路线规划算法与导航 ETA 计算逻辑。  
2. 不重做 Map 页面整体视觉风格。  
3. 不扩展到 Archive/Settings 等非地图页面。

## 8. 可复制执行指令（给后续窗口）

### 窗口 A 指令（Step 1）
“按 `半Sheet导航细节即时下拉spec.md` 的 Step 1 执行，下线顶部导航细节触发链路，只改允许文件，回传状态机变更与风险。”

### 窗口 B 指令（Step 2）
“按 Step 2 执行，确保半 Sheet 始终保留‘细节/取消’，并删除更改目的地提示文案，回传前后交互对比。”

### 窗口 C 指令（Step 3）
“按 Step 3 执行，为导航 pill 右侧加入极简箭头提示（无点击行为），回传可访问性处理方式。”

### 窗口 D 指令（Step 4）
“按 Step 4 执行，补齐 UI Test（无文案、无延迟弹页、有箭头提示），回传测试清单与结果。”
