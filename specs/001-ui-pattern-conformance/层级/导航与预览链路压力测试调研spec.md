# 001 导航与预览链路压力测试调研 Spec（反 Vibe Coding 污染）

> 目的：在“不先读业务代码”的前提下，基于 Apple 官方一手资料建立一份可执行规范，系统清除 vibe coding 常见的上下文污染错误与隐患。  
> 文档日期：2026-03-05（America/New_York）  
> 适用范围：SwiftUI 导航、Sheet 预览、交互动画、UI 自动化与回归门禁。  
> 方法约束：仅使用官方资料（Apple 文档 / WWDC / Swift 官方），并做交叉论证。

## 0. 检索标签（建议原样复用）

`swiftui navigationstack path` `navigationdestination lazy container` `sheet detents background interaction` `modal vs push` `single source of truth` `observation macro` `swiftui concurrency main actor` `swiftui instrument update groups` `xcode test repetitions` `ui automation accessibility identifier`

## 1. 调研方法与证据等级

### 1.1 证据来源分层

1. A 级：Apple 官方文档 API 条目（SwiftUI/XCTest/MetricKit）。
2. A 级：WWDC 会话文字稿（SwiftUI 团队/Xcode 团队/设计团队）。
3. B 级：Apple 官方教程或示例说明（用于补充，不单独作为强约束）。

### 1.2 结论生成规则

1. 每条“工程规范”至少由 2 条官方证据支撑（API + WWDC 或 WWDC + WWDC）。
2. 所有“推断”必须标注为推断，不冒充官方原句。
3. 以“最短 API 链路 + 最少状态源 + 最低时序耦合”为设计优先级。

## 2. 核心结论（先给结论）

1. 导航必须转为数据驱动：以 `NavigationStack(path:)` 作为容器真源，而非分散在多个 `Bool` 或多条链路里。
2. 预览关闭必须单出口：空白点击、Close、下滑等动作统一汇聚到一个状态出口（single source of truth）。
3. Sheet 与 Push 要语义分离：层级钻取用 push；自包含任务用 modal，不得混用导致行为歧义。
4. `navigationDestination` 不可放入 lazy 容器；这是导航链路随机失效和“有时跳不动”的高发源。
5. 视图 `body` 必须保持轻量与近似纯函数；副作用/重计算/对象重复创建要外移，否则会形成掉帧与状态漂移。
6. 异步任务要遵循 SwiftUI 并发模型：UI 状态同步更新，耗时任务异步执行，避免“先卡顿再收起”。
7. 回归策略必须从“通过一次”升级为“重复+量化”：使用 test repetitions、UI 视频回放、性能仪表三件套。

## 3. 反污染规范（行业级 MUST / MUST NOT）

### NAV-001（MUST）导航状态单一真源

1. 必须使用容器级路径状态（`path` / typed route）作为导航真源。
2. 禁止为每个跳转节点维护独立 `isPresented` 布尔旗标并行驱动。
3. 目标：防止链路分叉、回退不同步、深链恢复失败。

### NAV-002（MUST）值驱动导航，淘汰旧式绑定跳转

1. 必须采用 value-presenting `NavigationLink` + `navigationDestination`。
2. 旧式基于链接绑定的程序化跳转已在 iOS 16 起进入弃用路径。
3. 目标：降低 API 语义混乱和后续迁移成本。

### NAV-003（MUST NOT）`navigationDestination` 放在 lazy 容器内

1. 禁止将 destination 声明放在 `LazyVStack/LazyHStack/List` 等懒容器错误层级里。
2. 目标：消除“偶现 destination 不可见”的链路不稳定。

### NAV-004（MUST）Sheet 内导航优先 `NavigationStack`

1. 在 iPhone/iPad Sheet 场景，导航容器优先 `NavigationStack`。
2. 目标：统一导航语义，避免 `NavigationView` 历史行为差异引发不确定性。

