# 001 UI Pattern Conformance Audit

> 目的：沉淀“控件范式选对了，但层级/语义不规范”的审查标准，供后续对话快速检索与复用。  
> 检索关键词：`设置页不规范` `segmented 位置不对` `Form 里 CTA` `语言选择重复标签` `destructive 无确认`

## 1. 问题定义

本 Spec 关注以下高频问题：
1. 使用了正确的 SwiftUI 官方控件，但摆放层级、语义结构或交互预期不符合 iOS 常见范式。
2. 页面可用但“看上去不对”，主要表现为信息层级混乱、动作权重不当、风险动作保护不足。

## 2. 适用范围

首轮覆盖：`Archive`、`Settings`、`About`。  
后续可扩展至所有 `Features/**/*.swift`。

## 3. 规则清单（可检索）

### UIP-001: Form 行项过度“按钮化”

- 触发信号：
1. 页面使用 `Form` / `Section` 承载设置项。
2. 行级导航动作使用 `Button`，并套用 `dsPrimaryCTAStyle()` / `dsSecondaryCTAStyle()`。
- 风险：设置页出现“列表行里再包一层 CTA 卡片”，视觉权重异常，不符合系统设置页预期。
- 推荐范式：优先 `NavigationLink` + 系统 disclosure 行语义；CTA 样式用于主流程动作，不用于设置列表行导航。

### UIP-002: Section 标题与控件标签语义重复

- 触发信号：
1. `Section(strings.xxx)` 已表达语义（如 Language）。
2. 内部 `Picker(strings.xxx, ...)` 再次显示同名标签。
- 风险：出现“Language + Language”重复层级，增加噪音。
- 推荐范式：保留一个可见语义层；另一层使用 `.labelsHidden()`，并补 `accessibilityLabel`。

### UIP-003: 破坏性动作缺少二次确认

- 触发信号：
1. `Button(role: .destructive)` 直接执行不可逆或重置操作。
2. 未配套 `confirmationDialog` / `alert`。
- 风险：误触导致流程重置或数据状态突变。
- 推荐范式：在设置/管理页中，所有破坏性动作必须经 `confirmationDialog` 明确确认。

### UIP-004: Segmented 控件层级过重

- 触发信号：
1. `Picker(...).pickerStyle(.segmented)` 被包在厚重 header 中。
2. 同区域叠加摘要文字、分割线、额外装饰导致“伪导航条”观感。
- 风险：用户难判断这是“同页筛选/视图切换”还是“上层导航切换”。
- 推荐范式：保留系统 segmented；放在与内容紧邻的位置（如 `safeAreaInset(.top)`）；统计信息并入 section 标题或次级信息位。

## 4. 快速检索方法（给其他对话直接复用）

```bash
# 1) 查设置页是否把行项做成 CTA
rg -n "dsPrimaryCTAStyle\\(|dsSecondaryCTAStyle\\(" Features/Settings

# 2) 查 Section 与 Picker 标签是否重复（按具体字符串键继续人工核对）
rg -n "Section\\(strings\\.|Picker\\(strings\\." Features/Settings

# 3) 查 destructive 是否缺少确认（需结合同文件是否出现 confirmationDialog/alert）
rg -n "Button\\(role:\\s*\\.destructive\\)" Features
rg -n "confirmationDialog\\(|\\.alert\\(" Features

# 4) 查 segmented 是否可能层级过重
rg -n "\\.pickerStyle\\(\\.segmented\\)" Features
```

## 5. 修复策略（SwiftUI 原生 API）

1. 设置行导航：`NavigationLink` 优先，避免行级 CTA 按钮风格。
2. 筛选切换：`Picker + .segmented`，不自定义容器动画。
3. 风险动作：`confirmationDialog` + `.destructive` + `.cancel`。
4. 信息层级：统计文案优先靠近内容区（section header / secondary text），减少顶部叠层。

## 6. 验收标准

1. `Form` 行内导航不再使用 CTA button style。
2. 不出现可见的重复标签（如 `Language + Language`）。
3. 设置页所有 destructive 操作具备二次确认。
4. segmented 区域不叠加冗余摘要与装饰，首屏层级清晰。

## 7. 当前基线（2026-03-03）

1. `Archive`：已按本规则完成一次收敛（segmented 置于 `safeAreaInset(.top)`，统计并入 section 标题）。
2. `Settings`：存在可优化项（行级 CTA、标签重复、beta destructive 缺确认）作为后续整改输入。
