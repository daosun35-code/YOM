# UI Tips 深度调研与 YOM（SwiftUI）借鉴调整计划

- 文档日期：2026-02-27
- 调研对象：https://www.uidesign.tips/ui-tips
- 数据快照：站点 `sitemap-0.xml` 的 `lastmod` 为 2025-04-30T11:07:28.254Z；共提取 37 条 UI tips（`/ui-tips/*`，不含 tag 页）
- 本文定位：将第三方 UI 经验作为启发输入，最终方案严格对齐本仓库 P0/P1 约束（Apple 官方 API + 项目 Active docs）

## 1. 调研摘要（从 37 条 UI tips 抽样归纳）

### 1.1 高频主题

按标签统计（Top）：
- `ux` 30
- `ui` 23
- `visual effect` 14
- `cta` 10
- `conversions` 7
- `hierarchy` 6
- `forms` 4
- `accessibility` 3

结论：该站内容核心不是“炫技”，而是“降低理解成本 + 提高动作可预期性”。

### 1.2 对本项目最有价值的 6 类原则

1. **CTA 文案要消除不确定性**
- 代表 tips：
  - `Inform Users Beforehand`
  - `User Hate Surprises`
  - `Delete Modal`
- 核心启发：按钮文案需要明确“点击后会发生什么”，避免 `Yes/No` 这类脱离上下文文案。

2. **信息层级要稳定且可扫描**
- 代表 tips：
  - `Hack Visual Hierarchy`
  - `How To Enhance Hierarchy`
  - `The Perfect Header`
- 核心启发：主操作、主标题、次级说明必须在视觉上明显分层。

3. **输入/搜索要“自解释”**
- 代表 tips：
  - `Make Inputs Self-Explanatory`
  - `Pick The Correct Element`
- 核心启发：输入控件应通过占位/格式提示/控件类型减少错误输入与学习成本。

4. **移动端图标应辅以可见语义**
- 代表 tips：
  - `Support Icons With Labels`
  - `Make Tooltips Responsive`
- 核心启发：仅图标在移动端易误解，必要时补充可见标签或说明入口。

5. **危险操作必须降权 + 二次确认**
- 代表 tips：
  - `De-emphasize Dangerous Actions`
  - `Validate Deletion`
- 核心启发：危险动作视觉上应弱于主路径，并提供确认/撤销机制。

6. **卡片与列表项要具备明确可点击性**
- 代表 tips：
  - `Make Cards Look Clickable`
  - `Distinguish Selected Items`
  - `Visually Separate Elements`
- 核心启发：可点元素需要明确 affordance；已选状态需要一眼识别。

## 2. 与 YOM 当前功能的对应分析

> 当前代码基线（核心）：`AppRootView` + `MapTabRootView` + `ArchiveTabRootView` + `SettingsTabRootView` + `OnboardingFlowView` + `RetrievalView`。

| 模块 | 当前状态 | 可借鉴 tips | 调整方向（SwiftUI） | 优先级 |
|---|---|---|---|---|
| Onboarding（语言/权限） | 流程完整，按钮文案较基础 | `Inform Users Beforehand`, `User Hate Surprises`, `Distinguish Selected Items` | 明确“允许/暂不”后果；强化当前选中语言视觉态 | P0 |
| Map 预览卡（Go/Details） | 已有双按钮 + sheet | `How To Enhance Hierarchy`, `Use Consistent Buttons` | 统一主次按钮策略，避免状态切换时语义漂移 | P0 |
| Map 搜索（searchable + overlay） | 可用，但输入引导可提升 | `Make Inputs Self-Explanatory`, `Pick The Correct Element` | 优化 placeholder/推荐文案与输入约束，减少空搜/误搜 | P1 |
| Map 图标操作（Locate） | 视觉为纯图标，语义主要靠 a11y label | `Support Icons With Labels`, `Make Tooltips Responsive` | 在紧凑布局下增加可见短标签或说明入口 | P1 |
| 导航结束动作（End） | 可直接结束，缺少确认层 | `De-emphasize Dangerous Actions`, `Validate Deletion`, `Delete Modal` | 增加 `confirmationDialog`，危险操作降权 | P0 |
| Archive 卡片列表 | 已可点击，但“可点感”可继续强化 | `Make Cards Look Clickable`, `Visually Separate Elements` | 统一卡片点击 affordance 与分组留白节奏 | P1 |
| Retrieval / About 文本阅读 | 可读性基础可用 | `Avoid Fullwidth Paragraphs`, `The Perfect Header` | 长文本区限制最大宽度，优化标题-正文层级 | P1 |
| Settings（语言切换） | 功能稳定，信息层次简单 | `Distinguish Selected Items`, `Design Better Menus` | 强化“当前语言”识别与 section 信息组织 | P2 |

## 3. 仅使用 SwiftUI 官方 API 的实施计划

> 约束对齐：遵循 `docs/official-api-policy.md`，优先 L1/L2，不引入自定义容器动画。

### Phase 1（P0，先做可用性与风险控制）

1. Onboarding 文案与状态强化
- 目标：点击行为可预期，减少“是否会被阻断”的疑问。
- API：`Button`, `.accessibilityHint`, `.foregroundStyle`, `.overlay`, `.animation`。

