# 001 App 本体组件层级与 Token 深度检索总控 Spec（可复用）

> 文档日期：2026-03-06（America/New_York）  
> 目标：建立一套可反复执行的“组件层级 + Token + 交互质量”检索协议，持续清除 vibe coding 隐性问题。  
> 适用范围：`App/`、`Features/`、`Shared/`、`YOMUITests/`、`docs/`。

## 0. 本 Spec 解决的 4 个问题

1. 每个组件是否使用原生 API（Apple Framework First）。  
2. 组件是否在正确层级（导航层级、模态层级、容器层级）。  
3. 对应层级 UI 视觉是否统一（Token 化、尺寸与对齐一致）。  
4. 每个组件的开始/结束/切换交互是否流畅、可测、可回归。

## 1. 当前项目基线快照（Round-0）

### 1.1 组件层级（静态）

1. L0 `App Shell`：`YOMApp` -> `AppRootView` -> `TabView(Archive/Map/Settings)`。  
2. L1 `Feature Root`：`ArchiveTabRootView`、`MapTabRootView`、`SettingsTabRootView`、`OnboardingFlowView`、`RetrievalView`、`AboutView`。  
3. L2 `Map 子组件`：`MapPreviewSheetView`、`NavigationPillView`、`NavigationInlineDetailCard`、`NavigationDetailSheet`、`SearchOverlayCard`、`NavigationTaskInfoRow`、`PreviewMetadataChip`。  
4. L3 `平台桥接/服务`：`NativeSearchTextField(UIViewRepresentable)`、`DeferredFirstResponderTextField(UITextField)`、`MapSearchModel(MKLocalSearchCompleter)`、`UserLocationProvider(CLLocationManager)`。

### 1.2 Token 类（Design System）

1. `Shared/DesignSystem/DSTokens.swift`：`DSColor`、`DSSpacing`、`DSRadius`、`DSBorder`、`DSLineSpacing`、`DSOpacity`、`DSMotion`、`DSLayout`、`DSControl`。  
2. `Shared/DesignSystem/DSTypography.swift`：`DSTextStyle`、`DSTypography`、`dsTextStyle`。  
3. `Shared/DesignSystem/DSStyles.swift`：`DSPrimaryCTAButtonStyle`、`DSSecondaryCTAButtonStyle`、`DSSurfaceCardModifier`。

### 1.3 原生 API 基线

1. 当前 UI 栈主要来自 `SwiftUI + UIKit + MapKit + CoreLocation`。  
2. `project.yml` 与 `YOM.xcodeproj/project.pbxproj` 未见第三方 UI 依赖（`packageProductDependencies` 为空）。  
3. 原生性判定标签统一使用：
1. `NativeDirect`：直接使用 SwiftUI / UIKit / MapKit 官方 API。
2. `NativeBridge`：通过 `UIViewRepresentable` / `UIViewControllerRepresentable` 桥接原生 API。
3. `NonNative`：第三方 UI 框架或非 Apple 渲染层（当前基线应为 0）。

## 2. 四大审计维度与硬性判定

### 2.1 维度 A：原生 API 审计

1. 每个组件必须标注 `NativeDirect | NativeBridge | NonNative`。  
2. `NonNative` 一律至少记为 P1，必须解释收益与替代成本。  
3. `NativeBridge` 必须说明桥接原因（系统能力缺口、可访问性、焦点控制、输入法行为等）。

### 2.2 维度 B：层级正确性审计

1. 每个 Tab Root 仅允许一个主 `NavigationStack(path:)` 真源。  
2. `navigationDestination` 禁止挂在 lazy 容器错误层级（`List/Lazy*` 内错误放置会导致目的地不稳定）。  
3. Push/Modal 语义必须分离：层级钻取用 push；自包含任务用 sheet/modal。  
4. Sheet 关闭路径必须可收敛到单一状态写回（防止关闭迟滞和补弹）。

### 2.3 维度 C：视觉一致性审计

1. 文本、颜色、间距、圆角优先使用 DS Token。  
2. 控件触控热区目标 `>=44x44pt`。  
3. 同层级组件的对齐、间距、标题权重与信息密度需一致。  
4. 若存在“硬编码视觉值”且可被 Token 覆盖，记为 P2（影响一致性演进）。

### 2.4 维度 D：交互流畅度审计

