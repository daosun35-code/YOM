# 003 Foreground Passive Reminder UX 收口 Spec

> 文档日期：2026-04-01（America/New_York）  
> 目标：把“附近记忆提醒”从当前的多条前台系统打断，收口为“后台召回 + 前台页内提示”的一致体验。  
> 适用范围：`Features/Memory/PassiveExperienceCoordinator.swift`、`Features/Memory/NotificationOrchestrator.swift`、`Features/Map/MapTabRootView.swift`、`Features/Map/MapPreviewViews.swift`、`Shared/Localization/AppStrings+Settings.swift`、`Shared/Localization/AppStrings+Map.swift`、`YOMUITests/*`、`docs/app-routine.md`。  
> 约束：本 spec 只覆盖提醒呈现策略与用户心智，不改 Active 解锁判定、不改 `MemoryDetailView` 体验链路、不重做地图信息架构。所有新增或调整的 UI 必须通过 SwiftUI API 落地，不以 UIKit 包装、混合宿主或其他旁路视图方案替代。

## 1. 问题定义（当前实现为何不对）

### P0-001 前台仍被 Passive 系统提醒打断
- 现象：App 已打开且用户正在地图页时，只要 Passive 开关已开启，附近 geofence enter 仍会触发系统 banner / sound。
- 当前实现锚点：
1. `PassiveExperienceCoordinator.userNotificationCenter(_:willPresent:...)` 直接返回 `[.banner, .list, .sound]`。
2. `MapTabRootView` 在前台位置变化时仍持续调用 `refreshPassiveMonitoringIfNeeded()`。
- 风险：用户认为自己已在“主动使用 App”，却再次被系统级提醒打断，心智冲突明显。

### P0-002 高密度点位场景下出现“提醒风暴”
- 现象：在华埠这种点位密集区域，切换到某个模拟位置时，可能连续收到多条不同记忆提醒。
- 当前实现锚点：
1. `GeofenceCandidateSelector` 以最近点集合注册 geofence，半径固定 `200m`。
2. `PassiveExperienceCoordinator.handleGeofenceEvent(_:)` 对每个 `enter` 单独调度一条通知。
3. 通知冷却只按单个 `memoryId` 去重，没有“街区级 / 会话级”聚合。
- 风险：用户无法区分“一个附近入口”与“多条系统警报”，形成 alert fatigue。

### P0-003 “Active / Passive”与“前台 / 后台”语义错位
- 现象：代码中的 `.active` / `.passive` 实际表示探索来源，不等于 App scene；但用户容易把“Passive”理解为“退到后台时才提醒”。
- 风险：设置文案与实际行为不一致，降低信任。

### P1-004 刚启用提醒或刚进入监控集合时，缺少“已在圈内”保护
- 现象：当用户本来就站在多个 geofence 范围内时，开启 Passive 或刚刷新监控集合，系统可能立即回放多个 `satisfied` 事件。
- 风险：出现“刚打开开关就被炸一轮”的反直觉体验。

## 2. 设计结论（本 spec 的最终产品决策）

### 2.1 术语与产品语义
1. 对用户隐藏“Passive”术语；用户可见语义统一为“离开 App 后提醒我附近记忆”。
2. `Active` 保留为内部实现概念，仅表示“当前有主动探索目标”。
3. 对用户而言：
- App 打开时：这是“地图内提示”。
- App 不在前台时：这是“系统提醒”。

### 2.2 前台与后台的提醒规则
1. `scene == active` 时，Passive 事件不得再展示系统 banner / sound。
2. `scene == active` 且当前无主动导航时，Passive 事件应转为一个可忽略的 in-app 汇总入口。
3. `scene == active` 且当前处于主动导航 / 解锁流程时，Passive 事件应被静默抑制，不抢当前任务焦点。
4. `scene != active` 时，才允许使用系统本地通知。

### 2.3 呈现粒度
1. 前台：只显示一个汇总入口，不逐条展示多个地点。
2. 后台：同一批附近事件只发一条摘要通知，不逐条发多条地点通知。
3. 同一记忆仍保留 24h 冷却；除此之外还要增加“街区级 / 会话级”冷却，避免同区域短时间重复打扰。

