# 社区记忆库本地化实装规划报告（Phase 0：不连接服务器）

> 创建日期：2026-03-09（America/New_York）
> 最后更新：2026-03-11（America/New_York）
> 当前约束：暂不连接任何后端服务；记忆元数据全部本地化，媒体资源允许占位并逐步补齐到本地 App。
> 目标：先把 Active / Passive 双模式在端内跑通，再进入后端化阶段。

## Changelog

| 版本 | 日期 | 变更内容 |
| --- | --- | --- |
| v0.1 | 2026-03-09 | 初稿：执行结论、业务链路、端内架构、数据模型、状态机、Active/Passive 实现细节、分阶段计划、开工清单 |
| v0.2 | 2026-03-10 | 补充 Section 0.2 可执行性判定 + Section 0.3 可执行标准 8 条 + Section 0.4 证据格式；补充 Section 2.2 接口契约（4 模块协议签名）；补充 Section 8.1 NFR 基线 + Section 8.2 数据保留 + Section 8.3 风险登记册；补充 Section 10.6 DoD 追踪矩阵 + Section 10.7 门禁命令字典；补充 Section 11.2 任务卡 + Section 11.3 依赖关系；补充 Section 15 证据核验表 |
| v0.3 | 2026-03-10 | 修复 `GATE-OWNER-PLACEHOLDER` 检测模式（由 `Owner.*iOS-` 改为 `@TBD`）；任务卡 Owner 格式改为 `角色 @TBD`；统一文档头部日期字段 |
| v0.4 | 2026-03-10 | 修订可执行性收口：任务卡 Owner 全量实名；`GATE-OWNER-PLACEHOLDER` 仅检测任务卡行并修复 PR-1 文案冲突；将 `memory_detail_title` / `Background App Refresh` 门禁从“存在性 grep”升级为“指定 UI 用例执行” |
| v0.5 | 2026-03-10 | 执行性修订：`GATE-CONFIG-PLIST-KEYS` 升级为 Build Settings 生效校验；`GATE-MODULE-0B0C-IMPLEMENTED` 从关键词检索升级为“文件 + 协议 + 测试类”三段校验；`GATE-I18N` 改为与当前 `AppLanguage + memories.json` 体系一致；`DOD-0A-01` 状态由 PASS 调整为 PARTIAL（补齐 Map pin 证据后再转 PASS）；任务依赖 `blockedBy` 改为可机读原子列表 |
| v0.6 | 2026-03-10 | 严格修订：新增统一门禁脚本 `scripts/community_memory_gate.sh`；新增 `GATE-UI-MAP-PIN-TEST` 并落地 `testMapPointPinVisibleAfterOnboarding`；Section 10.7 全量改为 Gate 脚本入口；PR/任务卡/DoD 的自然语言门禁改为 Gate ID；新增 `EVID-UI-MAP-PIN-ASSERT` 实测 PASS 证据 |
| v0.7 | 2026-03-10 | 执行漏洞修复：`GATE-SNAPSHOT-BASELINE-TESTS` 补全 5 条基线（原只跑 1 条）；`GATE-I18N` 改为运行完整 `LocalMemoryDataIntegrityTests` 类（原只跑 1 个方法）；新增 `GATE-PR2-COMPOSITE` 和 `GATE-PR3-COMPOSITE`（Section 10.7 #17/#18）并更新 Section 11.1；`GATE-BG-REFRESH-GUARD-TEST` 补充模拟器 launch env 注入规范（`UITEST_SIMULATE_BG_REFRESH_UNAVAILABLE`，仅 DEBUG 生效） |
| v0.8 | 2026-03-10 | 补齐 6 处缺口：Section 0.1 增 a11y 强制约束（第 6 条）；Section 3 增 schema 版本化策略与 SwiftData 迁移路径（3.1/3.2 小节）；Section 5 增媒体运行时缺失 fallback 规范（5.1 小节）；Section 6.2 增第 7 条后台执行时间预算约束；Section 8.1 增 NFR-TEST-01/02（测试覆盖率）与 NFR-POWER-03（后台执行预算）；Section 10.7 增 `GATE-A11Y`（#19）与 `GATE-INTERFACE-CONTRACT-FROZEN`（#20）；Section 11.2 增 T-PR1-05（a11y 基线测试）；Section 11.3 补接口契约冻结依赖；Section 15.1 补 EVID-A11Y / EVID-INTERFACE-CONTRACT |
| v0.9 | 2026-03-11 | 文档校对：澄清 Section 3.1 的 `schemaVersion` 为预留策略而非当前仓库既成事实；调整 Section 6.2 编号与子项顺序；修复 Section 11.1 PR-1 引号笔误；统一“内容格式不兼容，请更新 App”文案引号 |
| v0.10 | 2026-03-11 | 新增 Section 11.4“AI 分步执行流程（模块化实装）”：定义 AI-00 ~ AI-08 的执行顺序、允许改动边界、模块内推荐拆分、单步交接产物与提示模板；要求先冻结接口、再做单模块实现、最后做集成接线 |
| v0.11 | 2026-03-11 | 执行 AI-02：`ExplorationStore` 完成 SwiftData 纯存储闭环与 `ExplorationStoreTests`；`GATE-EXPLORATIONSTORE-TESTS`、`GATE-BUILD`、`GATE-MODULE-0B0C-IMPLEMENTED`、`GATE-INTERFACE-CONTRACT-FROZEN` 均转 PASS，并回填 Section 10.6 / 15.1 状态 |
| v0.12 | 2026-03-11 | 将 SwiftLens MCP 研究整合入 Section 11.4：新增“强制使用 SwiftLens”执行铁律、AI-00 ~ AI-08 逐步必跑工具链、交接包 SwiftLens 证据要求与提示模板约束；若 SwiftLens 环境或索引未就绪，开发会话不得继续编码 |

## 0. 执行结论

本阶段采用 **Local-First 架构**：

1. 不调用远端 API，不做 APNs，不依赖云存储。
2. 记忆数据和媒体走本地资源（`Bundle` + 本地持久化）。
3. Active / Passive 双模式的目标是在端上闭环；当前完成度以 Section 2.1 与 Section 11 为准。
4. “已探索档案”和“记忆卡片”先保存为本地状态与本地文件。

## 0.1 强制实现约束

1. 新功能实现必须基于当前项目既有设计风格、组件层级和制作规范，不得另起一套视觉与交互语言。
2. 新功能必须使用 SwiftUI 落地，复用现有 DS 组件层（`DSColor` / `DSSpacing` / `.dsTextStyle` 等）。
3. 禁止绕过 DS 裸写 SwiftUI 或引入 UIKit 替代方案；新增页面/组件必须经由 DS Token 走样式。**例外：系统能力桥接（如分享 `UIActivityViewController`、相册 `PHPhotoLibrary`）可直接使用 UIKit，但须封装在 SwiftUI `UIViewControllerRepresentable` 或独立 helper 内，不得在 View body 中裸调。**
4. 代码评审新增门禁：若新增功能绕过 DS 层裸写样式常量或引入 UIKit 视图，则视为不通过。
5. 所有新增 UI 必须通过 `xcodebuild build` 编译验证及 `xcodebuild test` 回归测试，确保编译通过及架构合规。（注：`xcodebuildmcp` 为本地 MCP 工具，等同于封装后的 `xcodebuild` 命令行调用；若未配置，直接用 `xcodebuild` 命令替代。）
6. 所有新增交互式 UI 元素必须满足无障碍（Accessibility）最低要求：① 可交互元素（按钮、输入框）必须设置 `accessibilityLabel`，不得依赖视觉文本自动推断；② 关键信息载体（标题、状态文本）必须设置 `accessibilityIdentifier`；③ UI 必须在 `UIContentSizeCategory.accessibilityExtraExtraExtraLarge` 下不发生元素截断或重叠。门禁：`GATE-A11Y`（Section 10.7 #19），每个引入新主页面的 PR 必跑。**例外：纯装饰性图片/色块不需要 `accessibilityLabel`，应标记 `accessibilityHidden(true)`。**

## 0.2 当前可执行性判定（2026-03-10 补充）

以当前仓库实测为准：

1. `xcodebuild build`（iOS Simulator）可通过（证据 `EVID-BUILD`）。
2. `LocalMemoryDataIntegrityTests` 可通过（当前位于 `YOMUITests` target，证据 `EVID-TEST-DATA`）。
3. Phase 0A 尚缺 1 条 UI 断言测试：进入 `MemoryDetailView` 后验证 `memory_detail_title`（证据 `EVID-UI-TITLE-ASSERT`）。
4. Phase 0B / 0C 仍暂不可端到端执行：`ExplorationStore` 已完成纯存储闭环（证据 `EVID-EXPLORATIONSTORE`），但 `CardRenderer` / `GeofenceMonitor` / `NotificationOrchestrator` 仍待实现，且 Active / Passive 集成尚未接线（证据 `EVID-MODULE-0B0C`）。
5. Passive 与相册链路仍有配置缺口：`NSLocationAlwaysAndWhenInUseUsageDescription` 与 `NSPhotoLibraryAddUsageDescription` 需补齐（证据 `EVID-CONFIG-KEYS`）。
6. Passive 运行时前置条件 `Background App Refresh` 降级保护测试尚未落地（证据 `EVID-BGREFRESH-GUARD`）。

## 0.3 本报告的“可执行标准”定义

本报告要达到“可执行”必须同时满足以下 8 条（缺一不可）：

1. 每个未完成事项必须具备 `任务ID`、允许改动文件、禁止改动边界、门禁命令、回滚判据。
2. 每条 DoD 必须可追踪到至少 1 个自动化测试或可重复命令（Section 10.6）。
3. 配置前置条件必须可机器核查（如 `INFOPLIST_KEY_*`、target 存在性、测试用例存在性）。
4. 状态声明必须附“核验时间 + 命令 + 结果”，不得仅文字描述“可通过”。
5. 跨文档规范只保留一个真源，其他文档只做引用，不复制整段规范文本。
6. 外部平台约束（Core Location / 通知 / 相册权限）出现冲突时，以 Apple 官方文档与 WWDC 会话为准。
7. 每张任务卡必须包含 `Owner`、`优先级`、`计划开始`、`计划截止`（使用绝对日期）；`Owner` 必须为实名账号，不得使用占位符。
8. 必须定义本阶段 NFR 基线（性能/功耗/隐私与数据保留）及其验证方式。

## 0.4 状态证据格式（执行强制）

为满足 Section 0.3 第 4 条，所有“已完成 / PASS / 可通过”声明必须带证据引用：

1. 证据格式：`[EVID-xxxx]`，并在 Section 15.1 提供完整信息（核验时间、命令、结果、说明）。
2. 未绑定 `EVID-*` 的状态声明视为“未核验”，不得作为排期与验收依据。
3. 若代码或配置发生变更，证据需在同一 PR 内重跑并更新 Section 15.1。

## 1. 业务链路（本地闭环版）

### 1.1 Active 模式

1. 用户点击地图 `pin`，进入导航态。
2. App 在端上做“到达范围判定”（距离 <= `unlockRadius`，可加停留秒数）。
3. 达标后解锁记忆详情，按本地媒体类型渲染：`image` / `audio` / `video` / `ar(usdz)`。
4. 用户点“体验完成”后写入本地档案为 `已探索`。
5. 端上生成分享卡片图片，支持保存相册和系统分享。

