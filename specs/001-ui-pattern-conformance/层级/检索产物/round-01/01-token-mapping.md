# Round-01 Token Mapping

> 生成日期：2026-03-06
> 执行人：Claude (Step 1 静态清点)
> DS Token 文件：`Shared/DesignSystem/DSTokens.swift`、`DSTypography.swift`、`DSStyles.swift`

---

## Token 覆盖率总表

| Component | Token 使用集合 | 硬编码视觉值 | Verdict |
|---|---|---|---|
| AppRootView | `DSMotion` | 无 | Pass |
| ArchiveTabRootView | `DSSpacing`、`DSColor`、`DSRadius`、`DSControl`、`dsTextStyle`、`dsSurfaceCard` | 无 | Pass |
| MapTabRootView（根层） | `DSSpacing`、`DSColor`、`DSRadius`、`DSBorder`、`DSOpacity`、`DSControl`、`DSTypography`、`DSMotion` | `.easeOut(duration: 0.16)`（行 642，teardown 动画，非 `DSMotion.durationFast = 0.2`） | P2 |
| MapPreviewSheetView | `DSSpacing`、`DSColor`、`DSControl`、`DSLineSpacing`、`dsTextStyle`、`dsPrimaryCTAStyle` | 无 | Pass |
| PreviewMetadataChip | `DSSpacing`、`DSColor`、`DSOpacity`、`DSBorder`、`dsTextStyle` | `.font(.caption.weight(.semibold))` 行 1224（图标，文字已用 `dsTextStyle`） | P2 |
| NavigationPillView | `DSSpacing`、`DSColor`、`DSTypography`、`DSControl`、`dsTextStyle` | 无 | Pass |
| NavigationInlineDetailCard | `DSSpacing`、`DSColor`、`DSOpacity`、`DSBorder`、`DSRadius`、`DSControl`、`DSTypography`、`dsTextStyle`、`dsSecondaryCTAStyle` | 无（死代码） | N/A（死代码） |
| NavigationDetailSheet | `DSSpacing`、`DSColor`、`DSControl`、`DSTypography`、`dsTextStyle` | 无（死代码） | N/A（死代码） |
| NavigationTaskInfoRow | `DSSpacing`、`DSColor`、`dsTextStyle` | `.font(.caption.weight(.semibold))` 行 1612（图标，文字已用 `dsTextStyle`；死代码上下文） | N/A（死代码） |
| SearchOverlayCard | `DSSpacing`、`DSColor`、`dsTextStyle` | 无 | Pass |
| OnboardingFlowView | `DSColor`、`DSSpacing`、`DSTypography`、`DSControl`、`DSLayout`、`DSOpacity`、`DSMotion`、`dsTextStyle`、`dsPrimaryCTAStyle`、`dsSecondaryCTAStyle`、`dsSurfaceCard` | 无 | Pass |
| RetrievalView | `DSSpacing`、`DSColor`、`DSControl`、`DSTypography`、`dsTextStyle` | 无 | Pass |
| SettingsTabRootView / AboutView | `DSSpacing`、`DSColor`、`DSLineSpacing`、`DSLayout`、`dsTextStyle` | 无 | Pass |
| NativeSearchTextField | `DSSpacing`（caller side）、内部不使用 DS Token（UIKit 域） | 无（UIKit 实现层） | Pass（桥接已说明） |

---

## 硬编码视觉值明细

### HC-001 · P2 · 动画时长硬编码

| 字段 | 值 |
|---|---|
| 文件 | Features/Map/MapTabRootView.swift |
| 行号 | 642 |
| 代码 | `.easeOut(duration: 0.16)` |
| 上下文 | `handleEndNavigationAction()` 内 EndNavigation teardown 动画 |
| 问题 | `DSMotion.durationFast = 0.2`，此处 `0.16` 为经调试确认的特定值，但未通过 Token 管理。如需统一演进或全局改动，无法通过修改 DS 单点传播。 |
| 建议修复 | 在 `DSMotion` 新增 `static let durationTeardown: Double = 0.16` 并替换此处引用，或接受为局部特例并加注释说明（低优先级）。 |

