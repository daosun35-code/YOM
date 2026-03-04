# 001 UI Pattern Conformance（导航与细节链路）总控 Spec

> 文档日期：2026-03-04（America/New_York）  
> 目标：把“导航与细节内容链路”中的冗余操作、排版不规范、UI 重叠风险收敛为可分步落地的整改任务。  
> 适用范围：`Features/Map/MapTabRootView.swift`、`Shared/Localization/AppStrings.swift`、`YOMUITests/YOMUITests.swift`、`docs/app-routine.md`。

## 1. 本轮问题清单（审计结论）

### P0-001 顶部导航胶囊与定位按钮重叠
- 现象：导航进行中，顶部 `NavigationPill` 与 `Locate Me` 同时出现在右上区域，存在交叠风险。
- 本地运行态证据（iPhone 17 Pro，模拟器）：
1. `map_top_navigation_pill_container`：`x=12, y=66, w=378, h=62.67`
2. `map_locate_me`：`x=346, y=70, w=44, h=44`
3. 两者横纵坐标区间有交集。
- 代码锚点：
1. `safeAreaInset(.top)` 导航胶囊：`MapTabRootView.swift` 约 314-325 行
2. `.overlay(alignment: .topTrailing)` 定位按钮：约 326-346 行

### P1-002 链路遗留冗余代码与状态
- 现象：`routeOverlay` 相关 UI 已从渲染链路下线，但函数与分支保留；`isRouteLoading` 多处写入但无消费。
- 风险：维护成本上升，后续改动易误判真实路径。
- 代码锚点：
1. `isRouteLoading`：约 20、730、735、746、752、758、793 行
2. `routeOverlay` / `routeStatusFeedback` / `routeIssueFeedbackText`：约 678-850 行

### P1-003 失败恢复路径步数偏长
- 现象：路由失败后用户需“先开详情，再点 Retry”。
- 风险：恢复效率低，失败态可操作性弱。
- 代码锚点：
1. 打开详情入口：约 315-320 行
2. Retry 仅在详情 Sheet：约 1133-1143 行

### P1-004 文案与层级语义有冲突点
- 现象：
1. 详情页 `navigationTitle(details)` 与 `Section(details)` 语义重复。
2. `routeFailedRetry` 文案表达“会自动重试”，但 UI 又提供显式 `Retry` 按钮。
- 代码锚点：
1. 详情页 section/title：约 1082、1100 行
2. `routeFailedRetry`：`AppStrings.swift` 约 350-355 行

### P2-005 文档与实现不一致
- 现象：`docs/app-routine.md` 仍写“route overlay 常驻”和“Details 直达 Retrieval”，与现实现状不一致。
- 锚点：`docs/app-routine.md` 约 29、42、68 行。

## 2. 目标态（完成后）

1. 导航态顶部元素不重叠，关键操作均可点击。  
2. 路由状态表达只有一套真源，删除下线遗留逻辑。  
3. 路由失败恢复入口“近、快、可见”，减少无效跳转。  
4. 文案与交互行为一致，详情页信息层级无重复标题。  
5. 文档、代码、测试三者对齐，不再出现流程描述分叉。

## 3. 行业规范对标（用于审计依据）

1. Apple Design Tips（目标尺寸与文本重叠规避）：https://developer.apple.com/design/tips/
2. Apple Safe Area（避免关键 UI 被边界/系统区域影响）：https://developer.apple.com/videos/play/tech-talks/204/
3. Material Bottom Sheet（细节内容与关闭语义）：
- https://developer.android.com/develop/ui/compose/quick-guides/content/create-bottom-sheet
- https://developer.android.com/develop/ui/compose/components/bottom-sheets
4. Flutter `showModalBottomSheet`（背景点击关闭默认语义）：https://api.flutter.dev/flutter/material/showModalBottomSheet.html
5. 地图空白点击取消选中/关闭浮层常见语义：
- https://developers.google.com/maps/documentation/ios-sdk/reference/objc/Protocols/GMSMapViewDelegate
- https://leafletjs.com/reference.html
- https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/PopupOptions/
6. WCAG 2.2 Target Size（44x44）：https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html

## 4. 四步执行协议（供其他对话窗口直接分工）

> 规则：每个窗口只做一个步骤；一步一提交；不要跨步改文件。  
> 交接：每步结束后在 PR/回复里输出“变更文件 + 验收结果 + 未决风险”。

