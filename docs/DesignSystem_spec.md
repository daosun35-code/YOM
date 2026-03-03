# Design System Spec（SwiftUI Native / Lean）

> Active spec — YOM 视觉与交互的一致性规范。  
> 目标：在不引入冗余框架的前提下，建立可维护、可扩展、可落地的最小设计系统。

## 1. 适用范围

- 平台：iOS 17+
- 技术边界：仅使用 SwiftUI 原生 API（L1/L2）
- 覆盖页面：Onboarding / Map / Archive / Settings / Retrieval

## 2. 设计目标与非目标

### 2.1 目标

1. 统一视觉决策来源：颜色、字体、间距、圆角、状态不再散落硬编码。
2. 建立最小抽象层：先 token，再少量可复用样式；不一次性造“组件库大全”。
3. 保持原生体验：遵循 Apple 平台交互与系统容器行为。

### 2.2 非目标

1. 不引入第三方 UI 框架或第三方组件库。
2. 不引入自定义容器与自定义转场体系。
3. 不为“可能复用”提前构建大量组件。

## 3. 成熟设计系统调研结论（归纳）

以下为对成熟系统官方文档的归纳，不是逐字拷贝实现：

1. Apple HIG：强调层级、和谐、平台一致性，优先使用系统范式。
2. Fluent 2：token 分层（global + alias）能减少硬编码并提升跨端一致性。
3. Atlassian：将 token 作为单一事实源（single source of truth），基础样式统一管理。
4. Carbon：使用“角色型 token + theme”替代直接写死颜色值，支持主题切换与可访问性。
5. Material：采用 reference/system/component token 分层，组件尽量消费系统 token 而非直接值。

对 YOM 的落地结论：采用“2 层 token + 少量模式组件”即可满足当前体量，避免过度工程化。

## 4. 系统结构（最小化）

### 4.1 层级定义

- L0 Foundations（必须）：Design Tokens
- L1 Primitives（可选）：统一样式封装（按钮/卡片/输入）
- L2 Patterns（少量）：跨页面重复结构（如标题区块、操作区块）

### 4.2 控制规模规则

1. 新建 Primitive 的前提：同一模式至少在 3 处重复。
2. 首轮上限：Primitives 不超过 8 个。
3. 优先替换硬编码样式，不优先抽象业务视图。

## 5. Token 规范（MVP）

### 5.1 命名规则

- 使用语义命名，不使用视觉命名：`surfacePrimary` 而不是 `gray100`。
- 不暴露页面专属 token：页面专属值先回收为语义角色。

### 5.2 Color Tokens（语义色）

建议首轮保留以下最小集合：

- `surfacePrimary`
- `surfaceSecondary`
- `surfaceElevated`
- `textPrimary`
- `textSecondary`
- `textInverse`
- `accentPrimary`
- `accentOnPrimary`
- `borderSubtle`
- `borderStrong`
- `statusSuccess`
- `statusWarning`
- `statusError`

约束：
- 优先映射系统语义色（如 `Color(.systemBackground)`、`Color.secondary`、`.tint`）。
- 禁止在业务页直接写原始 hex/rgb（例如 `Color(red:...)`）。

### 5.3 Typography Tokens

仅基于 `Font.TextStyle`：

- `display` -> `.largeTitle`
- `title` -> `.title2`
- `headline` -> `.headline`
- `body` -> `.body`
- `caption` -> `.caption`

约束：
- 默认跟随 Dynamic Type。
- 除品牌字标外，禁止固定字号作为常规正文方案。

### 5.4 Spacing Tokens

首轮统一为 8pt 节奏，保留必要细分：

- `space4 = 4`
- `space8 = 8`
- `space12 = 12`
- `space16 = 16`
- `space24 = 24`
- `space32 = 32`

### 5.5 Radius / Stroke / Elevation

- Radius：`r8`, `r12`, `r16`
- Border width：`bw1`, `bw2`
- Elevation：优先系统材质与层次（`.regularMaterial`），避免自定义复杂阴影系统

### 5.6 Motion Tokens

- `durationFast = 0.2`
- `durationNormal = 0.35`
- 默认曲线：`.easeInOut` / `.spring(response:dampingFraction:)`
- `Reduce Motion` 开启时统一降级为淡入淡出

## 6. 原生 SwiftUI API 白名单（实施约束）

容器与导航：
- `TabView`
- `NavigationStack`
- `.sheet`
- `.fullScreenCover`
- `.presentationDetents`

交互与反馈：
- `Button`
- `.buttonStyle(.borderedProminent/.bordered/.plain)`
- `.alert`
- `.confirmationDialog`
- `.searchable`
- `.disabled`

视觉样式：
- `.font`
- `.foregroundStyle`
- `.background`
- `.overlay`
- `.clipShape`
- `.tint`
- `.controlSize`

