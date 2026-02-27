# Context Firewall

> 本文件划定 AI 与开发者在本仓库中的上下文读写边界。

## Active Context（默认可读可写）

- `docs/` — 项目 Active 规范
- `specs/` — 功能规格与验收场景
- `templates/` — 文档模板

## Legacy Context（默认不可读）

- 外部冻结归档目录（如 `../app-dev-legacy-archive/`）
- 旧仓库中的 `.pen` 画布文件
- AI 会话记忆 / Knowledge Item 中继承的旧设计决策

**触发条件**：仅当开发者在当次会话中明确说"请检索历史归档"时方可读取，且读取结果写入 Active 文档前须通过下方禁止词扫描。

## 禁止词清单

以下术语在本仓库 Active 文档中禁止出现（ADR 历史背景段除外）：

| 类别 | 禁止术语示例 |
|------|-------------|
| 旧浮动容器 | `TabBar-Floating`, `BottomBar`, `FloatingTabBar` |
| 旧形变组件 | `BottomMorphingContainer`, `NavPill` |
| 旧抽屉组件 | `Sheet-Half`, `Sheet-Full`, `SheetHalfView`, `SheetFullView` |
| 旧导航组件 | `CustomNavHeader`, `DetailNavCardView` |
| 旧组件 ID | 如 `tkvXY`, `Kz16x`, `CfMBE` 等画布节点 ID |
| 旧代码路径 | 如 `YOMPackage/Sources/...` |

**行为模式等价禁止**：即使不使用上述名称，以下交互模式描述未经 ADR 审批不得写入：
- "底部浮动工具栏"及同义表述
- 导航容器间的形变/变形过渡动画
- 非官方 API 的自定义半屏/全屏抽屉

## KI 隔离规则

- 本项目不继承任何 Knowledge Item 中的设计决策
- KI 仅可用于理解历史背景，不得作为 Active 规范输入
- 从 KI 获取的信息在写入 Active 文档前须通过禁止词扫描

## 例外流程

任何需要突破本文件规则的场景，必须通过 ADR 审批（`docs/adr/NNN-<title>.md`）。ADR 由人工审批，AI 不得自行创建并自行批准。