### Step 1（窗口 A）- 先解 P0 重叠风险
- 目标：导航胶囊与 `map_locate_me` 在所有导航态不重叠。
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
2. `YOMUITests/YOMUITests.swift`
- 必做事项：
1. 为定位按钮引入导航态动态避让（位置或 inset 调整）。
2. 新增/更新 UI Test：断言 `map_top_navigation_pill_container` 与 `map_locate_me` 同时存在时无交叠。
- DoD：
1. 两个元素均 `isHittable == true`。
2. 测试稳定通过。

### Step 2（窗口 B）- 缩短失败恢复链路
- 目标：失败恢复从“2 步”收敛到“1 步可触达”。
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
2. `YOMUITests/YOMUITests.swift`
3. `Shared/Localization/AppStrings.swift`（如需改提示文案）
- 必做事项：
1. 在导航主层提供轻量 Retry 快捷入口（仅在 `failed/unavailable` 显示）。
2. 保留详情页 Retry，二者行为一致（都触发 `retryRoute()`）。
3. 更新测试覆盖“主层 Retry 可恢复”。
- DoD：
1. 用户无需先开详情即可重试。
2. 详情页重试路径不回退。

### Step 3（窗口 C）- 清理冗余并修正文案语义
- 目标：删除死代码与无效状态，消除语义冲突。
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
2. `Shared/Localization/AppStrings.swift`
- 必做事项：
1. 清理 `routeOverlay`、`routeStatusFeedback`、`routeIssueFeedbackText` 等下线遗留实现。
2. 评估并移除未被消费的 `isRouteLoading`（若无需保留）。
3. 修正 `routeFailedRetry` 文案为“显式重试语义”。
4. 调整 `MapPreviewDetailSheet` 的重复标题层级。
- DoD：
1. `rg` 不再检出无用分支。
2. 文案语义与实际交互一致。

### Step 4（窗口 D）- 文档与回归收口
- 目标：文档、测试、实现完全一致并可交付。
- 允许改动文件：
1. `docs/app-routine.md`
2. `specs/001-ui-pattern-conformance/层级/导航详情分步整改spec.md`
3. `specs/001-ui-pattern-conformance/spec.md`（仅更新执行记录）
- 必做事项：
1. 修正文档中的过时流程（删除 route overlay 旧描述、改写 Details 链路）。
2. 在本 spec 追加“执行结果”区块，记录四步状态。
3. 补充剩余测试/快照说明。
- DoD：
1. 文档描述与当前 UI 行为一致。
2. 回归说明可被新窗口直接复用。

## 5. 每步统一验收模板

1. 功能：本步目标行为可触达、无回退。  
2. 可访问性：关键入口保持 44x44 及可读 label/hint。  
3. 回归：至少包含 1 条 UI 自动化断言。  
4. 变更控制：仅改本步允许文件，不夹带其他任务。

## 6. 给其他对话窗口可直接复制的执行指令

### 窗口 A 指令
“按 `specs/001-ui-pattern-conformance/spec.md` 的 Step 1 执行，只改允许文件，完成后回传：变更文件、测试结果、风险。”

### 窗口 B 指令
“按 `specs/001-ui-pattern-conformance/spec.md` 的 Step 2 执行，只改允许文件，完成后回传：失败恢复链路前后对比和测试结果。”

### 窗口 C 指令
“按 `specs/001-ui-pattern-conformance/spec.md` 的 Step 3 执行，只改允许文件，完成后回传：删除了哪些冗余代码、文案如何调整。”

### 窗口 D 指令
“按 `specs/001-ui-pattern-conformance/spec.md` 的 Step 4 执行，只改允许文件，完成后回传：文档对齐清单和最终验收结论。”

## 7. 执行记录

- 2026-03-04：总控 spec 建立，待四步分窗口执行。
- 2026-03-04：Step 1 完成。导航胶囊与 `map_locate_me` 解除重叠，导航态双元素可点击；回归锚点：`testNavigationShowsSingleTopStatusContainerBaseline`。
- 2026-03-04：Step 2 完成。主层新增失败态 quick retry，详情页保留 retry，二者统一触发 `retryRoute()`；回归锚点：`testMapRouteRetryFlowAfterFailure`。
- 2026-03-04：Step 3 完成。清理 `routeOverlay` 下线遗留与无消费状态，`Details`/重试文案语义与行为一致，详情页标题层级去重；回归锚点：`testPreviewDetailsOpensMapSheetWithoutImmediateRetrieval`、`testEndNavigationRequiresConfirmation`。
- 2026-03-04：Step 4 完成。`docs/app-routine.md` 与分层 spec 已按当前实现对齐，并补充回归与快照使用说明，可直接复用于后续窗口交接。
