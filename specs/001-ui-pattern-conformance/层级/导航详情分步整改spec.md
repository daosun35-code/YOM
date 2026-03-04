# 001 Map 导航/详情交互分步整改 Spec（最小颗粒度）

> 目的：把“点击导航/详情后 UI 不合理”问题拆成可单独提交、可回滚、可验收的微任务。  
> 适用范围：`Features/Map/MapTabRootView.swift`、`Shared/Localization/AppStrings.swift`、`YOMUITests/YOMUITests.swift`。  
> 关键词：`navigation detail` `map sheet hierarchy` `destructive action weight` `single top status`.

## 1. 问题基线（当前代码）

### ND-B001 顶部信息层重复
- 现象：导航中同时出现 `routeOverlay` 与 `NavigationPillView`，都表达“导航进行中”。
- 代码锚点：
  - `mapCanvas` 中 `routeOverlay` 渲染：`Features/Map/MapTabRootView.swift` 约 271-279 行
  - `safeAreaInset(.top)` 中 `NavigationPillView`：约 280-292 行
  - `routeOverlay` 本体：约 632-667 行

### ND-B002 详情入口导致上下文跳变
- 现象：点预览卡 `Details` 后直接走 `retrievalPoint`，打开 `fullScreenCover`，离开地图上下文。
- 代码锚点：
  - `showDetails()`：约 89-93 行
  - `fullScreenCover(item: $state.retrievalPoint)`：约 234-241 行
  - 预览卡 `onDetails`：约 216-218、922-924 行

### ND-B003 危险动作入口重复且前置
- 现象：`End` 在顶部胶囊与详情页内都可触发。
- 代码锚点：
  - `NavigationPillView` 内 `map_end_navigation`：约 999-1018 行
  - `NavigationDetailSheet` 内 `map_end_navigation_in_sheet`：约 1047-1053 行

### ND-B004 预览态主次动作权重过近
- 现象：`Go/Change Destination` 与 `Details` 都是 CTA 风格，视觉竞争。
- 代码锚点：
  - `primaryActionButton`：约 910-919 行
  - `secondaryActionButton`：约 921-929 行

### ND-B005 导航详情页“信息类型不对齐”
- 现象：详情页以地点摘要为主，导航任务信息为辅。
- 代码锚点：
  - `NavigationDetailSheet` `Section(strings.navigationActive)`：约 1035-1044 行

## 2. 目标样貌（最终态）

1. 顶部只保留一个导航主状态容器，不再双层表达同一语义。  
2. 点 `Details` 先进入地图内详情 Sheet（`medium/large detent`），不直接全屏跳转。  
3. `End Navigation` 收敛到详情层（或其更多操作区），不作为主层常驻动作。  
4. 预览卡只保留一个强主 CTA；`Details` 降为弱次级动作。  
5. 导航详情内容以导航任务信息优先，地点叙述次之。  

## 3. 拆分原则（执行约束）

1. 一次只做一个 `ND-Txxx` 任务；一个任务对应一个 PR。  
2. 每个任务改动文件不超过 3 个。  
3. 每个任务必须可独立回滚，不引入“半成品状态”。  
4. 每个任务必须至少有 1 条可执行验收（UI Test 或可观察断言）。  

## 4. 分步任务清单（最小颗粒度）