2. Navigation End 二次确认
- 目标：将“结束导航”视为潜在危险动作。
- API：`confirmationDialog`, `Button(role: .destructive)`, `Button(role: .cancel)`。

3. Map 预览卡主次 CTA 一致化
- 目标：`Go/Change Destination` 与 `Details` 在层级上稳定。
- API：`.buttonStyle(.borderedProminent/.bordered)`, `.controlSize`, `.lineLimit`, `.minimumScaleFactor`。

### Phase 2（P1，体验清晰度与可学习性）

1. 搜索输入自解释优化
- 目标：降低误输入与无结果率。
- API：`.searchable`, `.searchSuggestions`, `.submitLabel`, `.textInputAutocapitalization`, `.autocorrectionDisabled`。

2. 图标操作补可见语义
- 目标：移动端不依赖 hover/猜测理解。
- API：`Label`, `LabeledContent`, `.safeAreaInset`, `.overlay`。

3. Archive/Retrieval 的可读性与可点击性
- 目标：列表项可点感更明确，阅读区更稳。
- API：`.contentShape(Rectangle())`, `.frame(maxWidth:)`, `.font`, `.foregroundStyle(.secondary)`, `.padding`。

### Phase 3（P2，视觉一致性收口）

1. 统一层级 token（标题级别、次要文本透明度、间距节奏）
- API：`Font.TextStyle`, `.fontWeight`, `.opacity`, `VStack(spacing:)`。

2. 统一选中态策略（语言项、地图已选点相关信息块）
- API：`.background`, `.clipShape`, `.overlay`, `.tint`。

## 4. 任务拆解（可直接转开发）

1. `OnboardingFlowView`
- 明确权限按钮语义文案（允许后行为/暂不后行为）。
- 强化语言选中样式（颜色 + 图标 + 背景，不仅依赖单一特征）。

2. `MapTabRootView`
- 为结束导航加确认对话框。
- 统一预览卡主次按钮视觉强度。
- 搜索输入提示与建议区文案精炼。
- 为定位等关键图标操作增加可见辅助标签方案（紧凑布局自适应）。

3. `ArchiveTabRootView`
- 增强条目可点击 affordance（右侧动作文案或更明确交互提示）。
- 调整 section 留白，减少视觉噪音。

4. `RetrievalView` / `AboutView`
- 控制长段落阅读宽度，优化标题-说明-正文层级。

5. `YOMUITests`
- 新增/更新用例：
  - 结束导航需要确认。
  - Onboarding 权限页文案语义可见。
  - 搜索建议与无结果反馈链路保持稳定。

## 5. 验收标准

1. 文案可预期性
- 关键 CTA（继续、允许、暂不、结束导航）均可从文案直接理解后果。

2. 危险操作安全性
- 结束导航必须通过二次确认才能执行。

3. 输入与搜索清晰度
- 搜索框提示与建议项能明确输入期望；无结果时可恢复操作明确。

4. 可访问性与移动端可理解性
- 关键图标操作具备可见语义补充；保持原有 accessibility label/trait 完整。

5. 视觉层级一致性
- 主 CTA、次级 CTA、辅助文案在 Map/Onboarding/Archive 的层级关系一致。

## 6. 风险与边界

- 以下 tips 与当前 App Shell 关联较低，暂不纳入本轮：`Social Login`、`Highlight The Best Offer`、`Choose Chart Types Carefully`、Landing Page Hero 系列。
- 本轮不引入 UIKit 自定义容器，不触发 L4（自定义转场/容器）。
- 外部 tips 仅作启发；若与 Apple HIG 或仓库 Active 规范冲突，以 P0/P1 为准。

## 7. 参考来源

### 核心入口
- https://www.uidesign.tips/ui-tips
- https://www.uidesign.tips/sitemap.xml
- https://www.uidesign.tips/sitemap-0.xml

### 本计划重点借鉴的 UI tips
- https://www.uidesign.tips/ui-tips/don-t-let-user-guess
- https://www.uidesign.tips/ui-tips/users-hate-surprises
- https://www.uidesign.tips/ui-tips/quick-ui-fixes
- https://www.uidesign.tips/ui-tips/quick-ui-fixes-1
- https://www.uidesign.tips/ui-tips/visual-hierarchy
- https://www.uidesign.tips/ui-tips/how-to-design-the-perfect-header
- https://www.uidesign.tips/ui-tips/make-inputs-self-explanatory
- https://www.uidesign.tips/ui-tips/number-input-1
- https://www.uidesign.tips/ui-tips/support-icons-with-text
- https://www.uidesign.tips/ui-tips/responsive-tooltips
- https://www.uidesign.tips/ui-tips/de-emphasize-dangerous-actions
- https://www.uidesign.tips/ui-tips/how-to-validate-deletion
- https://www.uidesign.tips/ui-tips/make-cards-look-clickable-vol-2
- https://www.uidesign.tips/ui-tips/distinguish-selected-items
- https://www.uidesign.tips/ui-tips/visually-seperate-elements-1
- https://www.uidesign.tips/ui-tips/line-width