### 2.4 首次启用保护
1. 用户刚开启提醒时，若设备已经位于若干 geofence 内，默认不立即通知。
2. 至少满足“离开后再次进入”或“首次启用后经过最小稳定窗口”之一，才允许该批点位触发提醒。

## 3. 目标体验矩阵

| 场景 | 用户上下文 | 允许的呈现 | 禁止的呈现 |
| --- | --- | --- | --- |
| App 在前台，地图空闲态 | 用户浏览地图但未导航 | 一个页内汇总卡片/胶囊，显示“附近有 N 条记忆” | 系统 banner、声音、连续多条 alert |
| App 在前台，主动导航中 | 用户正去某个目标点 | 不打断当前链路；可静默缓存附近事件 | 系统 banner、强制弹卡、切走当前目标 |
| App 在后台或未打开 | 用户未使用 App | 一条摘要本地通知 | 多条逐点通知 |
| 用户点通知回到 App | 用户准备探索 | 进入地图页并打开“附近记忆入口”或聚合列表 | 直接跳详情页、直接多层弹窗 |
| 用户刚开启“附近记忆提醒” | 仍站在地理围栏内 | 零即时通知 | 刚开开关即连发多条提醒 |

## 4. 推荐交互形态

### 4.1 前台页内提示
1. 位置：地图页底部浮卡，锚定在 Tab Bar 上方；不要占用顶部，因为顶部已有搜索、跟随、导航胶囊。
2. 文案：
- 标题：`附近有 3 条记忆`
- 副文案：`先看 中华公所，也可浏览其余 2 条`
3. 操作：
- 主操作：`查看`
- 次操作：`稍后`
4. 行为：
- `查看` 打开一个轻量 nearby 列表或聚合卡，不直接跳详情。
- `稍后` 只关闭当前页内提示，并启动短时街区级冷却。

### 4.2 后台系统通知
1. 标题：`附近有 3 条可探索记忆`
2. 正文：优先显示最高优先级地点名，例如 `中华公所在附近，也有另外 2 条记忆可查看。`
3. 一次事件窗内仅允许一条通知。
4. 点通知后进入 Map，并展示聚合 nearby 入口，而不是直接打开任意单条详情页。

### 4.3 设置页文案
1. 标题建议：`离开 App 后提醒我附近记忆`
2. 说明建议：`当你不在 App 内时，我们会在附近有可探索记忆时提醒你。App 打开时改为页内提示，不会连发系统通知。`
3. 禁止继续使用会让用户误解为“App 打开时也会弹系统通知”的模糊文案。

## 5. 设计依据（外部规范，2026-04-01 核对）

1. Apple Human Interface Guidelines, Alerts  
https://developer.apple.com/design/human-interface-guidelines/alerts
2. Apple Human Interface Guidelines, Managing Notifications  
https://developer.apple.com/design/human-interface-guidelines/managing-notifications
3. Apple Developer Documentation, Asking Permission to Use Notifications  
https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications
4. Apple Developer Documentation, Requesting Authorization to Use Location Services  
https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services
5. Apple Developer Documentation, NSLocationAlwaysAndWhenInUseUsageDescription  
https://developer.apple.com/documentation/bundleresources/information-property-list/nslocationalwaysandwheninuseusagedescription
6. Material Design, Notifications  
https://m1.material.io/patterns/notifications.html

> 本 spec 的产品判断：对“附近可探索内容”这类低紧急度信息，前台优先页内提示，后台才用系统通知；且需要聚合，避免 alert fatigue。

## 6. 范围与非目标

### In Scope
1. 前台是否展示系统通知。
2. 前台 nearby 提示的交互形式与文案。
3. 后台通知从“逐条”改为“聚合摘要”。
4. “刚启用就爆发多条提醒”的保护策略。
5. 相关 UI / 单测 / 文档对齐。

### Out Of Scope
1. 重新设计 `MemoryDetailView`。
2. 调整 Active 解锁半径或 dwell 规则。
3. 全量重做地图页布局。
4. 引入远端推送、后端策略或 APNs。

## 7. 七步执行协议（小颗粒度，供后续会话逐步执行）