### 1.2 Passive 模式

1. 首次启用“附近记忆提醒”时请求通知权限与定位权限。
2. 用本地记忆点计算“最近监控点集合”，注册设备端地理围栏。
3. 用户靠近时由本地通知触发文案，点击后进入对应记忆点的 `NAVIGATING`（`source = passive`），再复用 Active 链路完成解锁。

## 2. 端内架构设计

```text
[iOS App]
  -> LocalMemoryRepository (本地记忆数据 + 媒体索引，代码已实现[EVID-CODE-LMR]；依赖 memories.json 解码校验通过[EVID-TEST-DATA])
  -> UnlockEvaluator (距离判定 + dwell 计时，已实现[EVID-CODE-UE])
  -> GeofenceMonitor (CLMonitor geofence 轮换，待实现)
  -> ExplorationStore (已探索记录，纯存储闭环已实现[EVID-EXPLORATIONSTORE]；UI 接线待 AI-04)
  -> CardRenderer (端上卡片渲染，待实现)
  -> NotificationOrchestrator (本地通知编排，待实现)
```

### 2.1 模块职责

1. `LocalMemoryRepository`：加载本地记忆数据（Bundle JSON）；`MemoryPoint.media` 数组即媒体索引，无需独立 `LocalMediaCatalog`。**代码已实现**（`Features/Memory/LocalMemoryRepository.swift`，证据 `EVID-CODE-LMR`），并要求 `Resources/memories.json` 通过 UUID/解码校验（见 Section 10.1，证据 `EVID-TEST-DATA`）。
2. `UnlockEvaluator`：进入范围判定（`distance <= unlockRadius`）+ 容错累计 dwell 计时。**已实现（当前为采样驱动版本）**（`Features/Memory/UnlockEvaluator.swift`，证据 `EVID-CODE-UE`）。
3. `GeofenceMonitor`：最近点计算（Top-N）、`CLMonitor` 条件注册与轮换。**待实现**。
4. `ExplorationStore`：记录探索状态、完成时间、来源（active/passive）。**已实现纯存储闭环**（`Features/Memory/ExplorationStore.swift` + `YOMUITests/ExplorationStoreTests.swift`，证据 `EVID-EXPLORATIONSTORE`）；Active 链路接线留待 AI-04。
5. `CardRenderer`：把记忆内容渲染为图片（卡片模板）。**待实现**。
6. `NotificationOrchestrator`：注册本地提醒、去重与冷却。**待实现**。

### 2.2 Phase 0B/0C 模块接口契约（执行前冻结）

> 目的：为 PR-2 / PR-3 并行开发提供稳定边界。以下为 Phase 0 最小契约；若需改签名，必须在同一 PR 同步更新本节、测试与调用方。

1. `ExplorationStore`（建议文件：`Features/Memory/ExplorationStore.swift`）

```swift
protocol ExplorationStoreProtocol {
    func upsertArchive(memoryPointId: UUID,
                       source: ExplorationSource,
                       exploredAt: Date,
                       cardLocalPath: String?) throws -> ExplorationRecord
    func fetchAllRecords() throws -> [ExplorationRecord]
    func fetchRecord(memoryPointId: UUID) throws -> ExplorationRecord?
    func isArchived(memoryPointId: UUID) throws -> Bool
}
```

- 输入约束：`memoryPointId` 必须对应有效 `MemoryPoint`。
- 输出约束：`upsertArchive` 必须幂等；同一 `memoryPointId` 重复调用不新增重复记录。
- 错误语义：持久化失败统一抛 `storageUnavailable` / `encodingFailed` 等可归类错误。

2. `CardRenderer`（建议文件：`Features/Memory/CardRenderer.swift`）

```swift
protocol CardRendererProtocol {
    func render(memory: MemoryPoint,
                exploredAt: Date,
                coverAssetName: String?,
                outputScale: CGFloat) throws -> URL
}
```

- 输入约束：`memory` 必须含可显示标题与摘要；`outputScale` 仅允许 `1...3`。
- 输出约束：返回沙盒内图片 URL（PNG），文件存在且可读。
- 错误语义：素材缺失/渲染失败需可区分（如 `assetMissing` vs `renderFailed`）。

3. `GeofenceMonitor`（建议文件：`Features/Memory/GeofenceMonitor.swift`）

```swift
protocol GeofenceMonitorProtocol {
    func refreshMonitors(currentLocation: CLLocationCoordinate2D,
                         candidates: [MemoryPoint],
                         maxConditions: Int,
                         now: Date) async throws -> [UUID]
    func startEventStream() -> AsyncStream<GeofenceEvent>
    func stop()
}
```

- 输入约束：`maxConditions` 默认 20，且不得超过治理阈值。
- 输出约束：`refreshMonitors` 返回本次生效监控集合（`memoryId` 列表）。
- 错误语义：权限不足、条件超限、系统 API 失败需分型可观测。

4. `NotificationOrchestrator`（建议文件：`Features/Memory/NotificationOrchestrator.swift`）

```swift
protocol NotificationOrchestratorProtocol {
    func scheduleNearbyReminder(memoryId: UUID,
                                title: String,
                                body: String,
                                now: Date,
                                cooldownHours: Int) async throws -> NotificationScheduleResult
    func extractMemoryId(from userInfo: [AnyHashable: Any]) -> UUID?
}
```

- 输入约束：`cooldownHours` 默认 24，最小值 1。
- 输出约束：`NotificationScheduleResult` 至少区分 `scheduled` / `skippedCooldown` / `skippedArchived`。
- 错误语义：通知权限未授权与调度失败必须可区分。

## 3. 本地数据模型（建议）

> 设计原则：现有 `Shared/Models/PointOfInterest.swift` 已包含 `id`, `year`, `coordinate`, 多语言 `name`/`summary`，是地图 pin 的真源。新模型必须与之统一，避免同一地点记忆出现两份不关联的 model。

**方案：`MemoryPoint` 组合持有 `PointOfInterest`（已实现，证据 `EVID-CODE-MEMORYPOINT`）**

> ⚠️ `MemoryPoint` 不是继承/扩展 `PointOfInterest`，而是**组合**模式：内含 `poi: PointOfInterest` 字段，title/summary/coordinate 等均通过 `poi` 代理访问。

1. `MemoryPoint`（`Shared/Models/MemoryPoint.swift`，已实现，证据 `EVID-CODE-MEMORYPOINT`）
`poi: PointOfInterest, storyByLanguage: [AppLanguage: String], unlockRadiusM: Double, tags: [String], media: [MemoryMedia]`
2. `MemoryMedia`
`id, memoryPointId, type(image/audio/video/ar), localAssetName, duration, thumbnailAssetName`
3. `ExplorationRecord`
`id, memoryPointId, exploredAt, source(active/passive), cardLocalPath`
4. `WatchRegion`
`memoryPointId, center, radiusM, enabledAt, cooldownUntil`

> 建议：`MemoryPoint` 与 `MemoryMedia` 放只读本地包（Bundle JSON）；`ExplorationRecord` 与 `WatchRegion` 放可写本地存储（SwiftData 优先，iOS 17+ 原生支持，备选 CoreData）。

### 3.1 本地 JSON Schema 版本化策略（预留，当前仓库未启用）

1. **当前仓库状态**：`memories.json` 根对象仍仅包含 `memoryPoints`；`LocalMemoryRepository` 也尚未读取 `schemaVersion`。因此，版本化加载在本阶段属于**预留策略**，不得据此宣称仓库已实现 schema 版本校验。
2. **启用时的目标约束**：根对象新增顶层字段 `"schemaVersion": <Int>`，初始值为 `1`；`LocalMemoryRepository` 需同步读取该字段。若值高于 App 已知最高版本，应以 `.schemaVersionUnsupported` 错误失败，并在 UI 显示“内容格式不兼容，请更新 App”引导，不得静默跳过。
3. 向前兼容：Swift `Codable` 默认忽略未知字段，满足同版本内新增可选字段的安全追加（无需改版本号）。破坏性变更（删除字段、改字段类型、改必填语义）须将 `schemaVersion` 自增，并同步更新 `LocalMemoryDataIntegrityTests` 校验逻辑。
4. 该策略正式落地时，需在同一 PR 同步更新 `specs/002-community-memory-backend/记忆写入指南.md`（单一真源）；本节仅描述加载策略，不复制字段表。

### 3.2 SwiftData 数据模型迁移路径（Phase 0 约束）

1. Phase 0 `ExplorationRecord` / `WatchRegion` 使用 `ModelSchemaV1`（在 `ExplorationStore.swift` 内定义 `VersionedSchema` 枚举）。
2. **Phase 0 内如需变更模型**（新增字段、改字段类型）：必须定义 `ModelSchemaV2` 与 `SchemaMigrationPlan`（lightweight migration 优先），并在同一 PR 内补充迁移集成测试（写入 V1 数据 → 迁移 → 读取 V2 数据，断言字段正确）。不得在无迁移计划的情况下直接改 V1 model。
3. **迁移失败降级策略**：Phase 0 允许"删除并重建 store"作为最终保底；但必须先向用户展示"探索记录将被清除"确认弹窗，不得静默清除数据。
4. 已知风险 RISK-03（SwiftData iOS 17.0–17.1 并发 bug）适用于本节；主线程单写策略（`@MainActor ModelContext`）为必选缓解，不得绕过。

## 4. 状态机与判定规则

### 4.1 状态转换图

```
IDLE --(tap pin)--> NAVIGATING --(in range)--> IN_RANGE --(dwell ok)--> UNLOCKED --(完成)--> ARCHIVED
  ^                    |  ^                      |                        |
  |                    |  |                      |                        |
  +---(cancel/fail)----+  +---(exit range)-------+                        |
  +---------------------------------------------------(exit without finish)---+
```

> 说明：`EXPERIENCED` 原设计为"完成体验但尚未写档"的中间态，但该转换为纯自动（无用户操作），不具备独立 UI/业务语义，已合并入 `ARCHIVED`。用户点击"体验完成"即同步写入 `ExplorationRecord`。

### 4.2 状态转换清单

| 转换 | 触发条件 | 副作用 |
| --- | --- | --- |
| `IDLE -> NAVIGATING` | 用户点击 pin 并确认导航 / 点击 Passive 通知 | 创建 `NavigationSession` |
| `NAVIGATING -> IN_RANGE` | `distance <= unlockRadius` | 启动 dwell 计时器 |
| `IN_RANGE -> UNLOCKED` | `dwellAccumulatedSeconds >= 10` | 解锁详情页 |
| `UNLOCKED -> ARCHIVED` | 用户点击"体验完成" | 同步写入 `ExplorationRecord` |
| `NAVIGATING -> IDLE` | 用户取消导航 / 定位失败 | 销毁 `NavigationSession` |
| `IN_RANGE -> NAVIGATING` | 用户离开 `unlockRadius` | 重置 dwell 计时器 |
| `UNLOCKED -> IDLE` | 用户退出详情但未点击"体验完成" | 不写入 `ExplorationRecord` |
| 任意 -> `ERROR` | 定位服务不可用 / 权限被撤销 | 弹出恢复引导 |

### 4.3 判定规则

