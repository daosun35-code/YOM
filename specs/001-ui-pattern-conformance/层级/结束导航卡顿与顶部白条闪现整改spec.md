# 001 结束导航卡顿与顶部白条闪现整改 Spec

> 目的：把“点击结束导航后体感卡顿 + 顶部白条闪现”问题沉淀为可分步执行、可回归、可跨会话复用的整改规范。  
> 文档日期：2026-03-05（America/New_York）  
> 适用范围：`Features/Map/MapTabRootView.swift`、`YOMUITests/YOMUITests.swift`、`docs/app-routine.md`。

## 0. 检索标签（建议原样复用）

`结束导航卡顿` `顶部白条闪现` `safeAreaInset 抖动` `confirmationDialog 锚点` `map_top_navigation_end_action` `navigation teardown`

## 1. 问题定义（当前基线）

### END-UX-001 结束导航后出现“慢半拍”体感

1. 现象：点击顶部 `End` 并确认后，界面会出现短暂“卡一下”再完成退出导航。  
2. 用户感知：确认操作已点击，但主界面反馈滞后，接近“点击不够跟手”。  
3. 代码锚点（当前实现）：
1. 顶部结束按钮触发 `confirmationDialog`：`NavigationPillView`。  
2. 确认后在 `withAnimation(shellAnimation)` 内直接执行 `state.endNavigation()`。  
3. `shellAnimation` 使用 spring 风格 `DSMotion.routeTransition(...)`。  

### END-UX-002 结束导航瞬间顶部白条闪现

1. 现象：确认结束后，屏幕顶部会短暂闪现白色条带。  
2. 用户感知：像是界面“抽帧”或布局跳变。  
3. 代码锚点（当前实现）：
1. 顶部导航容器通过 `.safeAreaInset(edge: .top)` 注入。  
2. 结束后 `navigationPoint = nil` 导致顶部 inset 区域瞬时收起。  
3. 地图层只 `.ignoresSafeArea(edges: .bottom)`，顶部未持续铺满。

### END-UX-003 销毁中视图承载确认弹层

1. 现象：确认弹层挂在 `NavigationPillView` 上，而该 view 会在结束动作后立刻从树中移除。  
2. 风险：弹层 dismiss 与容器 teardown 并行，增加动画/布局冲突概率。  
3. 代码锚点：`NavigationPillView` 内局部 `@State isEndNavigationDialogPresented` + `.confirmationDialog(...)`。

## 2. 目标态（完成标准）

1. 点击“结束导航”确认后，导航退出反馈稳定、无明显卡顿。  
2. 退出导航过程中不出现顶部白条闪现。  
3. 破坏性动作仍保留二次确认（不可降级为一步误触）。  
4. 导航退出后，地图主层与顶部控件状态切换一致，不出现残留容器/补弹。

## 3. 行业对标（交互依据）

1. Apple Maps：结束路线入口位于底部路线卡（非顶部状态条）。  
https://support.apple.com/en-az/guide/iphone/iph837d13d03/ios
2. Google Maps：退出导航入口位于底部信息卡操作区。  
https://support.google.com/maps/answer/3273406?co=GENIE.Platform%3DiOS&hl=en-SG
3. Waze：停止导航入口位于底部 ETA/路线操作区。  
https://support.google.com/waze/answer/6286774
4. SwiftUI：`safeAreaInset` 与 `ignoresSafeArea` 的容器行为会直接影响安全区回收过程中的视觉连续性。  
https://developer.apple.com/documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:)  
https://developer.apple.com/documentation/swiftui/view/ignoressafearea(_:edges:)

## 4. 根因拆解（便于实施时对照）

1. 动画耦合：确认动作与导航态销毁在同一事务内执行，且使用 spring 动画，导致 teardown 体感拖尾。  
2. 布局突变：顶部 `safeAreaInset` 容器随状态立即移除，安全区高度瞬时回收。  
3. 视觉兜底不足：地图背景未覆盖顶部安全区，回收瞬间暴露系统背景形成白条。  
4. 锚点不稳定：`confirmationDialog` 挂在即将销毁的 pill 子树上，增加切换抖动概率。

## 5. 分步骤执行（严格按序）

> 规则：一步一提交；每步只改允许文件；不可跨步夹带。  
> 交付格式：`变更文件` + `验收结果` + `残余风险`。

### Step 1（状态机先行）- 把确认弹层提升到稳定父层