> 规则：每次会话只执行一步；一步一提交；不得跨步改文件。  
> 交接格式：`本步目标 / 变更文件 / 验收结果 / 未决风险`。  
> 优先级：先完成 P0-1 ~ P0-4，再考虑 P1-5 ~ P1-7。

### Step 1（P0）- 术语与设置文案收口
- 目标：把用户可见语义改成“离开 App 后提醒我附近记忆”，不再让用户以为前台也该弹系统提醒。
- 允许改动文件：
1. `Shared/Localization/AppStrings+Settings.swift`
2. `Shared/Localization/AppStrings+Map.swift`
3. `docs/app-routine.md`
4. `specs/003-foreground-passive-reminder-ux/spec.md`
- 必做事项：
1. 更新设置标题、说明、失败/权限引导文案。
2. 在文档中明确“前台页内提示、后台系统提醒”的产品规则。
3. 不改运行时逻辑。
- DoD：
1. 所有用户可见主路径文案不再直接暴露“Passive”。
2. 文档与本 spec 一致。

### Step 2（P0）- 前台系统提醒抑制
- 目标：App 在前台时，不再展示 Passive 的系统 banner / sound。
- 允许改动文件：
1. `Features/Memory/PassiveExperienceCoordinator.swift`
2. `App/AppRootView.swift`（仅当需要 scene 状态桥接）
3. `YOMUITests/PassiveExperienceCoordinatorTests.swift`（可新增）
4. `YOMUITests/YOMUITests.swift`
- 必做事项：
1. 在前台 `willPresent` 分支中压制系统提醒。
2. 保留后台通知能力。
3. 为前台抑制增加自动化断言。
- DoD：
1. `scene == active` 时不再出现系统 banner。
2. 后台通知路径未回退。

### Step 3（P0）- 前台 nearby 事件聚合模型
- 目标：为前台页内提示建立一个“聚合入口”数据模型，而不是逐条弹出。
- 允许改动文件：
1. `Features/Memory/PassiveExperienceCoordinator.swift`
2. `Shared/Models/` 下新建轻量聚合 model（如需）
3. `YOMUITests/PassiveExperienceCoordinatorTests.swift`（可新增）
- 必做事项：
1. 把多个附近 enter 事件聚合为一个前台 summary 状态。
2. 提供最小字段：`count`、`topMemoryId`、`memoryIDs`、`occurredAt`。
3. 在主动导航进行中，允许静默缓存或直接丢弃，但不得打断当前链路。
- DoD：
1. 同一批附近事件只生成一个前台 summary。
2. 地图 UI 可只消费 summary，不必自己做去重。

### Step 4（P0）- 地图页页内汇总入口
- 目标：把前台 nearby 事件落为一个非模态入口，替代系统提醒。
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
2. `Features/Map/MapPreviewViews.swift`
3. `Shared/Localization/AppStrings+Map.swift`
4. `YOMUITests/YOMUITests.swift`
5. `YOMUITests/AccessibilityTests.swift`
- 必做事项：
1. 在地图页加入一个底部浮卡或等价的非模态 nearby summary 入口。
2. 主操作为 `查看`，次操作为 `稍后`。
3. 与搜索、导航胶囊、预览 Sheet 不发生遮挡冲突。
4. 所有本步涉及的 UI 必须直接调用 SwiftUI API 落地；不得以 UIKit bridge、overlay 宿主 hack 或其他非 SwiftUI 视图方案规避。
- DoD：
1. 前台 nearby 事件可见但不打断。
2. 汇总入口具备 `accessibilityIdentifier` 与 label。
3. 默认不覆盖当前导航胶囊与顶部控件。

### Step 5（P1）- 后台通知聚合为单条摘要
- 目标：后台附近提醒从“逐地点一条”收口为“同一批次一条摘要通知”。
- 允许改动文件：
1. `Features/Memory/NotificationOrchestrator.swift`
2. `Features/Memory/PassiveExperienceCoordinator.swift`
3. `YOMUITests/NotificationOrchestratorTests.swift`
4. `YOMUITests/YOMUITests.swift`
- 必做事项：
1. 为摘要通知定义 payload 与 identifier 规则。
2. 通知标题/正文以聚合 count + top priority memory 为主。
3. 点通知回到 Map 时打开聚合入口，而非直接进某一条详情。
- DoD：
1. 同一批 nearby 事件最多只产生一条系统通知。
2. 通知点击回跳路径稳定。