1. `ARCHIVED` 幂等，同一记忆重复完成不重复建档。
2. 解锁判定采用"双条件"：`distance <= unlockRadius` + `dwellAccumulatedSeconds >= 10`。
3. **dwell 采用连续停留计时（含抖动容忍）**：记录进入范围的时间戳，持续累加在范围内的停留时长；短暂跳出（< `bounceToleranceSeconds`，默认 3s）不重置计时器，视为信号抖动继续累计。当前实现为**采样驱动**：只有在连续 out-of-range 采样持续超过容忍窗口时，才视为真实离开并归零；若在下一次 out-of-range 采样前已回到 in-range，则继续累计。注意：这不是跨多次进出的"全局累计"，而是**单次连续停留计时**（含 3s 容忍窗口）。
4. Passive 触发后，若该记忆已 `ARCHIVED`，默认不再重复通知。

## 5. Active 模式实现细节（无服务端）

1. 点击 pin：创建本地 `NavigationSession`（内存态即可）。
2. 导航期间持续取位置，实时算到目标点距离。
3. 达标触发本地解锁事件，详情页从 `LocalMemoryRepository` 读取。
4. **详情页使用 `Features/Retrieval/MemoryDetailView.swift`**（接收 `MemoryPoint`，已具备媒体渲染框架），在其基础上扩展完整媒体播放能力：
   - `image`：本地图片资源
   - `audio/video`：本地文件 URL + 内嵌播放器
   - `ar`：本地 `usdz` + Quick Look
5. 体验完成后写 `ExplorationRecord`，并触发本地卡片渲染。

### 5.1 媒体运行时缺失处理规范

> 适用于 `MemoryDetailView` 所有媒体类型，在 Bundle 资源未正确打包或 `localAssetName` 与实际文件名不符时触发。

| 媒体类型 | 缺失时 UI 行为 | 错误可观测性 |
| --- | --- | --- |
| `image` | 显示 DS Token 色块占位图（`DSColor.surfaceSubtle`）+ 图标 `photo.slash`，不崩溃 | `Logger` 输出 `[MediaMissing] image asset: <name>`（DEBUG 构建追加文件路径） |
| `audio` | 播放按钮置灰 + 显示"音频暂时不可用"文案（i18n key `media_unavailable_audio`），不崩溃 | 同上，tag `audio` |
| `video` | 播放区域显示 DS 占位帧 + 文案"视频暂时不可用"（i18n key `media_unavailable_video`） | 同上，tag `video` |
| `ar` | Quick Look 按钮置灰 + 文案"AR 内容暂时不可用"（i18n key `media_unavailable_ar`） | 同上，tag `ar` |

**强制约束：**
1. 缺失不得触发 `fatalError` 或未捕获异常；`loadMedia` 入口必须返回 `Result<MediaAsset, MediaLoadError>` 而非 force-unwrap。
2. 三语（en / zhHans / yue）i18n key（`media_unavailable_*`）必须在 Phase 0A 落地时同步添加至 `Localizable` 体系（当前项目 `AppLanguage` 方案）。
3. `LocalMemoryDataIntegrityTests` 中 `localAssetName` 非空校验仅防止**数据写入**时的格式错误，无法防止**打包遗漏**；本节规范处理后者的运行时降级，两者互补。

## 6. Passive 模式实现细节（无服务端）

### 6.1 权限策略

1. 首屏先解释“附近记忆提醒价值”，再触发权限请求。
2. 权限顺序建议：通知权限 -> 定位权限（When In Use）-> Passive 开关开启后再请求 Always（含后台用途文案）。
3. Phase 0C 前必备配置项（`project.yml` / Info.plist，当前状态）：
   - `NSLocationWhenInUseUsageDescription`（已存在，证据 `EVID-CONFIG-WHENINUSE`）
   - `NSLocationAlwaysAndWhenInUseUsageDescription`（Passive 后台围栏所需，**待补齐**）
   - `NSPhotoLibraryAddUsageDescription`（卡片保存相册所需，**待补齐**）
4. 当前工程使用 `GENERATE_INFOPLIST_FILE = YES`（证据 `EVID-GEN-PLIST`），权限键应通过 `project.yml` 的 `INFOPLIST_KEY_*` 注入，不建议手改独立 `Info.plist` 文件。
5. Passive 链路前置运行条件：`Background App Refresh` 必须可用；若为 `.denied` / `.restricted`，必须降级并向用户展示恢复引导（Apple Region Monitoring 文档明确该条件会影响围栏事件回调）。

### 6.2 地理围栏策略（CLMonitor，iOS 17+）

> API 选型：在当前 SDK 中，`CLCircularRegion` 与 `startMonitoringForRegion` 已标注“将废弃（API_TO_BE_DEPRECATED）”，替代建议为 `CLMonitor` + `CLCircularGeographicCondition`。本项目（iOS 17+）统一采用后者；事件通过 `AsyncSequence` 接收。

> ⚠️ **两种半径区分**：`MemoryPoint.unlockRadiusM`（50–100m）是 **Active 模式解锁判定半径**，由 `UnlockEvaluator` 在端内精确计算距离使用。地理围栏半径是 **Passive 模式粗粒度提醒触发半径**（见下方第 4 条，≥ 200m），两者用途不同，`GeofenceMonitor` **不得**直接使用 `unlockRadiusM` 作为围栏半径。

1. 设备同时监控数量按 **N <= 20** 做保守治理（基于 Apple Region Monitoring 历史上限建议）；若未来 CLMonitor 官方文档给出不同上限，以新文档为准。`conditionLimitExceeded` 在 iOS 18+ 可作为兜底信号；iOS 17 需在注册前主动裁剪集合，不能依赖该字段回调。
2. 每次位置显著变化后，重算最近集合并替换监控列表（移除远点、补充近点）。
3. 对同一记忆设置冷却窗口（例如 24h）避免频繁打扰。
4. 测试期阈值按“边界外至少约 200m + 持续约 20s”做验证预算；生产参数可按场景收敛，但不得低于定位噪声容忍阈值。
5. 已知风险：iOS 18 早期版本 exit 事件可能在远处误触发，需加距离二次校验容错。
6. `CLMonitor` 生命周期硬约束（来自 WWDC23）：
   - 同名 monitor 在任意时刻只允许一个实例；
   - App 每次启动都要重建 monitor 并恢复 `events` 异步监听任务；
   - 不建议在 widget/extension 内直接维护 monitor，避免与主 App 竞争实例。
7. **后台执行时间预算约束**：`CLMonitor` geofence enter 事件触发 App 后台执行窗口，iOS 保证约 30s（不得依赖此上限做精确计时）。`NotificationOrchestrator.scheduleNearbyReminder` 的完整执行（包括 `ExplorationStore.isArchived` 查询 + `UNUserNotificationCenter` 调度）必须在 **10s 以内**完成（保守预算，留足余量）。超出预算前未完成调度时，当次通知静默丢弃（不重试），并通过 `Logger` 记录 `[BgBudget] exceeded 10s, notification skipped`。实现时必须使用 `withTimeout`（或等效 timeout helper）配合取消检查显式控制，不得依赖 OS 挂起隐式取消。

### 6.3 通知触发与跳转

1. 进入围栏后下发本地通知（`UNUserNotificationCenter`）。
2. payload 带 `memoryId`，点击后路由到对应记忆导航会话（`NAVIGATING`，`source = passive`），不直接进入详情页。
3. 到达解锁条件（`distance <= unlockRadius` + `dwellAccumulatedSeconds >= 10`）后进入详情页，并复用 Active 的归档逻辑。

## 7. 记忆卡片（本地生成）

1. 输入：标题、摘要、地点名、时间、封面图、本地配色模板。
2. 输出：卡片图片文件（App 沙盒）。
3. 分享：
保存相册（`PHPhotoLibrary`）；
系统分享（`UIActivityViewController`）。

## 8. 本地方案边界（已知限制）

1. 无法做远程运营（推送 AB、服务端实时策略）。
2. 设备丢失会丢本地探索档案（除非后续加 iCloud/后端同步）。
3. 地理围栏数量有限，长尾记忆点需动态轮换而非全量常驻。

### 8.1 非功能需求（NFR）基线（Phase 0）

| NFR-ID | 类别 | 指标目标（Phase 0） | 验证方式 | 不达标处理 |
| --- | --- | --- | --- | --- |
| NFR-PERF-01 | Active 解锁时延 | `distance` 达标到 UI 进入 `UNLOCKED`，`P95 <= 1s` | UI 测试 + 日志时间戳比对（同机型同构建） | 回退到上一个稳定实现，阻断合入 |
| NFR-PERF-02 | 本地持久化时延 | `ExplorationRecord` 单次写入 `P95 <= 150ms` | 单测/集成测试记录耗时（30 样本） | 标记 P1 缺陷并阻断 PR-2 发布 |
| NFR-PERF-03 | 卡片生成时延 | 1080p 卡片输出 `P95 <= 1.5s` | `CardRenderer` 基准测试（20 样本） | 降级模板复杂度并重测 |
| NFR-POWER-01 | Passive 待机功耗 | 真机 24h 待机新增耗电 `<= 8%`（开启 Passive，关闭导航） | Xcode Energy Log + 真机对照记录 | 暂停放量，收敛围栏轮换频率 |
| NFR-POWER-02 | 导航功耗治理 | 高精度定位只允许在 `NAVIGATING` / `IN_RANGE` 期间开启 | 代码审计 + 运行日志断言 | 违规即视为架构缺陷，必须修复 |
| NFR-PRIV-01 | 数据出站约束 | Phase 0 业务链路不得发起远端请求 | 代码审计（网络层调用点）+ 抓包抽检 | 立即回滚相关变更 |
| NFR-PRIV-02 | 最小化采集与保留 | 仅保存业务必需字段；默认不记录连续轨迹；允许用户清空本地探索记录 | 数据模型审计 + 设置页手测 | 变更需补隐私说明并重审 |
| NFR-TEST-01 | ExplorationStore 测试覆盖率 | `ExplorationStoreTests` 必须覆盖：① upsertArchive 幂等性；② fetchAllRecords/fetchRecord/isArchived 全路径；③ 持久化失败错误路径 | 用例检查：`ExplorationStoreTests` 中上述 3 类行为各至少 1 条用例 | 缺失任一行为类别视为覆盖率不足，阻断 PR-2 合入 |
| NFR-TEST-02 | 状态机关键转换测试覆盖 | Section 4.2 中 8 条状态转换，`NAVIGATING↔IDLE`、`IN_RANGE↔NAVIGATING`、`IN_RANGE→UNLOCKED`、`UNLOCKED→ARCHIVED` 4 条必须有自动化测试覆盖（`UnlockEvaluatorTests` 或集成测试） | 用例命名包含转换语义，可在 `YOMUITests` 或独立 Unit target | 缺覆盖的关键路径视为阻断缺陷 |
| NFR-POWER-03 | 后台通知调度时间预算 | `NotificationOrchestrator` 每次后台执行（geofence enter → 调度完成）`P95 <= 10s` | `NotificationOrchestratorTests` 含计时断言（20 样本） | 超预算次数 > 5%，需收敛 `isArchived` 查询路径后重测 |

### 8.2 数据保留策略（Phase 0）

1. `ExplorationRecord` 默认本地长期保留，直到用户主动清除或卸载 App。
2. `WatchRegion` 为运行态衍生数据，可在重启后重建，不要求长期持久化。
3. 卡片文件保留在 App 沙盒，删除探索记录时应提供联动清理选项（避免孤儿文件）。
4. 日志中不得落地精确经纬度（调试构建除外；发布构建需脱敏到区间/哈希）。