### SHEET-001（MUST）Sheet 关闭语义单出口

1. 空白点击 / Close / 下滑关闭都必须路由到同一状态写回函数。
2. 禁止多个关闭路径各自改状态（并行写回）。
3. 目标：消除“关闭迟滞、关闭后补弹、双层同显”。

### SHEET-002（MUST）detent 与背景交互显式声明

1. 必须显式声明 `presentationDetents`。
2. 必须显式声明 `presentationBackgroundInteraction` 策略（禁用、启用或 `upThrough`）。
3. 目标：避免系统默认行为与产品预期不一致。

### MODAL-001（MUST）Push 与 Modal 按任务类型分工

1. 层级钻取与频繁往返使用 push。
2. 自包含任务（输入/确认/完成）使用 modal。
3. 禁止把“本应 push 的层级浏览”塞进 modal，或把“本应 modal 的任务流”做成 push。

### STATE-001（MUST）视图层最少状态源

1. 视图内状态仅保留 UI 本地状态（例如编辑草稿、瞬时选择）。
2. 业务状态集中在模型层，避免同一事实被多个状态源重复持有。
3. 目标：防止上下文污染引发的状态漂移与竞态。

### STATE-002（MUST）正确使用 `@State/@Environment/@Bindable`

1. `@State`：视图自有状态。
2. `@Environment`：全局/跨层共享。
3. `@Bindable`：仅用于生成绑定。
4. 若三者都不满足，直接普通属性持有模型。

### PERF-001（MUST NOT）在 `body` 放重计算或副作用

1. 禁止在 `body` 中做昂贵计算、对象反复创建、网络/磁盘副作用。
2. 重计算应缓存/预计算；副作用移出 `body` 到事件或任务边界。
3. 目标：防止慢更新、掉帧、卡顿。

### CONC-001（MUST）同步 UI 反馈 + 异步任务解耦

1. 用户动作触发时，先做同步 UI 反馈（例如进入 loading / 关闭确认层）。
2. 耗时逻辑在异步任务中执行，结果再回写 UI 状态。
3. 目标：消除“点了没反应”的迟滞体感。

### TEST-001（MUST）可靠性验证必须做重复测试

1. 必须使用 test repetitions：固定次数、直到失败、失败重试（临时）三模式。
2. 禁止仅凭单次 UI pass 判定“稳定”。
3. 目标：让低概率竞态可复现、可定位、可量化。

## 4. “最短 SwiftUI API 链路”目标架构（代码无关版）

### 4.1 导航主链路

1. 一个路由模型（typed route enum + path）。
2. 一个 `NavigationStack(path:)`。
3. 一个或一组 `navigationDestination(for:)`（非 lazy 容器）。
4. 一个统一回退策略（pop / popToRoot）。

### 4.2 预览 Sheet 主链路

1. 一个 `sheet(item:)` 或 `sheet(isPresented:)` 真源。
2. 一个关闭出口函数（只此一处写回）。
3. 显式 `presentationDetents`。
4. 显式 `presentationBackgroundInteraction`。
5. 需要时用 `@Environment(\.dismiss)` 执行呈现层关闭动作。

### 4.3 安全区与顶部视觉连续性

1. 顶部容器注入（`safeAreaInset`）与底图覆盖（`ignoresSafeArea`）的职责要分离。
2. 拆除顶部容器时，必须保证底图连续覆盖，避免暴露系统底色。
3. 关闭/销毁事务避免与重弹层动画并帧。

## 5. 交互与动画规范（卡顿与闪现治理）

1. 破坏性确认流程：先关闭确认层，再结束业务态，避免同事务并拆。
2. teardown 阶段优先短时 `easeOut` 或最小动画；禁止重弹簧拖尾放大迟滞。
3. 滚动/转场卡顿排查优先级：
- Long View Body Updates。
- 不必要的更新次数。
- 主线程重计算。
- 事件到状态写回的事务堆积。