### Step 6（P1）- 首次启用与“已在圈内”保护
- 目标：避免用户刚开启提醒或刚刷新监控集合时被即时炸一轮。
- 允许改动文件：
1. `Features/Memory/GeofenceMonitor.swift`
2. `Features/Memory/PassiveExperienceCoordinator.swift`
3. `YOMUITests/GeofenceMonitorTests.swift`
4. `YOMUITests/PassiveExperienceCoordinatorTests.swift`（可新增）
- 必做事项：
1. 对“首次启用时已在 geofence 内”的 enter 事件增加过滤策略。
2. 明确采用哪种保护：`首次启用后稳定窗口` 或 `必须 exit -> re-enter`。
3. 在 spec 与测试中写死选择，不允许实现与文档分叉。
- DoD：
1. 开启提醒后，若用户原本已在多个圈内，不会立刻收到一轮提醒。
2. 正常重新进入区域时仍能触发提醒。

### Step 7（P1）- 文档、测试、回归收口
- 目标：把新语义与回归矩阵固化，便于后续窗口复用。
- 允许改动文件：
1. `docs/app-routine.md`
2. `specs/002-community-memory-backend/后端实装spec.md`（仅补充执行记录或引用）
3. `specs/003-foreground-passive-reminder-ux/spec.md`
4. 相关测试文件
- 必做事项：
1. 更新业务链路描述：前台页内提示、后台摘要通知。
2. 在本 spec 追加执行记录。
3. 为前台抑制、页内 nearby 入口、后台聚合、首次启用保护补齐测试锚点。
- DoD：
1. 文档、实现、测试无冲突。
2. 新窗口只读本 spec 即可继续工作。

## 8. 统一验收模板

1. 功能：本步目标行为已出现，且没有回退旧的多条前台系统提醒。
2. 体验：前台 nearby 信息“可见但不打断”，后台 nearby 信息“可达但不轰炸”。
3. 可访问性：新增入口具备 `accessibilityLabel`、`accessibilityIdentifier`、44x44 点击区。
4. 回归：至少 1 条自动化断言覆盖本步主路径。
5. 变更控制：只改本步允许文件，不夹带其他任务。

## 9. 给后续会话可直接复制的执行指令

### 会话 A 指令
“按 `specs/003-foreground-passive-reminder-ux/spec.md` 的 Step 1 执行，只改允许文件，完成后回传：文案变更、受影响页面、风险。”

### 会话 B 指令
“按 `specs/003-foreground-passive-reminder-ux/spec.md` 的 Step 2 执行，只改允许文件，完成后回传：前台抑制逻辑、测试结果、回退风险。”

### 会话 C 指令
“按 `specs/003-foreground-passive-reminder-ux/spec.md` 的 Step 3 执行，只改允许文件，完成后回传：前台 summary model 设计、字段、测试结果。”

### 会话 D 指令
“按 `specs/003-foreground-passive-reminder-ux/spec.md` 的 Step 4 执行，只改允许文件，完成后回传：地图页入口截图/描述、a11y 标识、测试结果。”

### 会话 E 指令
“按 `specs/003-foreground-passive-reminder-ux/spec.md` 的 Step 5 执行，只改允许文件，完成后回传：后台摘要通知 payload、点击回跳、测试结果。”

### 会话 F 指令
“按 `specs/003-foreground-passive-reminder-ux/spec.md` 的 Step 6 执行，只改允许文件，完成后回传：首次启用保护策略、边界条件、测试结果。”

### 会话 G 指令
“按 `specs/003-foreground-passive-reminder-ux/spec.md` 的 Step 7 执行，只改允许文件，完成后回传：文档对齐清单、测试矩阵、最终风险。”

## 10. 执行记录

- 2026-04-01：总控 spec 建立，待后续按七步小颗粒度执行。
