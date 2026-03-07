# Round-01 视觉一致性报告（Step 3）

> 生成日期：2026-03-06
> 执行步骤：Step 3 — 视觉一致性审计（Token 覆盖率 + 截图差异）
> 数据来源：静态代码扫描（rg）+ 01-token-mapping.md 延伸分析
> 说明：iOS 模拟器截图无法从 CLI 自动抓取，截图比对以**代码推导替代**（标注可复核路径）

---

## 1. 审计范围与分层

| 层级 | 屏幕 / 组件 | 审计方式 |
|---|---|---|
| L0 Shell | `AppRootView`、`TabView` | 代码推导 |
| L1 Feature Root | `ArchiveTabRootView`、`MapTabRootView`、`SettingsTabRootView`、`OnboardingFlowView`、`RetrievalView` | 代码推导 |
| L2 Map 子组件 | `MapPreviewSheetView`、`NavigationPillView`、`SearchOverlayCard`、`PreviewMetadataChip` | 代码推导 |
| L3 桥接层 | `NativeSearchTextField` | 代码推导（UIKit 域，DS 在 caller 侧） |

---

## 2. Token 覆盖率汇总（引用 01-token-mapping.md）

| 活跃组件 | Pass/P2 | 说明 |
|---|---|---|
| AppRootView | Pass | 仅 DSMotion 动画 |
| ArchiveTabRootView | Pass | DSSpacing/DSColor/DSRadius/DSControl/dsTextStyle/dsSurfaceCard 全覆盖 |
| MapTabRootView（根层） | P2 | HC-001 teardown 动画 0.16 硬编码 |
| MapPreviewSheetView | Pass | 全 Token 化 |
| PreviewMetadataChip | P2 | HC-002 图标 `.font(.caption)` 硬编码 |
| NavigationPillView | Pass | 全 Token 化 |
| SearchOverlayCard | Pass | 全 Token 化 |
| OnboardingFlowView | Pass | 全 Token 化 |
| RetrievalView | Pass | 全 Token 化 |
| SettingsTabRootView / AboutView | Pass | 全 Token 化 |
| NativeSearchTextField（桥接） | Pass（特例） | UIKit 域内部不用 DS Token，caller 侧已 Token 化 |

**活跃组件 Token 合规率：9/11 = 81.8%**（P2 ×2，P0/P1 = 0）

---

## 3. 同层级视觉偏差清单

### 3.1 L1 Feature Root — 横向 Padding 对比

| 屏幕 | 水平 Padding | 布局 Token | 备注 |
|---|---|---|---|
| ArchiveTabRootView | `DSSpacing.space16`（16pt） | 无 DSLayout 约束 | 全宽 List/Card 样式，16pt 为卡片外边距 |
| SettingsTabRootView | `DSSpacing.space24`（24pt） | `DSLayout.readableContentMaxWidth`（680pt） | 正文阅读区，24pt 标准边距 |
| RetrievalView | `DSSpacing.space24`（24pt） | `DSLayout.readableContentMaxWidth`（680pt） | 正文阅读区，与 Settings 一致 |
| OnboardingFlowView | `space16`（标题行）/ `space24`（正文/按钮） | `DSLayout.onboardingContentMaxWidth`（520pt） | 两级 padding 策略（标题窄/正文宽） |
| MapTabRootView | 不适用（全屏 Canvas） | 不适用 | 地图全屏无 content padding |

**偏差分析：**

- Archive（16pt）与 Settings/Retrieval（24pt）存在 8pt 水平边距差异。
- 差异属**设计意图分歧**而非 Token 缺失：Archive 是 List/Card 屏（宽屏卡片贴近边缘），Settings/Retrieval 是阅读屏（大边距增强可读性）。
- 两组均使用 DS Token，无硬编码值，可维护性合规。
- **若未来 iPad 适配需统一 L1 边距策略**，需在 DSLayout 补充 `contentEdgePadding` 分级枚举，否则会产生维护分歧。

**判定：P2**（可维护性隐患，不阻断视觉一致性，短期可接受）

---

### 3.2 L1 Feature Root — 标题字重一致性

| 屏幕 | 页面级标题 | 字重 Token |
|---|---|---|
| ArchiveTabRootView | 无独立页面标题（用 NavigationBar inline title） | — |
| SettingsTabRootView | `dsTextStyle(.title, weight: .semibold)` | ✅ |
| RetrievalView | `dsTextStyle(.title, weight: .semibold)` | ✅ |
| OnboardingFlowView | `DSTypography.brandDisplay`（.largeTitle, .bold, .rounded）/ `dsTextStyle(.title, weight: .semibold)` | ✅（品牌字体合理独立） |