### 8.3 风险登记册（Phase 0）

> 每条风险在 PR 合入前须核查缓解措施是否已落地。若风险触发，Owner 需在 48h 内更新本表状态。

| Risk-ID | 风险描述 | 可能性 | 影响面 | 缓解措施 | 预警信号 | 当前状态 |
| --- | --- | --- | --- | --- | --- | --- |
| RISK-01 | iOS 18 早期版本 `CLMonitor` exit 事件在远处误触发 | 中 | Passive 通知误发、体验混乱 | 在 `GeofenceMonitor` 中对每次 exit 事件追加距离二次校验（`distance > unlockRadius * 3`），低于阈值不下发通知 | Passive 测试中出现非预期 exit 回调 | 待实现（PR-3） |
| RISK-02 | 用户设备 `Background App Refresh` 被禁用导致 Passive 围栏事件不可用 | 高（iOS 系统省电策略频繁限制） | Passive 全链路静默失效 | 检测 `UIApplication.backgroundRefreshStatus`；若非 `.available`，关闭 Passive 开关并展示引导文案（T-PR1-04） | `testBackgroundRefreshUnavailableShowsGuidance` FAIL | 待实现（T-PR1-04） |
| RISK-03 | SwiftData 在 iOS 17.0–17.1 存在并发写入 bug（已知 rdar） | 低（目标用户多为 iOS 17.2+） | `ExplorationRecord` 偶发持久化失败 | 采用 `ModelContext` 主线程单写策略，避免后台并发写入；若发现崩溃率上升，降级至 CoreData | `ExplorationStore` 单测持久化用例出现随机失败 | 待监控（PR-2） |
| RISK-04 | 记忆点数量未来超出 `CLMonitor` 20 条件治理阈值，长尾记忆点 Passive 失效 | 中（Phase 0 数量少，远期风险） | 距用户当前位置较远的记忆点无法触发通知 | Top-N 轮换策略已在 `GeofenceMonitor` 接口契约中内置（Section 2.2）；超限前必须触发轮换逻辑 | 监控集合注册数 >= 18 时告警 | 接口已设计，待实现（T-PR3-01） |
| RISK-05 | 卡片渲染 P95 超过 1.5s（NFR-PERF-03），主要原因为大尺寸图片解码 | 低 | 卡片生成体验卡顿 | 使用 `ImageRenderer` 限制最终分辨率；封面图在写入时预缩略（`thumbnailAssetName` 字段） | `CardRenderer` 基准测试 P95 > 1.2s 时提前预警 | 待验证（T-PR2-02） |
| RISK-06 | `NSLocationAlwaysAndWhenInUseUsageDescription` 缺失导致 Passive 权限请求被系统静默拒绝 | 高（已确认当前缺口，`EVID-CONFIG-KEYS` FAIL） | Passive 链路完全无法启动 | T-PR1-01 补齐配置键；`GATE-CONFIG-PLIST-KEYS` 纳入 PR-1 合入门禁 | 配置补齐前禁止合入任何 PR-3 内容 | 待补齐（T-PR1-01） |

## 9. 分阶段实施（仅本地）

### Phase 0A（计划 2026-03-11 至 2026-03-13，PR-1 窗口）

1. 落地本地记忆数据模型（`MemoryPoint` 组合持有 `PointOfInterest`）与媒体索引。
2. 跑通 Active：导航 -> 解锁 -> 详情媒体播放（复用 `MemoryDetailView`）。

**DoD（验收标准）**：
1. 从本地 JSON 加载 >= 3 条 `MemoryPoint`，地图 pin 正常渲染。
2. 点击 pin -> 导航态 -> 到达范围内 -> 详情页展示标题/年份/摘要/媒体。
3. UI Test 断言：`memory_detail_title` 存在且文本匹配（**当前仓库待补齐，见 Section 11 第 11 项**）。

### Phase 0B（计划 2026-03-14 至 2026-03-17，PR-2 窗口）

1. 落地探索归档与档案页展示。
2. 落地卡片本地渲染 + 保存相册 + 系统分享。

**DoD（验收标准）**：
1. 体验完成后 `ExplorationRecord` 持久化，重启 App 仍可见。
2. 卡片渲染输出 >= 1 张图片，可保存至相册。
3. 系统分享 Sheet 弹出且可交互。

### Phase 0C（计划 2026-03-18 至 2026-03-21，PR-3 窗口）

1. 落地 Passive：`CLMonitor` geofence + 本地通知 + 点击跳转。
2. 完成去重/冷却与边界回归测试。

**DoD（验收标准）**：
1. Passive 模式注册 >= 1 个 `CLMonitor` 条件，进入围栏后收到本地通知。
2. 同一记忆 24h 内不重复通知。
3. 已 `ARCHIVED` 的记忆默认不触发通知。

### 阶段验收决策流程

> 适用于 Phase 0A / 0B / 0C 各阶段结束时的进阶决策。

#### 验收触发条件（缺一不可）

1. 本阶段所有 DoD 条目状态为 `PASS`（见 Section 10.6）。
2. 本阶段 PR 已合入 `main`，构建门禁 `GATE-BUILD` 通过。
3. 风险登记册（Section 8.3）中本阶段相关风险的缓解措施状态已更新为"已落地"。

#### 决策角色与责任

| 场景 | 决策权 | 所需证据 |
| --- | --- | --- |
| 本阶段 DoD 全 PASS，无阻塞 Risk | Phase Owner（表中各 PR 的合并发起方）可直接宣布通过并开启下阶段 | `GATE-PR{N}-COMPOSITE` 通过截图或日志 |
| 任意 DoD TODO 未完成 | 需挂起下阶段，不得开始 PR-{N+1} 任务 | 在当前 PR 描述注明阻塞原因 |
| 阶段延期 > 3 个工作日 | 必须在 Section 11.2 同步更新计划截止日期并写明原因 | 任务卡注释 |
| 高优先级风险（RISK-02/RISK-06）未缓解即进入下阶段 | 禁止 — 须先合入缓解 PR | N/A |

#### 进阶决策检查清单（每次 Phase 结束时执行）

```
[ ] 运行 GATE-PR{N}-COMPOSITE，截图留存
[ ] Section 10.6 DoD 追踪矩阵相关条目全部置为 PASS（附 EVID 引用）
[ ] Section 8.3 风险登记册本阶段相关行更新状态
[ ] Section 15.1 证据表补充本次核验记录（时间 + 命令 + 结果）
[ ] 下阶段任务卡 Owner 角色已替换为真实人名（GATE-OWNER-PLACEHOLDER 通过）
```

## 10. 阶段验收与自动化查验方案 (QA & Acceptance Testing)

为确保 Local-First 架构及 UI 渲染质量，每个阶段（Phase 0A, 0B, 0C）结束后均需进行相应的自动化与半自动化检测。推荐的 XCTest / Snapshot 测试方案如下：

### 10.1 逻辑/数据门禁测试（XCTest）
用于验证纯逻辑组件与数据完整性：
- `LocalMemoryDataIntegrityTests`（**已实现，当前落在 `YOMUITests` target，证据 `EVID-TEST-CLASS` + `EVID-TEST-DATA`**）：对 `Resources/memories.json` 做强解码，校验 `MemoryPoint.id` / `MemoryMedia.id` 为合法 UUID 且无重复；校验 `nameByLanguage` / `summaryByLanguage` / `storyByLanguage` 三语键完整且非空；校验 `audio` / `video` 必填 `duration`；校验 `unlockRadiusM > 0` 与 `localAssetName` 非空，防止格式错误导致运行期空数据或解锁异常。
- `UnlockEvaluatorTests`（**待实现**）：模拟不同 GPS 坐标流，验证 `distance <= unlockRadius` 判定与 `isUnlocked` 触发时机。
- `DwellTimerTests`（**待实现**）：覆盖抖动容忍窗口、连续 out-of-range 采样归零、回到 in-range 继续累计等边界行为。
- 当前 `LocalMemoryDataIntegrityTests` 落在 `YOMUITests` target；Phase 0 允许沿用。为缩短反馈链路，建议在后续阶段迁移到独立 Unit Test target。

### 10.2 Snapshot Tests（XCUITest 截图基线方案）
用于防止 UI 组件发生视觉退化，确保 DS Token 体系未被破坏。**工具与现有仓库对齐，使用 XCUITest 内置截图能力（`XCTAttachment`），不引入第三方 `swift-snapshot-testing` 库。**
- 对 `MemoryDetailView` 及其内的多媒体组件（CardRenderer 生成的图）等核心 View 使用 Snapshot 测试。
- **新页面 Snapshot 覆盖计划**：每个 PR 新增的主页面须在同一 PR 内补充浅色模式基线；深色模式基线可在下一 PR 补齐，但不得在无基线的情况下关闭 Snapshot 门禁。具体分配：
  - PR-2：`ExplorationArchiveView`（档案列表）浅色基线
  - PR-3：Passive 开关页 / 权限引导页浅色基线
- 新增页面/UI原则上应提供浅色/深色模式 Snapshot；**当前仓库已落地浅色基线，深色基线为待补项**（证据 `EVID-SNAPSHOT-TESTS`），后续补齐后纳入门禁。
- 基线截图存放位置与现有 `YOMUITests` 保持一致；并固定设备/系统版本（示例：`iPhone 17 + iOS 26.2`，具体以本机 `xcodebuild -showdestinations` 可用列表为准）避免噪声。
- 当前仓库已采用阻塞式门禁：缺少 baseline、尺寸不一致或像素差异超过阈值均会 `XCTFail`；现行阈值为 `diffRatio <= 1%`（`snapshotDiffTolerance = 0.01`），通道差阈值为 `8`（证据 `EVID-SNAPSHOT-THRESHOLD`）。后续在噪声可控后再评估是否收紧至 `0.1%`。

### 10.3 UI Tests (XCUITest)
用于自动化用户操作流及页面跳转验证：
- 配合 Xcode 提供 Mock Location 服务（GPX 文件注入坐标）。
- 启动 App 后验证 `NAVIGATING -> IN_RANGE -> UNLOCKED -> ARCHIVED` 这一完整闭环状态机的状态流转及 UI 元素更新。
- 包含 Accessibility Identifier 断言，确保核心按钮（如"体验完成"）可达且行为符合预期。

### 10.4 本地执行命令基线（可直接复制）

1. 先查询本机可用目标（避免写死不存在的模拟器）：

```bash
xcodebuild -scheme YOM -showdestinations
```

2. 选择一个可用 iOS Simulator destination 后执行：

```bash
DEST='platform=iOS Simulator,name=<YourSimulatorName>,OS=<YourSimulatorOS>'

xcodebuild -scheme YOM -destination "$DEST" build
xcodebuild -scheme YOM -destination "$DEST" \
  -only-testing:YOMUITests/LocalMemoryDataIntegrityTests test
```

3. 若报错 `Unable to find a device matching the provided destination specifier`，说明 destination 不存在，需替换为第 1 步列出的可用项。

### 10.5 Phase 0 最小门禁（CI 建议）