## 6. 测试与门禁（从“能过”升级到“可证明稳定”）

### 6.1 稳定性门禁

1. 关键链路（导航结束、预览关闭、pin 切换）每条最少 200 次重复。
2. 同进程重复 + 重启 runner 重复都要覆盖。
3. 发布前建议 300 次耐久跑。

### 6.2 时延门禁（建议起始阈值）

1. `End确认 -> 顶部导航消失`：P95 < 500ms，P99 < 800ms。
2. `空白/Close -> 预览Sheet消失`：P95 < 400ms，P99 < 800ms。
3. 任一链路出现 `>=1s` 样本按高优先级缺陷处理。

### 6.3 动画流畅度门禁

1. 开发期：XCTest + `XCTOSSignpostMetric` / `measure` 做定向采样。
2. 线上期：MetricKit 追踪 `MXAnimationMetric`、`MXHangDiagnostic`、`MXAppResponsivenessMetric`。
3. Hitch ratio 参考口径：<5ms/s 良好，5-10ms/s 需排查，>=10ms/s 需立即处理。

### 6.4 自动化稳健性门禁

1. 关键控件必须提供稳定 accessibility identifier。
2. 录制生成的查询必须改为“最短且稳定”的定位表达。
3. 每条关键用例必须包含 `waitForExistence` 或等价等待策略，禁止裸断言。

## 7. 执行协议（不看代码先落规范）

### Step 1：架构对齐评审（无代码）

1. 输出当前链路的状态拓扑图（导航 / Sheet / 异步）。
2. 标记并行状态源、重复关闭入口、非最短 API 链路。
3. 产物：`架构差距清单（规范 -> 现状）`。

### Step 2：状态收敛整改

1. 导航收敛到路径真源。
2. Sheet 关闭收敛到单出口。
3. 异步动作与 UI 反馈解耦。

### Step 3：交互与视觉一致性整改

1. 修复 teardown 动画拖尾。
2. 修复 safe area 回收白条。
3. 修复 modal/push 语义错位。

### Step 4：回归门禁落地

1. 重复测试矩阵跑满。
2. 性能与流畅度指标出具 P50/P95/P99。
3. 形成版本门禁结论：`Pass / Conditional Pass / Fail`。

## 8. 交付物（必须齐全）

1. 本 spec（规范主文档）。
2. 差距清单（现状映射到规范条款）。
3. 压测产物（`.xcresult`、失败截图、视频、日志）。
4. 指标报告（稳定性、时延、hitch、线上观测计划）。
5. 风险闭环清单（未完成项 + owner + 截止日期）。

## 9. 统一验收模板

1. 规范符合度：MUST 条款通过率。
2. 功能稳定性：重复测试失败率、首次失败迭代。
3. 时延：P50/P95/P99/Max。
4. 流畅度：hitch 指标与关键动画观察结果。
5. 可维护性：状态源数量、关闭入口数量、导航 API 链路长度。
6. 结论：`Pass / Conditional Pass / Fail`。

## 10. 官方资料清单（交叉论证留痕）

### 10.1 SwiftUI 导航与层级语义

1. The SwiftUI cookbook for navigation（WWDC22）  
https://developer.apple.com/videos/play/wwdc2022/10054/
2. Explore navigation design for iOS（WWDC22）  
https://developer.apple.com/videos/play/wwdc2022/10001/
3. Adding a search interface to your app（SwiftUI 文档）  
https://developer.apple.com/documentation/SwiftUI/Adding-a-search-interface-to-your-app

### 10.2 SwiftUI 状态与并发

1. Data Essentials in SwiftUI（WWDC20）  
https://developer.apple.com/videos/play/wwdc2020/10040/
2. Discover Observation in SwiftUI（WWDC23）  
https://developer.apple.com/videos/play/wwdc2023/10149/
3. SwiftUI essentials（WWDC24）  
https://developer.apple.com/videos/play/wwdc2024/10150/
4. Explore concurrency in SwiftUI（WWDC25）  
https://developer.apple.com/videos/play/wwdc2025/266/