1. 覆盖三类交互：开始（Open/Present）、结束（Dismiss/End）、切换（Switch/Replace）。  
2. 必须以“重复测试 + 分位阈值”判定稳定性，不接受单次通过。  
3. 推荐阈值（与现有 `YOMStressTests` 一致）：
1. End 导航：P95 < 500ms，P99 < 800ms。
2. 预览关闭：P95 < 400ms，P99 < 800ms。
3. Pin 切换：P95 < 500ms，P99 < 800ms。
4. 搜索打开到键盘可交互：P95 < 350ms，P99 < 600ms，Max < 1000ms。
4. 动画策略需兼容 Reduce Motion，避免高风险 motion trigger。

## 3. 多轮检索循环（可无限复用直到问题收敛）

### Step 0：建立本轮产物目录

1. 固定目录：`specs/001-ui-pattern-conformance/层级/检索产物/round-<NN>/`。  
2. 每轮至少输出 4 个文件：
1. `00-component-inventory.md`
2. `01-token-mapping.md`
3. `02-hierarchy-findings.md`
4. `03-interaction-latency-report.md`

### Step 1：静态全量清点（组件 + Token + API）

1. 枚举组件、层级、桥接类型、token 使用热点。  
2. 标注每个组件入口动作、退出动作、切换动作。

### Step 2：层级正确性审计（规则匹配 + 人工复核）

1. 检查 `NavigationStack` 真源、`navigationDestination` 放置点、Push/Modal 语义。  
2. 检查 `sheet` 的状态源是否唯一、关闭路径是否收敛。  
3. 检查 `safeAreaInset` 与背景层覆盖责任是否分离。

### Step 3：视觉一致性审计（Token 覆盖率 + 快照）

1. 标记组件是否遵守 DS Token（颜色/间距/圆角/字体/动效）。  
2. 对比关键页面基线截图（Onboarding/Map/Archive/Settings/Retrieval）。  
3. 输出“同层级视觉偏差清单”（按 P0/P1/P2 分级）。

### Step 4：交互流畅度审计（重复回归 + 指标）

1. 运行 `YOMUITests` 与 `YOMStressTests`。  
2. 记录稳定性（失败率）和时延分位（P50/P95/P99/Max）。  
3. 对失败链路追加录像与定位备注（卡在输入焦点、dismiss、切换同帧冲突等）。

### Step 5：收敛判定与下一轮计划

1. `Pass`：P0=0、P1=0，且所有关键链路满足阈值。  
2. `Conditional Pass`：P0=0，仍有 P1 或局部阈值波动。  
3. `Fail`：存在 P0，或关键链路 P99 持续超阈值。  
4. 每轮必须输出下一轮最小任务集（仅列必须项，不列愿望项）。

## 4. 固定命令清单（每轮直接复跑）

### 4.1 组件/Token/API 清点

```bash
rg -n "struct\\s+[A-Za-z0-9_]+\\s*:\\s*View" App Features Shared | sort
rg -n "enum DSColor|enum DSSpacing|enum DSRadius|enum DSBorder|enum DSLineSpacing|enum DSOpacity|enum DSMotion|enum DSLayout|enum DSControl|enum DSTextStyle|enum DSTypography|struct DSPrimaryCTAButtonStyle|struct DSSecondaryCTAButtonStyle|struct DSSurfaceCardModifier" Shared/DesignSystem/*.swift
rg -n "import\\s+(SwiftUI|UIKit|MapKit|CoreLocation|AppKit)" App Features Shared | sort
```

### 4.2 层级规则扫描

```bash
rg -n "NavigationStack\\(|NavigationLink\\(|navigationDestination\\(|sheet\\(|fullScreenCover\\(|safeAreaInset\\(|presentationDetents\\(|presentationBackgroundInteraction\\(" App Features Shared
rg -n "LazyVStack|LazyHStack|LazyVGrid|List" App Features Shared
```

### 4.3 视觉一致性扫描

```bash
rg -n "Color\\(|\\.font\\(|\\.padding\\(|cornerRadius\\(|\\.opacity\\(" App Features Shared
rg -n "DSColor|DSSpacing|DSRadius|DSBorder|DSLineSpacing|DSOpacity|DSMotion|DSTypography|dsTextStyle|dsPrimaryCTAStyle|dsSecondaryCTAStyle|dsSurfaceCard" App Features Shared
```