可访问性：
- `.accessibilityLabel`
- `.accessibilityHint`
- `.accessibilityValue`
- `.accessibilityAddTraits`

## 7. 禁止项

1. 在页面中新增“魔法数字风格”常量（未进入 token 的尺寸/颜色/间距）。
2. 新增 UIKit 桥接仅用于视觉定制。
3. 为单一页面一次性创建大而全组件层。

## 8. 推荐目录结构（精简）

```text
Shared/
  DesignSystem/
    DSTokens.swift          # Color/Spacing/Radius/Motion
    DSTypography.swift      # TextStyle 映射
    DSStyles.swift          # ButtonStyle/CardStyle/InputStyle
```

约束：
- 首轮最多 3 个文件。
- 每个文件只承担单一职责。

## 9. 首轮落地顺序（防冗余）

1. 先抽 L0 token（不改交互，只替换硬编码样式入口）。
2. 再抽 2-3 个高频样式（Primary CTA、Secondary CTA、Surface Card）。
3. 最后按页面迁移（Onboarding -> Map -> Archive/Settings -> Retrieval）。

## 10. 验收标准

1. `Features/` 中新增代码不得直接声明原始颜色值。
2. 核心文本样式全部来自 `DSTypography`。
3. 主要 CTA 的样式策略一致（主按钮/次按钮语义稳定）。
4. Dynamic Type 下关键内容不被截断。
5. `Reduce Motion` 路径可用且不影响流程完成。

## 11. 强约束验收（必选）

以下 5 项全部通过，才可判定“解耦到位且高可维护”。

### 11.1 CI/Lint 门禁（硬阻断）

- 必须在 CI 增加 Design System 扫描任务；失败即阻断合并。
- 扫描范围：`Features/**/*.swift`
- 最低检查项：
1. 禁止新增原始颜色构造（如 `Color(red:`, `Color(` hex 包装器等）。
2. 禁止新增固定字号正文（如 `.font(.system(size:`，品牌字标白名单除外）。
3. 禁止新增未注册 spacing/radius 魔法数字（白名单除外）。

### 11.2 分层边界（硬规则）

1. 页面层（`Features/`）只允许消费 `Shared/DesignSystem/*` 暴露的 token 与样式。
2. 页面层不得定义可复用视觉常量；仅允许一次性业务常量（例如业务阈值）。
3. 新视觉语义必须先入 token，再被页面消费；禁止“先页面硬编码、后补 token”。

### 11.3 回归测试基线（必跑）

1. UI 快照：Onboarding / Map / Archive / Settings / Retrieval 五个核心页面至少各 1 张基线快照。
2. 可访问性：至少覆盖 Dynamic Type（最大辅助字号）与 Reduce Motion 两条路径。
3. 交互稳定性：主 CTA 与危险操作（如确认对话）需有 UI 测试断言。

### 11.4 变更治理（必留痕）

1. token 变更必须记录 changelog（新增 / 修改 / 删除 / 替代项）。
2. 删除 token 必须提供 deprecation 周期（至少一个迭代）和迁移指引。
3. 若变更影响跨页面视觉语义，必须附 ADR 或等效决策记录。

### 11.5 迁移度量（持续监控）

每次迭代记录以下指标，趋势必须向好：

1. `Features/` 内硬编码样式点位总数（目标：持续下降）。
2. token 覆盖率（目标：持续上升）。
3. 复用样式覆盖组件数（目标：主链路页面全部接入）。

建议在 PR 模板加入必填字段：
- “新增/修改 token 列表”
- “受影响页面”
- “回归验证结果”

## 12. 参考来源（官方）

- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- Apple SwiftUI: https://developer.apple.com/swiftui/
- Apple `TabView`: https://developer.apple.com/documentation/SwiftUI/TabView
- Apple Search in SwiftUI: https://developer.apple.com/documentation/SwiftUI/Adding-a-search-interface-to-your-app
- Apple `presentationDetents`: https://developer.apple.com/documentation/swiftui/view/presentationdetents%28_%3A%29
- Microsoft Fluent 2 Design Tokens: https://fluent2.microsoft.design/design-tokens
- Microsoft Fluent 2 Layout: https://fluent2.microsoft.design/layout
- Atlassian Foundations: https://atlassian.design/foundations/
- Atlassian Spacing: https://atlassian.design/foundations/spacing
- IBM Carbon Color Overview: https://carbondesignsystem.com/elements/color/overview/
- IBM Carbon Spacing Overview: https://carbondesignsystem.com/elements/spacing/overview/
- Material Web Theming: https://material-web.dev/theming/material-theming/
- Material Web Color: https://material-web.dev/theming/color/

> 检索日期：2026-03-03（America/New_York）
