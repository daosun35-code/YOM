# 000 App Shell Routine

## 1. 结构摘要

App Shell 构成应用的主流程骨架，基于 `TabView` 和 `NavigationStack` 构建：
- **根路由结构**：使用 `TabView` 作为应用全局底座，包含三个固定的平行导航标签（Archive, Map, Settings）。
- **独立导航栈**：每个 Tab 内部使用独立的 `NavigationStack`。页面推入（Push）仅在当前 Tab 的导航栈内进行，确保不同 Tab 切换时状态互相隔离且保持记忆。
- **首屏拦截与呈现**：应用的启动流程（Language -> Permission -> Map）作为首轮强制介入路径。可使用根视图层的条件路由将启动向导全屏覆盖于主体 `TabView` 之上，待向导执行完成后再进入常规的地图为主默认态。
- **环境状态下发**：语言选择、无障碍参数和核心环境控制通过顶层 `@Environment` 或环境对象的统一下发机制注册，保证全视图级联的即时响应。

## 2. 官方 API 映射清单

根据官方 API 政策，本模块优先使用 SwiftUI L1/L2 原生交互与容器承载目标行为：

| 目标行为 | 官方 API 承接策略 | 匹配阶梯 |
| --- | --- | --- |
| 底栏固定导航切换 | `TabView` 与 `tabItem` 修饰符 | L1 |
| 层级结构的压栈推入 | `NavigationStack` 与 `NavigationLink` | L1 |
| 地点预览（半卡） | `.sheet` 结合 `presentationDetents([.medium])` | L1 |
| 记忆提取（全屏卡） | `.sheet` 结合 `.large` detent 或 `.fullScreenCover` | L1 |
| 地图默认状态搜索 | `.searchable` 修饰符 | L1 |
| 横跨层级的异常通知 | 原生 `.alert` 弹窗或顶层可控的 `.overlay(alignment: .top)` | L1 |
| 实时多语言切换机制 | `@Environment(\.locale)` 及自定义状态依赖 | L1 |

> *约束：底层视图需严格遵守动态 Safe Area 框架映射，不硬编码避让高度。*

## 3. 首轮目标版本边界

- `000-app-shell-routine` 首轮以 **`iOS 17+` App Shell 骨架闭环** 为目标版本范围。
- 首轮交付以本 Spec 已列出的 SwiftUI L1/L2 官方 API（`TabView` / `NavigationStack` / `.sheet` / `.searchable` 等）完成主流程与导航验证。
- `iOS 26+` 专属 API（例如新的底部附属区域能力）**不作为本 Spec 首轮交付前提**；若后续引入，必须在新 Spec 中明确最低系统版本与降级策略。

## 4. Deferred 清单

为保证首个 Spec 轻量清晰，以下内容被明确延后至后续独立功能 Spec 处理：
1. **容器形变动效**：导航容器交互的"单体形变 (Morphing)"效果首轮暂缓，一律使用官方标准的 `.sheet` 弹出动画承接过渡需求（接受 L2 系统默认视觉）。
2. **地图业务域深度逻辑**：选点态的大头针自动居中偏移量运算、路径规划渲染与 AR 罗盘导航的相对坐标换算。
3. **视觉还原微调规范**：精确阴影渲染参数、字距/行高覆盖、具体色域的纯视觉参数。
4. **历史工程代码重构**：任何旧有组件如何进行提取和复用的讨论。