1. 编译门禁：`GATE-BUILD` 必须通过。
2. 数据门禁：`GATE-DATA-INTEGRITY` 必须通过。
3. Phase 0A 收口门禁：`GATE-UI-MAP-PIN-TEST` 与 `GATE-UI-MEMORY-TITLE-TEST` 均需纳入必跑集。
4. Snapshot 门禁：保持当前阻塞式阈值 `diffRatio <= 1%`，新增/更新 baseline 必须在 PR 描述附差异说明。
5. Phase 0C 前置门禁：`NSLocationAlwaysAndWhenInUseUsageDescription` 与 `NSPhotoLibraryAddUsageDescription` 配置完成并验证权限弹窗链路。
6. Passive 运行时前置门禁：`Background App Refresh` 不可用时必须走降级文案与引导，不得继续宣称 Passive 已启用。

### 10.6 DoD 追踪矩阵（执行必填）

| DoD-ID | 需求描述 | 验证方式 | 命令 / 用例 | 当前状态 |
| --- | --- | --- | --- | --- |
| DOD-0A-01 | 本地 JSON 可加载且 pin 正常渲染 | 自动化 + UI 自动化 | `GATE-DATA-INTEGRITY` + `GATE-UI-MAP-PIN-TEST` | PASS（证据 `EVID-TEST-DATA` + `EVID-UI-MAP-PIN-ASSERT`） |
| DOD-0A-02 | Active 链路可达详情并展示核心字段 | UI 自动化 | `GATE-UI-MEMORY-TITLE-TEST` | TODO |
| DOD-0B-01 | 完成体验后归档可持久化 | 单测 + UI 流程 | `GATE-EXPLORATIONSTORE-TESTS` + 重启验证 | PARTIAL（证据 `EVID-EXPLORATIONSTORE`；纯存储已通过，UI 接线待 AI-04） |
| DOD-0B-02 | 卡片可生成并可保存/分享 | 集成测试 | `GATE-CARDRENDERER-TESTS` | TODO |
| DOD-0C-01 | Passive 围栏提醒可触发 | 集成测试 | `GATE-GEOFENCE-TESTS` + `GATE-NOTIFICATION-TESTS` | TODO |
| DOD-0C-02 | 去重/冷却生效 | 单测 | `GATE-NOTIFICATION-TESTS` | TODO |
| DOD-CONFIG-01 | Always + PhotoAdd 权限键齐全且对 App Target 生效 | 配置核查 | `GATE-CONFIG-PLIST-KEYS` | TODO |
| DOD-CONFIG-02 | Background App Refresh 不可用时降级链路正确 | UI 自动化 + 断言 | `GATE-BG-REFRESH-GUARD-TEST` | TODO |
| DOD-I18N-01 | 新增记忆内容字段（name/summary/story）有 en / zhHans / yue 三语覆盖 | 自动化 | `GATE-I18N`（PR 合入前必跑） | PASS（证据 `EVID-TEST-DATA`） |

### 10.7 门禁命令字典（机器可执行）

> 说明：Task 卡的“测试门禁”必须引用以下 Gate ID，不再写自然语言描述。  
> 统一入口：`scripts/community_memory_gate.sh <GATE-ID>`。  
> 需要模拟器时，脚本按 `DEST` -> `SIM_UDID` -> 自动探测可用 iPhone simulator 的顺序解析 destination。

1. `GATE-BUILD`
```bash
scripts/community_memory_gate.sh GATE-BUILD
```
2. `GATE-DATA-INTEGRITY`
```bash
scripts/community_memory_gate.sh GATE-DATA-INTEGRITY
```
3. `GATE-UI-MAP-PIN-TEST`
```bash
scripts/community_memory_gate.sh GATE-UI-MAP-PIN-TEST
```
4. `GATE-UI-MEMORY-TITLE-TEST`
```bash
scripts/community_memory_gate.sh GATE-UI-MEMORY-TITLE-TEST
```
5. `GATE-CONFIG-PLIST-KEYS`
```bash
scripts/community_memory_gate.sh GATE-CONFIG-PLIST-KEYS
```
6. `GATE-MODULE-0B0C-IMPLEMENTED`
```bash
scripts/community_memory_gate.sh GATE-MODULE-0B0C-IMPLEMENTED
```
7. `GATE-SNAPSHOT-BASELINE-TESTS`
```bash
scripts/community_memory_gate.sh GATE-SNAPSHOT-BASELINE-TESTS
```
8. `GATE-SNAPSHOT-THRESHOLD-CONFIG`
```bash
scripts/community_memory_gate.sh GATE-SNAPSHOT-THRESHOLD-CONFIG
```
9. `GATE-BG-REFRESH-GUARD-TEST`（当前应为 FAIL，直到实现）
```bash
scripts/community_memory_gate.sh GATE-BG-REFRESH-GUARD-TEST
```
> ⚠️ **模拟器注入规范**：`UIApplication.backgroundRefreshStatus` 在模拟器中固定返回 `.available`，无法直接触发降级路径。测试实现**必须**：
> 1. 在测试中设置 `app.launchEnvironment["UITEST_SIMULATE_BG_REFRESH_UNAVAILABLE"] = "1"` 后再调用 `app.launch()`
> 2. App 代码在 Passive 权限编排入口处检查该键：若存在则将 `backgroundRefreshStatus` 视为 `.denied`，不得跳过此分支直接走正常链路
> 3. 此注入键**仅在 `#if DEBUG` 编译条件下生效**，发布构建不得响应该键
10. `GATE-OWNER-PLACEHOLDER`（任务卡开工前必跑；命中任务卡 Owner 占位符即 FAIL，未命中即 PASS）
```bash
scripts/community_memory_gate.sh GATE-OWNER-PLACEHOLDER
```
11. `GATE-I18N`（每个涉及新增记忆内容的 PR 必跑）
```bash
scripts/community_memory_gate.sh GATE-I18N
```
12. `GATE-EXPLORATIONSTORE-TESTS`（AI-02 已通过）
```bash
scripts/community_memory_gate.sh GATE-EXPLORATIONSTORE-TESTS
```
13. `GATE-CARDRENDERER-TESTS`（当前应为 FAIL，直到实现）
```bash
scripts/community_memory_gate.sh GATE-CARDRENDERER-TESTS
```
14. `GATE-GEOFENCE-TESTS`（当前应为 FAIL，直到实现）
```bash
scripts/community_memory_gate.sh GATE-GEOFENCE-TESTS
```
15. `GATE-NOTIFICATION-TESTS`（当前应为 FAIL，直到实现）
```bash
scripts/community_memory_gate.sh GATE-NOTIFICATION-TESTS
```
16. `GATE-PR1-COMPOSITE`
```bash
scripts/community_memory_gate.sh GATE-PR1-COMPOSITE
```
17. `GATE-PR2-COMPOSITE`
```bash
scripts/community_memory_gate.sh GATE-PR2-COMPOSITE
```
18. `GATE-PR3-COMPOSITE`
```bash
scripts/community_memory_gate.sh GATE-PR3-COMPOSITE
```
19. `GATE-A11Y`（当前应为 FAIL，直到 T-PR1-05 完成；每个引入新主页面的 PR 必跑）
```bash
scripts/community_memory_gate.sh GATE-A11Y
```
> 校验内容：① `AccessibilityTests` 类存在性；② 运行 `AccessibilityTests` 用例集（含超大字体下截断断言、核心交互元素 `accessibilityLabel` 非空断言）。
20. `GATE-INTERFACE-CONTRACT-FROZEN`（当前已通过；T-PR2-02 合入前仍必须复跑，确保 Protocol 签名与 Section 2.2 保持一致）
```bash
scripts/community_memory_gate.sh GATE-INTERFACE-CONTRACT-FROZEN
```
> 校验内容：4 个协议文件存在且包含 Section 2.2 中定义的核心方法签名关键词（`upsertArchive`、`render(memory:`、`refreshMonitors`、`scheduleNearbyReminder`）。当前应为 FAIL，直到 PR-2 实现这些协议。

## 11. 开工清单

1. 新增 `LocalMemoryDataIntegrityTests`，对 `Resources/memories.json` 做解码与 UUID 唯一性门禁。**已完成**（`YOMUITests/YOMUITests.swift`，证据 `EVID-TEST-DATA`）
2. ~~新建 `LocalMemoryRepository`，先从本地 `JSON` 读取记忆与媒体元数据。~~ **已完成**（`Features/Memory/LocalMemoryRepository.swift`，前提：数据门禁通过，证据 `EVID-CODE-LMR` + `EVID-TEST-DATA`）
3. 定义 `MemoryMedia.type` 与本地资源命名规范（含 `usdz`）。**已完成**（见 `specs/002-community-memory-backend/记忆写入指南.md`，证据 `EVID-WRITE-GUIDE`）
4. ~~实现 `UnlockEvaluator`（距离 + 停留时长）。~~ **已完成**（`Features/Memory/UnlockEvaluator.swift`，证据 `EVID-CODE-UE`）
5. ~~实现 `ExplorationStore`（SwiftData 优先，iOS 17+）。~~ **已完成纯存储闭环**（`Features/Memory/ExplorationStore.swift`、`YOMUITests/ExplorationStoreTests.swift`，证据 `EVID-EXPLORATIONSTORE`；Active 链路接线留待 AI-04）
6. 实现 `CardRenderer`（固定模板 1 套即可）。
7. 实现 `GeofenceMonitor`：`CLMonitor` + 最近点 Top-N 轮换。
8. 实现 `NotificationOrchestrator`：本地通知触发、去重、冷却。
9. 补齐权限与系统配置：`NSLocationAlwaysAndWhenInUseUsageDescription`、`NSPhotoLibraryAddUsageDescription`，并回归验证 Passive/相册保存权限弹窗链路。
10. 对齐 Snapshot 门禁文档与 CI：维持现行阻塞式阈值（`diffRatio <= 1%`），并在新增/更新基线时要求 PR 附差异说明；后续再评估收紧阈值到 `0.1%`。
11. 新增 Phase 0A UI Test：进入 `MemoryDetailView` 后断言 `memory_detail_title` 存在且文本匹配（当前待实现）。
12. 新增 Passive 降级保护：`Background App Refresh` 不可用时给出引导，不宣称 Passive 已启用（当前待实现）。
13. 新增 Phase 0A UI Test：Map 首屏 `map_point_1935` pin 可见且可点击。**已完成**（`YOMUITests/YOMUITests.swift::testMapPointPinVisibleAfterOnboarding`，证据 `EVID-UI-MAP-PIN-ASSERT`）

### 11.1 建议 PR 拆分（执行顺序）

| PR | 目标 | 内容 | 前置依赖（硬约束）| 过门槛条件 |
| --- | --- | --- | --- | --- |
| PR-1 | 先补“可执行基础” | 补权限键配置（Always + PhotoAdd）、补 `memory_detail_title` UI Test、补 Snapshot/CI 门禁映射、补 Background App Refresh 降级门禁、补 a11y 基线测试（`AccessibilityTests`） | 无 | `GATE-PR1-COMPOSITE`（应为 PASS） |
| PR-2 | 完成 Phase 0B | 实现 `ExplorationStore` + `CardRenderer` + 档案页最小闭环 | **PR-1 已合入 main** | `GATE-PR2-COMPOSITE`（应为 PASS） |
| PR-3 | 完成 Phase 0C | 实现 `GeofenceMonitor` + `NotificationOrchestrator`（Top-N、冷却、去重） | **PR-2 已合入 main**；RISK-06 缓解措施已落地 | `GATE-PR3-COMPOSITE`（应为 PASS） |