| ID | 任务 | 触达文件 | 前置 | 完成定义（DoD） |
|---|---|---|---|---|
| ND-T001 | 给顶部两个容器分别补可识别 `accessibilityIdentifier`（临时）用于基线验证 | `Features/Map/MapTabRootView.swift` | 无 | UI Test 可同时定位两个容器，建立现状基线 |
| ND-T002 | 新增 UI Test：断言导航中当前存在双顶部容器（基线测试，后续会改） | `YOMUITests/YOMUITests.swift` | ND-T001 | 测试可稳定复现当前问题 |
| ND-T003 | 在 `mapCanvas` 移除 `routeOverlay` 的渲染入口（保留函数体暂不删） | `Features/Map/MapTabRootView.swift` | ND-T002 | 导航中顶部只剩 `NavigationPillView` |
| ND-T004 | 删除/下线与 `routeOverlay` 相关的顶部 offset 依赖，修正 `map_locate_me` 遮挡风险 | `Features/Map/MapTabRootView.swift` | ND-T003 | 导航中定位按钮可点击且无遮挡 |
| ND-T005 | 更新/替换 ND-T002 测试：断言导航中仅有一个顶部状态容器 | `YOMUITests/YOMUITests.swift` | ND-T003 | 测试通过并锁定“单顶部容器” |
| ND-T006 | 在 `MapScreenState` 新增 `previewDetailPoint`（或同义字段） | `Features/Map/MapTabRootView.swift` | 无 | 状态层具备“地图内详情”独立承载位 |
| ND-T007 | 将 `showDetails()` 从写入 `retrievalPoint` 改为写入 `previewDetailPoint` | `Features/Map/MapTabRootView.swift` | ND-T006 | 点 `Details` 不再直接触发 `fullScreenCover` |
| ND-T008 | 新增地图内详情 `sheet(item:)`（`medium/large` detent）承载详情入口 | `Features/Map/MapTabRootView.swift` | ND-T007 | 点 `Details` 打开详情 Sheet，地图仍在上下文内 |
| ND-T009 | 在新详情 Sheet 内增加“Open Retrieval”动作，才触发 `retrievalPoint` | `Features/Map/MapTabRootView.swift` | ND-T008 | Retrieval 变为二级进入，不再一跳全屏 |
| ND-T010 | 新增 UI Test：验证 `Details -> 详情 Sheet`，且未立即进入 Retrieval | `YOMUITests/YOMUITests.swift` | ND-T008 | 新测试稳定通过 |
| ND-T011 | 新增 UI Test：验证 `Details -> Open Retrieval -> Retrieval` 完整链路 | `YOMUITests/YOMUITests.swift` | ND-T009 | 新测试稳定通过 |
| ND-T012 | 从 `NavigationPillView` 移除 `End` 按钮，仅保留“打开详情”主入口 | `Features/Map/MapTabRootView.swift` | ND-T008 | 顶部主层不再出现 destructive 操作 |
| ND-T013 | 保留 `NavigationDetailSheet` 中 `End Navigation + confirmationDialog` 作为唯一结束入口 | `Features/Map/MapTabRootView.swift` | ND-T012 | 结束导航仍可执行，且必须确认 |
| ND-T014 | 更新现有 `testEndNavigationRequiresConfirmation`：改为“先开详情，再结束” | `YOMUITests/YOMUITests.swift` | ND-T013 | 旧测试逻辑完成迁移并通过 |
| ND-T015 | 将预览卡 `secondaryActionButton` 从 `dsSecondaryCTAStyle()` 降级为弱次级文本动作 | `Features/Map/MapTabRootView.swift` | 无 | 预览卡视觉上只剩一个强主 CTA |
| ND-T016 | 校正文案：`detailsText`、详情入口 hint，使其体现“先看详情，再进回溯” | `Shared/Localization/AppStrings.swift` | ND-T008 | 文案语义与实际流转一致 |
| ND-T017 | 在 `NavigationDetailSheet` 增加导航任务信息区（ETA/距离/状态）并置顶 | `Features/Map/MapTabRootView.swift` | ND-T003 | 详情页首屏优先展示导航信息 |
| ND-T018 | 将地点 summary 区降到次级 section，并保持可读性与行数约束 | `Features/Map/MapTabRootView.swift` | ND-T017 | 信息层级变为“导航优先，地点次之” |
| ND-T019 | 更新 Map 快照基线与快照测试说明 | `YOMUITests/SnapshotBaselines/*`, `YOMUITests/SnapshotBaselines/README.md` | ND-T018 | Map 基线与新结构一致 |

## 5. 每步通用验收模板

1. 功能：本步目标交互可完成，且不影响 `Go/Change Destination` 主链路。  
2. 可访问性：关键入口有可读 label/hint，触控目标仍满足最小点击面积。  
3. 回归：`testAccessibilityReduceMotionPathKeepsPrimaryFlowStable` 通过。  
4. 快照：若本步影响视觉，更新对应 baseline 并说明变更原因。  

## 6. 执行顺序建议

1. 先做结构去重：`ND-T001` 到 `ND-T005`。  
2. 再做详情流转改造：`ND-T006` 到 `ND-T011`。  
3. 再做危险动作降权：`ND-T012` 到 `ND-T014`。  
4. 最后做视觉语义收口：`ND-T015` 到 `ND-T019`。  

## 7. 非目标（本轮不做）

1. 不引入 UIKit 自定义导航容器。  
2. 不重做地图渲染与路线算法。  
3. 不重写 Archive/Settings 页面，仅处理本 Spec 涉及路径。  