### 10.3 交互性能与动画流畅度

1. What’s new in SwiftUI（WWDC25）  
https://developer.apple.com/videos/play/wwdc2025/256/
2. Optimize SwiftUI performance with Instruments（WWDC25）  
https://developer.apple.com/videos/play/wwdc2025/306/
3. Eliminate animation hitches with XCTest（WWDC20）  
https://developer.apple.com/videos/play/wwdc2020/10077/

### 10.4 Sheet / Safe Area / Dismiss API

1. PresentationBackgroundInteraction（SwiftUI）  
https://developer.apple.com/documentation/swiftui/presentationbackgroundinteraction
2. presentationDetents(_:)（SwiftUI）  
https://developer.apple.com/documentation/swiftui/view/presentationdetents%28_%3A%29
3. EnvironmentValues（含 `dismiss`）  
https://developer.apple.com/documentation/SwiftUI/EnvironmentValues
4. Layout modifiers（含 `safeAreaInset`、`ignoresSafeArea`）  
https://developer.apple.com/documentation/swiftui/view-layout

### 10.5 测试可靠性与自动化

1. Diagnose unreliable code with test repetitions（WWDC21）  
https://developer.apple.com/videos/play/wwdc2021/10296/
2. Author fast and reliable tests for Xcode Cloud（WWDC22）  
https://developer.apple.com/videos/play/wwdc2022/110361/
3. Record, replay, and review: UI automation with Xcode（WWDC25）  
https://developer.apple.com/videos/play/wwdc2025/344/
4. MXAnimationMetric（MetricKit）  
https://developer.apple.com/documentation/metrickit/mxanimationmetric

## 11. 交叉论证矩阵（关键结论 -> 证据）

| 关键结论 | 官方证据 A | 官方证据 B | 工程推断 |
|---|---|---|---|
| 导航应由容器路径统一驱动 | WWDC22 `The SwiftUI cookbook for navigation`（值驱动 + path） | WWDC24 `SwiftUI essentials`（状态驱动 UI） | 多 `Bool` 并行驱动会放大链路分叉风险 |
| `navigationDestination` 不能放 lazy 容器错误层级 | WWDC22 `The SwiftUI cookbook for navigation`（明确提醒） | SwiftUI 导航文档与运行时警告实践一致 | 懒加载层级易引发 destination 不稳定 |
| Sheet 关闭应单出口 | SwiftUI `presentationDetents` + `presentationBackgroundInteraction` | WWDC22 导航设计（模态任务应语义闭环） | 多关闭入口并行写回会导致迟滞/补弹 |
| Push 与 Modal 需语义分工 | WWDC22 `Explore navigation design for iOS` | WWDC22 `The SwiftUI cookbook for navigation` | 错位使用会增加认知负担和状态复杂度 |
| `body` 应保持轻量、避免副作用 | WWDC20 `Data Essentials in SwiftUI` | WWDC25 `Optimize SwiftUI performance with Instruments` | 重计算/副作用进入渲染路径会增加掉帧 |
| 并发应“同步反馈 + 异步执行” | WWDC25 `Explore concurrency in SwiftUI` | WWDC24 `SwiftUI essentials`（数据驱动更新） | 先做同步反馈可显著降低迟滞体感 |
| 稳定性必须做重复测试 | WWDC21 `Diagnose unreliable code with test repetitions` | WWDC22 `Author fast and reliable tests for Xcode Cloud` | 单次 pass 不能证明无竞态 |
| UI 自动化要稳定选择器 | WWDC25 `Record, replay, and review: UI automation with Xcode` | XCTest 等待机制最佳实践 | 录制原始查询不稳定，需收敛为最短表达 |

## 12. 执行记录

- 2026-03-05：完成“先调研、后映射代码”的行业规范版草案，进入 Step 1（架构差距清单）阶段。