### 11.2 可直接派发的任务卡（执行边界 + 回滚条件）

> 计划日期采用绝对日期（America/New_York）；`Owner` 列格式为 `角色 @username`，且必须实名（示例：`iOS-Core @xiangkaisun`）；任务卡内存在 `@TBD` 时 `GATE-OWNER-PLACEHOLDER` 视为 FAIL。

| Task ID | 任务 | Owner | 优先级 | 计划开始 | 计划截止 | 允许改动文件 | 禁止改动 | 测试门禁 | 回滚条件 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-PR1-01 | 补齐权限键（Always + PhotoAdd） | iOS-Infra @xiangkaisun | P0 | 2026-03-11 | 2026-03-11 | `project.yml` | 业务逻辑文件 | `GATE-BUILD` + `GATE-CONFIG-PLIST-KEYS` | 构建失败，或任一权限键缺失 |
| T-PR1-02 | 新增 `memory_detail_title` UI 断言 | iOS-QA @xiangkaisun | P0 | 2026-03-11 | 2026-03-12 | `YOMUITests/YOMUITests.swift` | DS Token / 视觉样式 | `GATE-UI-MEMORY-TITLE-TEST` + `GATE-BUILD` | 连续 3 次本地运行仍出现非确定性失败 |
| T-PR1-03 | 对齐 Snapshot/CI 门禁 | iOS-QA @xiangkaisun | P1 | 2026-03-12 | 2026-03-13 | `YOMUITests/YOMUITests.swift`、CI 配置文档 | 业务功能实现文件 | `GATE-SNAPSHOT-BASELINE-TESTS` + `GATE-SNAPSHOT-THRESHOLD-CONFIG` | snapshot diff 超过 `1%` 且无合理变更说明 |
| T-PR1-04 | 补 Background App Refresh 降级门禁 | iOS-Core @xiangkaisun | P0 | 2026-03-12 | 2026-03-13 | `Features/*`（权限编排相关）、`YOMUITests/YOMUITests.swift` | 地图/检索主流程视觉改版 | `GATE-BG-REFRESH-GUARD-TEST` + `GATE-BUILD` | 不可用时仍显示 Passive 已启用 |
| T-PR1-05 | 新增 `AccessibilityTests`（a11y 基线：Phase 0A 页面） | iOS-QA @xiangkaisun | P1 | 2026-03-12 | 2026-03-13 | `YOMUITests/YOMUITests.swift` | 业务功能实现文件 | `GATE-A11Y` + `GATE-BUILD` | `AccessibilityTests` 任意用例失败或 XXXL 字体下元素截断 |
| T-PR2-01 | 实现 `ExplorationStore` | iOS-Core @xiangkaisun | P0 | 2026-03-14 | 2026-03-16 | `Features/Memory/*`（新文件可加） | Map 主流程状态机 | `GATE-BUILD` + `GATE-EXPLORATIONSTORE-TESTS` | 重启后记录丢失或数据不一致 |
| T-PR2-02 | 实现 `CardRenderer` | iOS-Media @xiangkaisun | P1 | 2026-03-14 | 2026-03-17 | `Features/Memory/*`、必要桥接 helper | 地图/导航交互层 | `GATE-BUILD` + `GATE-CARDRENDERER-TESTS` + `GATE-INTERFACE-CONTRACT-FROZEN` | 卡片生成失败率 > 1%（20 次样本） |
| T-PR3-01 | 实现 `GeofenceMonitor` Top-N | iOS-Location @xiangkaisun | P0 | 2026-03-18 | 2026-03-20 | `Features/Memory/*` | Retrieval/Archive 现有页面结构 | `GATE-BUILD` + `GATE-GEOFENCE-TESTS` | 监控集合频繁抖动，或注册数量超治理阈值 |
| T-PR3-02 | 实现 `NotificationOrchestrator` 去重冷却 | iOS-Notification @xiangkaisun | P0 | 2026-03-18 | 2026-03-21 | `Features/Memory/*` | Onboarding 既有权限文案 | `GATE-BUILD` + `GATE-NOTIFICATION-TESTS` | 24h 冷却失效或重复提醒 |

### 11.3 任务依赖关系（执行顺序约束）

> 下表声明强依赖（blockedBy）：被依赖任务未合入 main，则依赖方不得开始编码。

| Task ID | 被阻塞于（blockedBy） | 原因 |
| --- | --- | --- |
| T-PR1-02 | T-PR1-01 | 权限键就绪后才能稳定运行 UI Test 链路 |
| T-PR1-03 | T-PR1-02 | Snapshot 基线与 memory_detail_title 测试在同一 `xcodebuild test` 会话，需先通过 UI 断言 |
| T-PR1-04 | T-PR1-01 | BGRefresh 检测依赖 `NSLocationAlwaysAndWhenInUse` 配置存在（权限请求前置） |
| T-PR1-05 | T-PR1-02 | a11y 测试依赖 `MemoryDetailView` 已有 `accessibilityIdentifier`（T-PR1-02 落地后方可稳定断言） |
| T-PR2-01 | T-PR1-01, T-PR1-02, T-PR1-03, T-PR1-04, T-PR1-05 | PR-2 在 `main` 分支的干净基础上开始，避免配置缺口污染 ExplorationStore 测试 |
| T-PR2-02 | T-PR2-01 | `CardRenderer.render()` 输出的 `cardLocalPath` 需写入 `ExplorationRecord.cardLocalPath`；接口未稳定前不得实现 CardRenderer。合入前需 `GATE-INTERFACE-CONTRACT-FROZEN` PASS（校验 Section 2.2 四个协议签名已在代码中落地） |
| T-PR3-01 | T-PR2-01 | `GeofenceMonitor` 在 enter 事件中需调用 `ExplorationStore.isArchived()` 做去重判断 |
| T-PR3-02 | T-PR3-01 | `NotificationOrchestrator` 依赖 `GeofenceMonitor.startEventStream()` 提供的 `AsyncStream<GeofenceEvent>` |

> **并行开发白名单**：T-PR2-01 与 T-PR2-02 可在 T-PR2-01 接口契约冻结（Section 2.2）后并行实现，但 T-PR2-02 不得提前合入。

### 11.4 AI 分步执行流程（模块化实装）

> 目的：为 AI coding agent 提供可直接执行的最小闭环顺序，避免一次性横切 `Store / Renderer / Geofence / Notification / UI` 导致大 PR、上下文污染和回归面失控。AI 执行时默认遵循本节；若与 Section 11.2 任务卡冲突，以“更小步、更窄边界”的本节流程为准，但不得突破任务卡中的“禁止改动”约束。

#### 11.4.1 执行铁律（AI 必须遵守）

1. **先冻结接口，再写实现，最后做集成接线**；不得在同一步同时改协议签名、持久化实现和 UI 调用方。
2. **每一步只收敛一个核心模块**，最多允许顺带改动其测试夹具与最小依赖类型；跨模块协作优先使用 stub / mock / adapter，不得“顺手一起做完”。
3. **每一步结束必须满足三件事**：`xcodebuild build` 通过、对应 Gate 通过、能明确交接到下一步；三者缺一不可。
4. 现有 `LocalMemoryRepository` / `UnlockEvaluator` / `MemoryPoint` / `MemoryDetailView` 默认视为上游冻结依赖；除非阻塞当前 Gate，否则 AI 不得顺手重构。
5. UI 只允许做“接线式改动”：注入 protocol、view model、helper 或 accessibility 标识；禁止在 View body 内直接堆叠存储、地理围栏或通知逻辑。
6. 新类型优先按 `Protocol -> Error/Result -> Implementation -> Tests` 顺序落地；若某步新增公共类型，优先放在 `Features/Memory/` 下，避免过早扩散到多个目录。
7. 任一步若失败，应先缩步而不是扩面：把失败步骤继续拆为“纯逻辑层”和“系统桥接层”两个子步骤，再重新执行。
8. **AI-00 ~ AI-08 必须显式使用 SwiftLens MCP**：凡涉及 Swift 代码、Swift 测试、协议签名、引用影响面、a11y 标识落点、证据回填的步骤，不得仅靠全文检索或人工猜测；若未运行本节指定的 SwiftLens 工具，不得宣称“上下文已装载”“接口已冻结”“影响面已确认”。
9. **SwiftLens 预热是编码前置条件**：AI-00 必须先执行 `swift_check_environment`、`swift_lsp_diagnostics(project_path)`、`swift_build_index(project_path[, scheme])`；若任一失败、LSP 健康状态异常、或索引未生成，则本次开发会话状态记为 `BLOCKED-SWIFTLENS`，除修复工具链外不得继续写业务代码。
10. **每步遵循“索引 -> 定义 -> 引用 -> 校验”闭环**：编码前至少运行 `swift_analyze_files`、`swift_get_symbol_definition`、`swift_find_symbol_references_files` 中与本步匹配的最小组合；编码后必须对本步改动的 Swift 文件执行 `swift_validate_file`。若仅需替换已有 symbol 的实现体，优先使用 `swift_replace_symbol_body` 以保持签名稳定。
11. **SwiftLens 结果用于缩小改动面，而不是替代 Gate**：SwiftLens 负责语义导航、引用分析、类型校验、符号级改写；`xcodebuild build`、`xcodebuild test`、`scripts/community_memory_gate.sh`、Snapshot/a11y/UI 断言仍是验收真源，二者缺一不可。
12. **交接包必须包含 SwiftLens 证据**：至少列出本步运行过的 SwiftLens tool 名称、核验过的关键 symbol / file、由引用分析确认的影响面，以及仍未被 LSP 覆盖的盲区；缺失任一项，视为交接不完整。

#### 11.4.2 AI 执行顺序表（推荐严格串行）