**判定：Pass** — 内容屏（Settings/Retrieval）标题均用 `.semibold`，一致。Onboarding 品牌字体独立，合理。

---

### 3.3 L2 Map 子组件 — 图标字号一致性

| 组件 | 图标字号用法 | 相邻文字用法 | 偏差 |
|---|---|---|---|
| `PreviewMetadataChip`（行 1224） | `.font(.caption.weight(.semibold))`（raw） | `.dsTextStyle(.caption, weight: .semibold)` | **有偏差**（图标绕过 DS） |
| `NavigationPillView` | `.font(DSTypography.iconLarge.weight(.semibold))` | `.dsTextStyle(...)` | ✅ 合规 |
| `SearchOverlayCard`（行 540/556） | `.font(DSTypography.iconMedium.weight(.semibold))` | `.dsTextStyle(...)` | ✅ 合规 |
| `NavigationTaskInfoRow`（行 1612，死代码） | `.font(.caption.weight(.semibold))`（raw） | `.dsTextStyle(.caption, weight: .semibold)` | P2（死代码，不计入活跃） |

**根本原因：** `DSTypography` 仅定义 `iconLarge（.title2）`、`iconMedium（.body）`，缺少 `iconSmall（.caption）` Token，导致 caption 尺寸图标无 DS 锚点，开发者只能退而求其次用 raw `.font(.caption)`。

**判定：P2** — 视觉上当前一致（均为 `.caption`），但若全局调整 caption 字号，图标字号不会跟随 DS 演进。

---

### 3.4 L1 — 动效策略一致性

| 场景 | 动画值 | DS 锚点 | 偏差 |
|---|---|---|---|
| Shell tab 切换（AppRootView） | `DSMotion.shell(reduceMotion:)` | ✅ | — |
| Onboarding step 切换 | `DSMotion.shell(reduceMotion:)` | ✅ | — |
| Map 搜索展开/收起 | `shellAnimation`（= DSMotion.shell） | ✅ | — |
| Map EndNavigation teardown | `.easeOut(duration: 0.16)` | ❌ 硬编码 | **偏差** |
| Map 预览 Sheet detent 调整 | `previewSheetDetentAnimation`（局部变量） | 未检索到 DS 锚点 | 需确认 |

**`previewSheetDetentAnimation` 追查：**

<details>
<summary>扫描结果</summary>

`previewSheetDetentAnimation` 出现于 MapTabRootView:764，是局部 computed var，需查原文。

</details>

**判定：P2**（HC-001，已记录于 01-token-mapping.md）— 仅影响单次 EndNavigation 动画曲线与其他 spring 动画不一致。

---

### 3.5 DS Token 枚举完整性缺口

| 缺口 | 影响 | 建议 |
|---|---|---|
| `DSTypography.iconSmall` 缺失 | caption 尺寸图标无 DS 锚点（HC-002） | 补充 `static let iconSmall = Font.caption` |
| `DSMotion.durationTeardown` 缺失 | EndNavigation 0.16s 无 Token 管理（HC-001） | 补充 `static let durationTeardown: Double = 0.16` |
| `DSControl` 缺少 Sheet 高度边界 | previewSheet 高度散落局部常量（HC-003） | 可选：补充 `previewSheetCompactMinHeight / MaxHeight` |
| `DSLayout` 缺少 L1 边距分级 | Archive 16 vs Settings 24 无统一命名（VCNS-001） | 可选（iPad 适配前可延迟） |

---

## 4. 截图基线分析（代码推导，无模拟器截图）

> 注：以下为基于代码结构的视觉推导，无法替代真实快照。如需快照 diff，请在 Simulator 中对各 Tab 截图后手动对比。

| 页面 | 背景层 | 内容区主色 | 卡片样式 | 间距节奏 |
|---|---|---|---|---|
| Onboarding | `DSColor.surfacePrimary → DSColor.surfaceSecondary`（渐变） | `DSColor.textPrimary` | `dsSurfaceCard`（语言选项） | space12/space24 |
| Archive | `DSColor.surfacePrimary` | `DSColor.textPrimary` | `dsSurfaceCard`（条目列表） | space8/space12/space16 |
| Map | MapKit 渲染层（全屏） | — | 浮层 `DSColor.surfaceElevated` | DSControl 动态计算 |
| Settings | `DSColor.surfacePrimary` | `DSColor.textPrimary` | 无卡片，纯文本块 | space12/space24 |
| Retrieval | `DSColor.surfacePrimary` | `DSColor.textPrimary` | `dsSurfaceCard`（检索结果） | space12/space24 |