- 目标：解除“弹层锚点跟随销毁视图”的耦合。  
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
- 必做事项：
1. 把 `isEndNavigationDialogPresented` 从 `NavigationPillView` 提升到 `MapTabRootView`。  
2. `NavigationPillView` 仅发出 `onEndTap` 事件，不承载 `.confirmationDialog`。  
3. `.confirmationDialog` 挂在稳定容器（`mapCanvas` 或更上层）上。  
- DoD：
1. 确认弹层可正常出现/取消/确认。  
2. `NavigationPillView` 移除局部弹层状态与确认逻辑。

### Step 2（交互平滑）- 拆分确认关闭与导航态销毁事务

- 目标：消除确认后“慢半拍”体感。  
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
- 必做事项：
1. 确认按钮先关闭弹层，再触发导航结束状态写回（可 `DispatchQueue.main.async` 下一帧执行）。  
2. `state.endNavigation()` 改用更短 `easeOut` 或无动画事务，避免 spring 拖尾。  
3. 确保 route 相关状态仍正确重置（`navigationPoint/activeRoute/routeStatus`）。  
- DoD：
1. 确认后顶部导航容器消失明显更顺滑，无“卡顿停顿”。  
2. 退出后无状态残留。

### Step 3（视觉兜底）- 消除顶部白条闪现

- 目标：保证安全区回收过程视觉连续。  
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
- 必做事项：
1. 地图背景覆盖顶部安全区（例如 `.ignoresSafeArea(edges: .top)` 或等价方案）。  
2. 校验 `safeAreaInset(.top)` 收起时，不露系统白底。  
3. 保持现有按钮可点击区域与避让逻辑不回退。  
- DoD：
1. 结束导航过程不再出现顶部白条闪现。  
2. `map_locate_me` 与其他顶部控件布局正常。

### Step 4（回归加固）- 自动化与文档收口

- 目标：把问题固化为可回归断言，便于后续会话直接验证。  
- 允许改动文件：
1. `YOMUITests/YOMUITests.swift`
2. `docs/app-routine.md`
- 必做事项：
1. 新增“结束导航确认后快速退出”的时序断言（避免明显拖尾）。  
2. 新增“结束导航后顶部无异常残留容器”的断言。  
3. 在 `app-routine` 更新结束导航入口与层级说明。  
- DoD：
1. 新增/更新测试本地稳定通过。  
2. 文档描述与实现一致。

## 6. 每步统一验收模板

1. 功能：是否满足本步目标交互。  
2. 视觉：是否消除卡顿/白条/跳变。  
3. 一致性：确认流程与状态机是否解耦清晰。  
4. 回归：是否新增/更新至少 1 条自动化断言。

## 7. 非目标（本轮不做）

1. 不改路线规划算法与 ETA 计算。  
2. 不重做地图视觉主题。  
3. 不扩展 Archive/Settings 业务流程。

## 8. 可复制执行指令（给后续窗口）

### 窗口 A 指令（Step 1）
“按 `结束导航卡顿与顶部白条闪现整改spec.md` 的 Step 1 执行，先把 confirmationDialog 从 NavigationPillView 提升到父层，只改允许文件，回传状态机变化与风险。”

### 窗口 B 指令（Step 2）
“按 Step 2 执行，拆分‘确认关闭’与‘导航结束’事务，降低结束动画拖尾，只改允许文件，回传交互前后对比。”

### 窗口 C 指令（Step 3）
“按 Step 3 执行，处理顶部安全区覆盖，消除白条闪现，只改允许文件，回传截图对比与兼容性说明。”

### 窗口 D 指令（Step 4）
“按 Step 4 执行，补齐 UI 回归用例并对齐 app-routine 文档，回传测试清单与结果。”

## 9. 资料清单（审计留痕）

1. Apple Maps 用户支持（结束路线入口）：  
https://support.apple.com/en-az/guide/iphone/iph837d13d03/ios
2. Google Maps 用户支持（停止导航）：  
https://support.google.com/maps/answer/3273406?co=GENIE.Platform%3DiOS&hl=en-SG
3. Waze 用户支持（停止路线）：  
https://support.google.com/waze/answer/6286774
4. SwiftUI `safeAreaInset`：  
https://developer.apple.com/documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:)
5. SwiftUI `ignoresSafeArea`：  
https://developer.apple.com/documentation/swiftui/view/ignoressafearea(_:edges:)