| Step ID | 对应任务 / PR | 本步目标 | 允许改动文件 | 本步产出 | 必跑门禁 | 进入下一步条件 |
| --- | --- | --- | --- | --- | --- | --- |
| AI-00 | PR-1 / PR-2 开工前 | 基线核验与上下文装载，不写业务代码 | 只读：本 spec、`记忆写入指南.md`、`project.yml`、`scripts/community_memory_gate.sh`、相关现有实现 | 基线状态：哪些 Gate 已 PASS / FAIL；明确当前阻塞点 | `GATE-BUILD` + `GATE-DATA-INTEGRITY` | 明确当前基线无新增未知失败 |
| AI-01 | PR-2 / PR-3 前置 | 冻结四个后续模块的代码边界与脚手架 | `Features/Memory/ExplorationStore.swift`、`CardRenderer.swift`、`GeofenceMonitor.swift`、`NotificationOrchestrator.swift`、对应测试文件 | 协议、错误类型、结果类型、空实现 / stub、测试壳 | `GATE-BUILD` + `GATE-MODULE-0B0C-IMPLEMENTED` + `GATE-INTERFACE-CONTRACT-FROZEN` | 四个模块文件与测试壳齐备，接口签名不再漂移 |
| AI-02 | T-PR2-01 | 实现 `ExplorationStore` 的纯存储闭环 | `Features/Memory/ExplorationStore.swift`、必要 model / test 文件 | `upsertArchive` / `fetch` / `isArchived` 真正可用，幂等通过 | `GATE-BUILD` + `GATE-EXPLORATIONSTORE-TESTS` | `ExplorationStore` 可独立验证，不依赖 UI |
| AI-03 | T-PR2-02（第 1 步） | 实现 `CardRenderer` 的纯渲染闭环 | `Features/Memory/CardRenderer.swift`、模板 view / helper、对应测试 | 输出 PNG 到沙盒、素材缺失与渲染失败可分型 | `GATE-BUILD` + `GATE-CARDRENDERER-TESTS` | `render()` 可独立产图，不依赖分享 / 相册 UI |
| AI-04 | PR-2 集成 | 把 `ExplorationStore` + `CardRenderer` 接进 Active 完成链路与最小档案页 | `Features/Memory/*`、`Features/Retrieval/*`、必要时新增 `Features/Archive/*`、`YOMUITests/*` | `UNLOCKED -> ARCHIVED` 真正写档，档案可见，分享/保存最小闭环 | `GATE-PR2-COMPOSITE` + `GATE-A11Y` + `GATE-SNAPSHOT-BASELINE-TESTS` | Phase 0B DoD 全 PASS |
| AI-05 | T-PR3-01（第 1 步） | 实现 `GeofenceMonitor` 的纯围栏闭环 | `Features/Memory/GeofenceMonitor.swift`、候选点筛选 helper、对应测试 | Top-N 选择、`CLMonitor` 注册轮换、事件流输出 | `GATE-BUILD` + `GATE-GEOFENCE-TESTS` | `refreshMonitors()` 与事件流稳定，不触碰通知层 |
| AI-06 | T-PR3-02（第 1 步） | 实现 `NotificationOrchestrator` 的纯通知闭环 | `Features/Memory/NotificationOrchestrator.swift`、payload/cooldown helper、对应测试 | 调度、去重、24h 冷却、userInfo 反解 | `GATE-BUILD` + `GATE-NOTIFICATION-TESTS` | 通知层独立可测，不依赖页面跳转 |
| AI-07 | PR-3 集成 | 将 `GeofenceMonitor` + `NotificationOrchestrator` 接入 Passive 权限与跳转主线 | `Features/Memory/*`、权限编排相关 `Features/*`、`YOMUITests/*` | Passive 开关、围栏触发、通知点击回到记忆详情、BGRefresh 降级 | `GATE-BG-REFRESH-GUARD-TEST` + `GATE-PR3-COMPOSITE` + `GATE-A11Y` | Phase 0C DoD 全 PASS |
| AI-08 | 每步收口 | 回填文档、证据、风险状态，收敛到可交接状态 | 本 spec 的 Section 10.6 / 15.1 / 8.3（如有状态变化） | DoD 状态、EVID 引用、风险缓解状态同步 | 与本步对应 Gate 保持 PASS | 文档状态与代码状态一致，无“已完成但无证据”项 |

#### 11.4.2A SwiftLens MCP 强制动作（逐步）

1. `AI-00`
   必跑：`swift_check_environment` -> `swift_lsp_diagnostics(project_path)` -> `swift_build_index(project_path[, scheme])`。
   然后：对 `Features/Memory/*.swift`、`Features/Retrieval/MemoryDetailView.swift`、相关测试文件执行 `swift_analyze_files` 或 `swift_get_symbols_overview`，建立当前 symbol 基线。
   交付：明确记录 SwiftLens 环境是否健康、索引是否可用、哪些核心 symbol 已存在、哪些步骤将依赖这些 symbol；若预热失败，本步唯一允许动作是修复 SwiftLens 工具链。

2. `AI-01`
   必跑：`swift_search_pattern` + `swift_get_symbol_definition` + `swift_get_declaration_context`。
   用途：逐一核对 Section 2.2 的四个 protocol、错误类型、结果类型、测试壳是否已在代码中落地，禁止仅依赖 `rg` 判定“接口已冻结”。
   收口：对 `ExplorationStore.swift`、`CardRenderer.swift`、`GeofenceMonitor.swift`、`NotificationOrchestrator.swift` 跑 `swift_validate_file`；若需要替换 stub 实现，优先 `swift_replace_symbol_body`，不得顺手改签名。

3. `AI-02`
   必跑：`swift_analyze_files(['Features/Memory/ExplorationStore.swift'])`。
   然后：用 `swift_get_symbol_definition` 定位 `ExplorationRecord` / `ExplorationSource` / `ExplorationStoreProtocol` 真正声明位置；用 `swift_find_symbol_references_files` 追踪 `upsertArchive`、`fetchAllRecords`、`isArchived` 的调用面与测试覆盖面。
   收口：对本步改动的 store / model / test 文件逐个执行 `swift_validate_file`，确认幂等逻辑、SwiftData 包装层和测试夹具在语义上闭合。

4. `AI-03`
   必跑：`swift_analyze_files(['Features/Memory/CardRenderer.swift', 'YOMUITests/CardRendererTests.swift'])`。
   然后：用 `swift_get_file_imports` 审视渲染桥接依赖；对关键类型位置运行 `swift_get_hover_info`，确认 `ImageRenderer` / `SwiftUI` / `UIKit` 相关类型签名与预期一致；用 `swift_find_symbol_references_files` 检查 `CardRendererProtocol.render(...)` 的测试与调用落点。
   收口：对 renderer、模板 view、asset resolver 与测试文件执行 `swift_validate_file`；SwiftLens 可证明语义正确，但不能替代 PNG 产物与 Snapshot 验证。

5. `AI-04`
   必跑：`swift_build_index(project_path[, scheme])` 重新建索引，避免上一轮单模块实现后的引用结果陈旧。
   然后：用 `swift_find_symbol_references_files` 串起 `ExplorationStoreProtocol`、`CardRendererProtocol`、完成动作回调、档案页入口的跨文件接线；用 `swift_get_symbol_definition` 精确定位 `MemoryDetailView`、Archive 入口、最小分享/保存 helper 应落到哪个 symbol；用 `swift_search_pattern` 审计 `accessibilityLabel` / `accessibilityIdentifier` 是否落在正确 view。
   收口：对所有接线改动文件执行 `swift_validate_file`；若引用分析显示影响面超出 Active 链路，必须先缩步，不得继续扩展到 Passive。

6. `AI-05`
   必跑：`swift_analyze_files(['Features/Memory/GeofenceMonitor.swift', 'YOMUITests/GeofenceMonitorTests.swift'])`。
   然后：用 `swift_get_file_imports` / `swift_get_hover_info` 核对 `CLMonitor`、`CLCircularGeographicCondition`、`AsyncStream<GeofenceEvent>` 的类型与 API 形态；用 `swift_find_symbol_references_files` 追踪 `refreshMonitors(...)`、`startEventStream()`、候选点筛选 helper 的消费方。
   收口：对 monitor、driver、selector、tests 运行 `swift_validate_file`；SwiftLens 负责确保符号边界稳定，不负责证明系统围栏事件一定会在真机/模拟器触发。

7. `AI-06`
   必跑：`swift_analyze_files(['Features/Memory/NotificationOrchestrator.swift', 'YOMUITests/NotificationOrchestratorTests.swift'])`。
   然后：用 `swift_get_hover_info` 核对 `UNUserNotificationCenter`、通知 request/content/userInfo 相关类型；用 `swift_find_symbol_references_files` 追踪 `NotificationScheduleResult`、`scheduleNearbyReminder(...)`、`extractMemoryId(from:)` 的测试与调用面；必要时用 `swift_search_pattern` 固化 payload key 与 cooldown 分支的字符串/枚举使用点。
   收口：对 orchestrator、payload builder、cooldown policy、tests 运行 `swift_validate_file`；SwiftLens 不能替代通知权限与真实投递链路验证。

8. `AI-07`
   必跑：`swift_build_index(project_path[, scheme])`，然后用 `swift_find_symbol_references_files` 横向串起权限编排、`GeofenceMonitor` 事件、`NotificationOrchestrator` 调度、通知点击回跳、`MemoryDetailView` 入口。
   然后：用 `swift_get_symbol_definition` 定位 Passive 开关、权限说明、BGRefresh 降级展示 helper 的真实入口；用 `swift_search_pattern` 审计 `accessibilityIdentifier`、BGRefresh 引导文案与仅 DEBUG 生效的测试注入点。
   收口：对 Passive 主线改动文件全部执行 `swift_validate_file`；若引用图显示依赖扩散到非授权范围页面，必须回退到 adapter / helper 分层。

9. `AI-08`
   必跑：`swift_search_pattern` / `swift_analyze_files` 复核本步声称完成的协议、实现类、测试类、a11y 标识、EVID 所引用 symbol 是否真实存在。
   然后：交接包中必须写明“本步用过哪些 SwiftLens 工具、分析过哪些 file/symbol、哪些断言仍依赖 xcodebuild / Gate / UI 测试而非 LSP”。
   例外：若本步仅改文档且无任何代码状态变化，可跳过 `swift_validate_file`；但只要引用了代码状态，就必须先用 SwiftLens 复核，不得手写“已完成”。

#### 11.4.3 推荐模块内拆分（尽可能避免大文件）

1. `ExplorationStore` 推荐拆分为 5 层：
   `ExplorationStoreProtocol`、`ExplorationStoreError`、`ExplorationRecord` / `ExplorationSource`、`SwiftDataExplorationStore`、`ExplorationStoreTests`
2. `CardRenderer` 推荐拆分为 6 层：
   `CardRendererProtocol`、`CardRenderError`、`CardTemplateView`、`CardAssetResolver`、`DefaultCardRenderer`、`CardRendererTests`
3. `GeofenceMonitor` 推荐拆分为 6 层：
   `GeofenceMonitorProtocol`、`GeofenceEvent`、`GeofenceCandidateSelector`、`CLMonitorDriver`、`DefaultGeofenceMonitor`、`GeofenceMonitorTests`
4. `NotificationOrchestrator` 推荐拆分为 6 层：
   `NotificationOrchestratorProtocol`、`NotificationScheduleResult`、`NotificationPayloadBuilder`、`NotificationCooldownPolicy`、`DefaultNotificationOrchestrator`、`NotificationOrchestratorTests`
5. **跨模块共享类型最小化**：
   除 `ExplorationRecord`、`ExplorationSource`、`GeofenceEvent`、`NotificationScheduleResult` 外，不新增跨模块共享 model；其余依赖优先通过协议输入输出解耦。
6. **系统桥接单独封装**：
   `CLMonitor`、`UNUserNotificationCenter`、相册保存、系统分享都应有独立 adapter / helper；上层模块只依赖协议，不直接碰系统对象。

#### 11.4.4 每一步的最小交接包（AI 完成后必须具备）

1. 变更文件列表：只列本步真正改动的文件，不夹带与当前步骤无关的整理。
2. 本步通过的 Gate：至少列出 Gate ID，不得只说“测试通过”。
3. 尚未处理的边界：明确说明哪些能力故意留给下一步，例如“当前仅完成纯渲染，未接入分享 Sheet”。
4. 下一步建议入口：指出应该从哪个文件、哪个协议、哪个 Gate 开始，不得让下一个 AI 重新从全仓扫描。
5. SwiftLens 证据：列出本步实际运行过的 SwiftLens tool 名称，以及它们分别核验了哪些关键 file / symbol。
6. SwiftLens 盲区：明确哪些结论仍需依赖 `xcodebuild`、Gate、Snapshot、UI Test、真机/模拟器行为，而不是被 LSP 直接证明。

#### 11.4.5 AI 单步提示模板（可直接复用）