### HC-002 · P2 · 图标 `.font(.caption)` 未用 `dsTextStyle`

| 字段 | 值 |
|---|---|
| 文件 | Features/Map/MapTabRootView.swift |
| 行号 | 1224（PreviewMetadataChip）、1612（NavigationTaskInfoRow，死代码） |
| 代码 | `.font(.caption.weight(.semibold))` |
| 上下文 | `Image(systemName:)` 图标字号，同一组件的 `Text` 已正确使用 `dsTextStyle(.caption, weight: .semibold)` |
| 问题 | `Image` 的 `.font()` 未走 DS Typography 路径，若 DS 字体尺度演进，图标与文字可能产生视觉偏差。 |
| 建议修复 | 将 `.font(.caption.weight(.semibold))` 替换为 `.font(DSTypography.caption.weight(.semibold))` 或封装 `DSTypography` 对应尺码（需确认 DSTypography 是否有 `.caption` 对应 font 值）。 |

### HC-003 · P2 · 预览 Sheet 高度边界值硬编码

| 字段 | 值 |
|---|---|
| 文件 | Features/Map/MapTabRootView.swift |
| 行号 | 179–180 |
| 代码 | `private let previewSheetCompactMinHeight: CGFloat = 200` / `previewSheetCompactMaxHeight: CGFloat = 360` |
| 上下文 | Sheet 高度 detent 的动态计算边界 |
| 问题 | 属于布局业务逻辑常量，非通用视觉 Token，可接受为局部常量；但若未来 sheet 高度策略演进（如 iPad 适配），值散落难以全局追踪。 |
| 建议修复 | 可选：移入 `DSControl` 作为 `previewSheetCompactMinHeight / MaxHeight`，或在本地以命名常量注释说明保留。 |

---

## Token 枚举完整性核查

以下枚举均已在 `Shared/DesignSystem/*.swift` 中定义，组件实际使用情况如下：

| Token 枚举 | 已使用组件数 | 未使用场景 |
|---|---|---|
| `DSColor` | 13/14（AppRootView 未直接用颜色） | — |
| `DSSpacing` | 13/14 | AppRootView 无布局用途 |
| `DSRadius` | 5（Map 相关、Archive） | OnboardingFlowView 无独立圆角需求（用 `dsSurfaceCard`） |
| `DSBorder` | 3（Map 相关） | 其余组件无边框 |
| `DSLineSpacing` | 2（Settings、MapPreviewSheet） | 其余组件文本间距用系统默认 |
| `DSOpacity` | 4（Map、Archive、Onboarding） | — |
| `DSMotion` | 3（AppRoot、Map、Onboarding） | Settings/Archive 无页面级动画 |
| `DSLayout` | 2（Onboarding、Settings） | — |
| `DSControl` | 9 | — |
| `DSTypography` | 5（Map 相关，图标字号） | 其余组件用 `dsTextStyle` modifier |
| `DSTextStyle` / `dsTextStyle` | 12/14 | NativeSearchTextField（UIKit 域）、AppRootView（无文本） |
| `dsPrimaryCTAStyle` | 3（Onboarding、MapPreview、MapNavInline(dead)） | — |
| `dsSecondaryCTAStyle` | 2（Onboarding、NavInlineDetail(dead)） | — |
| `dsSurfaceCard` | 2（Archive、Onboarding） | — |

---

## 活跃组件 Token 覆盖率汇总

| 评级 | 组件数 | 说明 |
|---|---|---|
| Pass | 9 | 无硬编码视觉值，完全 Token 化 |
| P2 | 2（MapTabRootView、PreviewMetadataChip） | 有硬编码值，但不阻断功能 |
| N/A | 3 | 死代码，不计入覆盖率 |
| **总活跃组件** | **11** | |
| **Token 合规率** | **81.8%（9/11）** | 目标：100% Pass |