### 4.4 交互与稳定性回归

```bash
xcodebuild test -project YOM.xcodeproj -scheme YOM -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YOMUITests/YOMUITests
TEST_RUNNER_STRESS_REPETITIONS=200 TEST_RUNNER_LATENCY_SAMPLES=50 xcodebuild test -project YOM.xcodeproj -scheme YOM -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YOMUITests/YOMStressTests
```

## 5. 标准产物模板（复制即用）

### 5.1 `00-component-inventory.md`

| Component | File | Layer | NativeTag | Start | End | Switch |
|---|---|---|---|---|---|---|
| MapTabRootView | Features/Map/MapTabRootView.swift | L1 Root | NativeDirect | pin/search | close/end | pinA->pinB |

### 5.2 `01-token-mapping.md`

| Component | Token Used | Hardcoded Visuals | Verdict |
|---|---|---|---|
| MapPreviewSheetView | DSSpacing/DSColor/DSRadius/DSControl | 无 | Pass |

### 5.3 `02-hierarchy-findings.md`

| Rule ID | Finding | Severity | Evidence | Fix Owner |
|---|---|---|---|---|
| HIER-001 | `navigationDestination` 放置不当 | P0/P1/P2 | file:line | @owner |

### 5.4 `03-interaction-latency-report.md`

| Flow | Samples | P50 | P95 | P99 | Max | Verdict |
|---|---|---|---|---|---|---|
| End Navigation | 50 |  |  |  |  | Pass/Fail |

## 6. 分级规则（统一风险语言）

1. P0：会导致功能不可用、链路断裂、明显卡顿/闪烁、导航错误层级。  
2. P1：功能可用但交互体验明显不达标、层级语义偏差、可回归风险高。  
3. P2：视觉一致性或可维护性问题，短期不阻断但应持续清理。

## 7. 多窗口并行执行协议（后续会话可直接粘贴）

### 窗口 A（静态清点）

“按《App本体组件层级与Token深度检索总控spec.md》执行 Step 1，仅输出 inventory 和 token mapping，不改业务代码。”

### 窗口 B（层级审计）

“按该 spec 执行 Step 2，重点检查 NavigationStack / sheet / safeArea 层级，输出 P0-P2 清单。”

### 窗口 C（视觉一致性）

“按该 spec 执行 Step 3，基于 token 覆盖率和截图差异输出视觉统一性报告。”

### 窗口 D（交互压测）

“按该 spec 执行 Step 4，跑 YOMStressTests，给出 P50/P95/P99 与门禁判定。”

## 8. 官方调研依据（Web，一手资料）

1. SwiftUI 导航数据驱动与 `navigationDestination` 层级建议（WWDC22 SwiftUI Cookbook for Navigation）：  
https://developer.apple.com/videos/play/wwdc2022/10054/  
2. iOS 导航语义：push 用于层级钻取，modal 使用边界（WWDC22 Explore navigation design for iOS）：  
https://developer.apple.com/videos/play/wwdc2022/10001/  
3. SwiftUI Sheet 相关 API：`presentationDetents`、`presentationBackgroundInteraction`：  
https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:)  
https://developer.apple.com/documentation/swiftui/presentationbackgroundinteraction  
4. 设计一致性与触控尺寸（Apple UI Design Dos and Don’ts）：  
https://developer.apple.com/design/tips/  
5. 性能排查方法（WWDC25 Optimize SwiftUI performance with Instruments）：  
https://developer.apple.com/videos/play/wwdc2025/306/  
6. UI 自动化可靠性与标识策略（WWDC25 Record, replay, and review: UI automation with Xcode）：  
https://developer.apple.com/videos/play/wwdc2025/344/  
7. 重复测试诊断不稳定问题（WWDC21 Diagnose unreliable code with test repetitions）：  
https://developer.apple.com/videos/play/wwdc2021/10296/  
8. Reduced Motion 评估标准（Apple Developer Help）：  
https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria

## 9. 执行记录

1. 2026-03-06：建立总控 spec，完成 Round-0 基线归档规则。  
2. 2026-03-06：确认当前工程为 Apple 原生 UI 栈（SwiftUI/UIKit/MapKit/CoreLocation），未引入第三方 UI 依赖。  
3. 2026-03-06：后续所有轮次统一复用本 spec，直到达到 `Pass`。