```text
你现在只执行 Step <AI-XX>，不要跨步。

目标：
- <只写一个核心目标，例如：实现 ExplorationStore 幂等持久化>

允许改动：
- <文件 1>
- <文件 2>

禁止改动：
- 地图主流程状态机
- 非本步骤对应的其他模块
- 视觉样式与 DS Token

必须满足：
- 协议签名保持与 Section 2.2 一致
- 先按 Section 11.4.2A 跑完本步要求的 SwiftLens MCP 工具；若 `swift_check_environment` / `swift_lsp_diagnostics` / `swift_build_index` 未通过，不得继续编码
- 完成后运行 <GATE-...>
- 输出“已完成 / 未完成 / 留给下一步”的边界说明
- 输出 `SwiftLens 证据`：本步使用的 tools、核验的 files/symbols、未覆盖盲区

如果实现过程中需要第二个模块配合：
- 先使用 stub / mock，不得直接跳去实现下一模块
```

## 12. 后续迁移到后端（保留位）

当你准备连服务器时，沿用当前端内模型做平滑迁移：

1. `LocalMemoryRepository` 升级为 `Repository` 协议：本地实现 + 远端实现可切换。
2. `ExplorationStore` 新增同步队列，离线写本地、在线回传服务端。
3. 通知从本地触发逐步过渡到“本地 + APNs 混合模式”。

## 13. 参考（本阶段相关）

1. Apple CLMonitor（iOS 17+ 区域监控）  
https://developer.apple.com/documentation/corelocation/clmonitor
2. Apple CLCircularGeographicCondition  
https://developer.apple.com/documentation/corelocation/clcirculargeographiccondition
3. Apple Region Monitoring（Legacy，上限约束仍适用）  
https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/LocationAwarenessPG/RegionMonitoring/RegionMonitoring.html
4. Apple Asking permission to use notifications  
https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications
5. Apple UNUserNotificationCenter  
https://developer.apple.com/documentation/usernotifications/unusernotificationcenter
6. Apple NSLocationAlwaysAndWhenInUseUsageDescription  
https://developer.apple.com/documentation/bundleresources/information-property-list/nslocationalwaysandwheninuseusagedescription
7. Apple NSLocationWhenInUseUsageDescription  
https://developer.apple.com/documentation/bundleresources/information-property-list/nslocationwheninuseusagedescription
8. Apple NSPhotoLibraryAddUsageDescription  
https://developer.apple.com/documentation/bundleresources/information-property-list/nsphotolibraryaddusagedescription
9. Apple AR Quick Look（USDZ）  
https://developer.apple.com/augmented-reality/quick-look/
10. Apple PHPhotoLibrary  
https://developer.apple.com/documentation/photos/phphotolibrary
11. Apple SwiftData  
https://developer.apple.com/documentation/swiftdata
12. Apple WWDC23: Meet Core Location Monitor  
https://developer.apple.com/videos/play/wwdc2023/10147/
13. Apple Technical Note TN2339（xcodebuild 命令行测试）  
https://developer.apple.com/library/archive/technotes/tn2339/_index.html
14. Apple News: Get started with Core Location updates（2024-06-11）  
https://developer.apple.com/news/?id=3xpv8r2m

## 14. 附录：数据写入规范（单一真源）

为避免规范漂移，`MemoryPoint` / `MemoryMedia` 的写入规则不再在本报告内重复维护。

1. 唯一真源文档：`specs/002-community-memory-backend/记忆写入指南.md`。
2. 本报告仅保留“执行门禁与引用关系”，不再复制字段表与模板。
3. 若两文档出现冲突，以写入指南为准，并在同一 PR 内同步修复本报告引用。

## 15. 第二轮核验与交叉验证（2026-03-10）

### 15.1 本地命令核验结果

| EVID-ID | 核验时间（America/New_York） | 检查项 | 核验命令 | 结果 | 说明 |
| --- | --- | --- | --- | --- | --- |
| EVID-DEST | 2026-03-09 23:05 | 可用 destination 列表 | `xcodebuild -scheme YOM -showdestinations` | PASS | `iPhone 17 (iOS 26.2)` 可用 |
| EVID-BUILD | 2026-03-11 18:41 | 构建门禁 | `scripts/community_memory_gate.sh GATE-BUILD` | PASS | AI-02 收口后整体编译通过 |
| EVID-TEST-DATA | 2026-03-09 23:05 | 数据门禁 | `xcodebuild -scheme YOM -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:YOMUITests/LocalMemoryDataIntegrityTests test` | PASS | 1/1 通过 |
| EVID-TEST-CLASS | 2026-03-09 23:03 | `LocalMemoryDataIntegrityTests` 类存在 | `rg -n "final class LocalMemoryDataIntegrityTests" YOMUITests/YOMUITests.swift` | PASS | 测试类已落地 |
| EVID-CODE-LMR | 2026-03-09 23:03 | `LocalMemoryRepository` 实现存在 | `test -f Features/Memory/LocalMemoryRepository.swift` | PASS | 文件存在 |
| EVID-CODE-UE | 2026-03-09 23:03 | `UnlockEvaluator` 实现存在 | `test -f Features/Memory/UnlockEvaluator.swift` | PASS | 文件存在 |
| EVID-CODE-MEMORYPOINT | 2026-03-09 23:03 | `MemoryPoint` 组合持有 `PointOfInterest` | `rg -n "let poi: PointOfInterest" Shared/Models/MemoryPoint.swift` | PASS | 组合模型成立 |
| EVID-WRITE-GUIDE | 2026-03-09 23:03 | 写入指南存在且含媒体字段规范 | `rg -n "MemoryMedia|localAssetName|usdz" specs/002-community-memory-backend/记忆写入指南.md` | PASS | 写入规范已落地 |
| EVID-GEN-PLIST | 2026-03-09 23:03 | 使用生成式 Info.plist | `rg -n "GENERATE_INFOPLIST_FILE: YES" project.yml` | PASS | 应通过 `INFOPLIST_KEY_*` 注入权限键 |
| EVID-CONFIG-WHENINUSE | 2026-03-09 23:03 | `WhenInUse` 权限键存在 | `rg -n "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription" project.yml` | PASS | 仅 `WhenInUse` 已配置 |
| EVID-SNAPSHOT-TESTS | 2026-03-09 23:08 | Snapshot 基线测试已落地（浅色） | `rg -n "testSnapshotBaselineOnboardingPage|testSnapshotBaselineMapPage|testSnapshotBaselineArchivePage|testSnapshotBaselineSettingsPage|testSnapshotBaselineRetrievalPage" YOMUITests/YOMUITests.swift` | PASS | 5 条浅色基线测试存在 |
| EVID-SNAPSHOT-THRESHOLD | 2026-03-09 23:08 | Snapshot 阈值配置 | `rg -n "snapshotDiffTolerance: Double = 0.01|snapshotChannelDeltaTolerance: Int = 8" YOMUITests/YOMUITests.swift` | PASS | 阈值与文档一致 |
| EVID-A11Y-TITLE-ID | 2026-03-09 23:03 | 详情页标题标识存在性 | `rg -n "memory_detail_title" Features` | PASS | `MemoryDetailView` 已有标识 |
| EVID-UI-MAP-PIN-ASSERT | 2026-03-10 13:24 | 地图 pin 可见性 UI 断言 | `scripts/community_memory_gate.sh GATE-UI-MAP-PIN-TEST` | PASS | `Executed 1 test`，`testMapPointPinVisibleAfterOnboarding` 通过 |
| EVID-UI-TITLE-ASSERT | 2026-03-10 13:24 | 详情页标题 UI 断言用例 | `scripts/community_memory_gate.sh GATE-UI-MEMORY-TITLE-TEST` | FAIL（预期） | 严格门禁已加入“测试方法存在性”校验，当前方法未落地（T-PR1-02） |
| EVID-BGREFRESH-GUARD | 2026-03-10 13:24 | Background App Refresh 降级保护用例 | `scripts/community_memory_gate.sh GATE-BG-REFRESH-GUARD-TEST` | FAIL（预期） | 严格门禁已加入“测试方法存在性”校验，当前方法未落地（T-PR1-04） |
| EVID-CONFIG-KEYS | 2026-03-10 13:24 | Passive/相册权限键（Build Settings 生效） | `scripts/community_memory_gate.sh GATE-CONFIG-PLIST-KEYS` | FAIL（预期） | 目前两键未对 App Target 生效（T-PR1-01） |
| EVID-MODULE-0B0C | 2026-03-11 18:41 | 0B/0C 核心模块实现度（文件 + 协议 + 测试类） | `scripts/community_memory_gate.sh GATE-MODULE-0B0C-IMPLEMENTED` | PASS | 四个模块文件、协议与测试类均已齐备；真实实现进度以各自 Gate 为准 |
| EVID-EXPLORATIONSTORE | 2026-03-11 18:40 | `ExplorationStore` 纯存储闭环 | `scripts/community_memory_gate.sh GATE-EXPLORATIONSTORE-TESTS` | PASS | 4/4 通过，覆盖幂等更新、重启后持久化、非法 ID、损坏数据错误路径 |
| EVID-A11Y | — | a11y 基线测试（AccessibilityTests 类 + XXXL 字体断言） | `scripts/community_memory_gate.sh GATE-A11Y` | FAIL（预期） | T-PR1-05 未落地（AccessibilityTests 类不存在） |
| EVID-INTERFACE-CONTRACT | 2026-03-11 18:41 | 接口契约冻结（4 个 Protocol 签名存在于源码） | `scripts/community_memory_gate.sh GATE-INTERFACE-CONTRACT-FROZEN` | PASS | Section 2.2 的 4 个核心方法签名已在源码中落地 |

### 15.2 文档交叉验证结果

1. 执行闭环：已新增 Section 0.3 / 10.6 / 10.7 / 11.2，使每个阶段 DoD 均可追踪到命令或测试，并以 Gate ID 落地。
2. 规范一致性：本报告不再复制写入字段规范，转为引用单一真源（Section 14），消除双维护风险。
3. 任务可派发性：已为 PR-1/2/3 拆出任务卡，明确允许改动文件、门禁（Gate ID）、回滚条件。
4. 状态可审计性：已引入 `EVID-*` 证据索引；所有“已完成”声明必须可在 Section 15.1 回溯。
5. 严格门禁：新增统一脚本入口 `scripts/community_memory_gate.sh`，并在关键 UI Gate 中加入“测试方法存在性”前置校验，避免 `only-testing` 命中 0 条测试却误判 PASS。

### 15.3 外部依据（用于冲突裁决）

1. CLMonitor 生命周期约束以 WWDC23 `Meet Core Location Monitor` 为准（同名 monitor 实例管理、启动后恢复事件流）。
2. 围栏数量与测试半径预算采用 Apple Region Monitoring 历史建议做保守治理；若 CLMonitor 文档更新，以新文档优先。
3. 权限键与权限请求链路以 Apple 官方文档为准：
   - `NSLocationAlwaysAndWhenInUseUsageDescription`
   - `NSPhotoLibraryAddUsageDescription`
   - `UNUserNotificationCenter` 授权请求
   - `PHPhotoLibrary.requestAuthorization(for: .addOnly)`
4. Passive 可靠性前置条件以 Apple Region Monitoring 文档为准：`Background App Refresh` 被关闭时，围栏事件不可作为可用路径声明。