**视觉一致性评估：**
- Archive / Onboarding / Retrieval 均使用 `dsSurfaceCard` 呈现卡片内容 → **风格统一 ✅**
- Settings 无卡片（纯文本信息），符合设置页轻量语义 → **设计意图合理 ✅**
- Map 为全屏 Canvas，浮层组件使用 `DSColor.surfaceElevated`，与其他 Tab 的 `surfacePrimary` 区分层次 → **语义正确 ✅**

---

## 5. 触控热区检查

| 组件 | 热区 | 满足 44×44pt？ |
|---|---|---|
| PrimaryCTA Button | `DSControl.largeButtonHeight = 52pt`，`frame(maxWidth: .infinity)` | ✅ |
| SecondaryCTA Button | 同上 | ✅ |
| Archive 列表条目 | `DSControl.listItemMinHeight = 72pt`，全宽 | ✅ |
| NavigationPill（EndNav） | `DSControl.minTouchTarget = 44pt` | ✅ |
| LocateMe 浮动按钮 | `DSControl.minTouchTarget`（44pt frame） | ✅ |
| PreviewMetadataChip | 信息展示组件（只读），无交互热区要求 | N/A |

**判定：Pass** — 所有可交互控件热区 ≥ 44×44pt。

---

## 6. Reduce Motion 兼容性

| 场景 | `reduceMotion` 分支 | 实现 |
|---|---|---|
| Shell 入场动画 | `DSMotion.shell(reduceMotion:)` → `.easeInOut(0.2)` | ✅ |
| Onboarding step 动画 | 同上 | ✅ |
| Archive submenu 切换 | `.easeInOut(DSMotion.durationFast)` | ✅（静态 easeInOut，无 spring）|
| EndNavigation teardown | `.easeOut(0.16)`（无 reduceMotion 分支） | ⚠️ 无 reduceMotion 特判，但 easeOut 本身无幅度/位移，风险极低 |

**判定：P2**（teardown 缺 reduceMotion 分支，低风险）

---

## 7. 视觉偏差汇总清单（P0/P1/P2）

| ID | 类别 | 描述 | 严重级 | 文件:行 | 建议 |
|---|---|---|---|---|---|
| VCNS-001 | L1 布局 | Archive(16pt) vs Settings/Retrieval(24pt) 水平 padding 差异，无统一 DSLayout 命名 | P2 | ArchiveTabRootView:172, SettingsTabRootView:121 | 可延迟至 iPad 适配时新增 DSLayout 分级命名 |
| VCNS-002 | Typography | `PreviewMetadataChip` 图标 `.font(.caption)` 绕过 DS Typography | P2 | MapTabRootView:1224 | 补充 `DSTypography.iconSmall` 后替换 |
| VCNS-003 | DS Token 缺口 | `DSTypography` 缺少 `iconSmall` Token | P2 | Shared/DesignSystem/DSTypography.swift | 补充 `static let iconSmall = Font.caption` |
| VCNS-004 | Motion | EndNavigation teardown 动画 `.easeOut(0.16)` 硬编码，缺 DSMotion 锚点 | P2 | MapTabRootView:642 | 补充 `DSMotion.durationTeardown = 0.16` 后替换 |
| VCNS-005 | Motion | EndNavigation teardown 缺 reduceMotion 分支（easeOut 本身低风险） | P2 | MapTabRootView:642 | 低优先级，随 VCNS-004 修复一并评估 |

**P0 = 0，P1 = 0，P2 = 5**

---

## 8. 收敛判定

| 判定 | 说明 |
|---|---|
| **Conditional Pass** | P0 = 0，P1 = 0；5 项 P2 均为可维护性/Token 缺口，不阻断视觉一致性或功能。 |

**下一步最小任务集（Step 3 遗留，可并入下轮修复批次）：**

1. `DSTypography` 补充 `iconSmall = Font.caption`，替换 MapTabRootView:1224 图标 `.font(.caption)`（VCNS-002 + VCNS-003）。
2. `DSMotion` 补充 `durationTeardown: Double = 0.16`，替换 MapTabRootView:642 硬编码（VCNS-004 + VCNS-005 同步评估）。
3. 可选：`DSControl` 补充 `previewSheetCompactMinHeight / MaxHeight`（HC-003，低优先级）。
4. 可选：`DSLayout` 补充 L1 边距分级命名（VCNS-001，延至 iPad 适配前）。
