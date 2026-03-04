# 001 地图预览 Sheet「紧凑高度排版错位」审计 Spec

> 目的：沉淀“Map 预览 Sheet 在不同状态下排版错位/压底”的可检索规范，用于后续对话快速判断是否出现同类问题。  
> 审计日期：2026-03-04（America/New_York）  
> 适用范围：`Features/Map/MapTabRootView.swift`、`YOMUITests/YOMUITests.swift`。

## 0. 检索标签（建议原样复用）

`预览Sheet排版错位` `按钮不规范` `主按钮窄胶囊` `次级按钮贴底` `0.33 detent` `changeDestinationHint 挤压` `map_preview_primary_action` `map_preview_secondary_details` `map_preview_close_action`

## 1. 问题定义

本 Spec 聚焦 `MapPreviewSheetView` 在“紧凑 detent”下的排版失衡：
1. 主按钮与次级动作行出现异常断层，视觉重心失衡。
2. 次级动作行（`查看详情` / `关闭`）被挤压到 Tab Bar 区域附近，出现“贴底/压底”观感。
3. 在“更改目的地”状态（含额外 hint 文案）下，问题会更明显。

## 1.1 问题本体快照（现象证据）

1. 视觉现象 A：主 CTA（蓝色）呈现“窄胶囊”而非预期的强主按钮宽度。
2. 视觉现象 B：`查看详情` / `关闭` 行接近底部系统栏，形成“贴底+层级断裂”观感。
3. 视觉现象 C：在“更改目的地”态，由于新增说明文案，动作区挤压更明显。

本地运行态（iPhone 17 Pro，模拟器）观测样例：
1. `map_preview_secondary_details`：`y≈774, h≈42`
2. `Tab Bar` 顶部：`y=791`
3. 结论：次级动作行在视觉上与底栏区域过近，属于高风险布局。

## 2. 触发状态（可复现）

### PS-LAYOUT-001 默认预览态
- 状态：`previewPoint != nil && navigationPoint == nil`
- 现象：主按钮位置偏上，次级动作行靠近底部系统区域。

### PS-LAYOUT-002 导航中改目的地态
- 状态：`previewPoint != nil && navigationPoint != nil`
- 现象：在 PS-LAYOUT-001 基础上再叠加一行 `changeDestinationHint`，可用高度更紧张，错位更显著。

## 3. 因果链（问题本身 + 触发机制）

### C-001 固定紧凑高度触发“可用空间不足”
- 原因：预览 Sheet 紧凑态被固定为 `0.33`，且选点后总是回落到该 detent。  
- 代码锚点：`previewSheetDetent`、`previewSheetCompactDetent = .fraction(0.33)`、`onChange(of: state.previewPoint?.id)`。  
- 文件：`Features/Map/MapTabRootView.swift`（约 164、187-192、378-380 行）。
- 结果：底部卡片在小高度下长期承载完整内容，压缩裕量不足。

### C-002 内容体量超出紧凑态预算
- 原因：紧凑态仍渲染标题区 + 摘要 + 分割线 + 三动作（主/详情/关闭）+ 底部 padding。  
- 代码锚点：`actionSection`、`primaryActionButton`、`secondaryActionButton`、`closeActionButton`。  
- 文件：`Features/Map/MapTabRootView.swift`（约 925-983 行）。
- 结果：主次动作之间出现异常空洞，次级动作行被推向底部区域。

### C-003 导航中附加文案放大挤压效应
- 原因：`isChangingDestination == true` 时额外渲染 `changeDestinationHint`。  
- 代码锚点：`if isChangingDestination { Text(changeDestinationHint) }`。  
- 文件：`Features/Map/MapTabRootView.swift`（约 912-916 行）。
- 结果：同一 detent 下可用高度进一步减少，PS-LAYOUT-002 比 PS-LAYOUT-001 更易失衡。

### C-004 主按钮“窄胶囊观感”来自样式实现方式
- 原因：`DSPrimaryCTAButtonStyle` 在样式内部按 label 的内在宽度绘制背景，未在样式内扩展横向填充。  
- 代码锚点：`configuration.label ... .padding(.horizontal, ...) .background(...)`。  
- 文件：`Shared/DesignSystem/DSStyles.swift`（约 7-21 行）。
- 结果：即使外层设置了 `maxWidth`，视觉上仍可能出现主按钮不够“主操作”的窄按钮观感。

### C-005（推断）缺少内容滚动兜底
- 原因：Sheet 层设置了 `.presentationContentInteraction(.scrolls)`，但 `MapPreviewSheetView` 本体为 `VStack`，不是滚动容器。  
- 代码锚点：`.presentationContentInteraction(.scrolls)` 与 `MapPreviewSheetView` `VStack` 根容器。  
- 文件：`Features/Map/MapTabRootView.swift`（约 240、888-922 行）。
- 结果：在紧凑 detent 下，内容无法通过内部滚动有效“让位”，更容易演化为贴底错位。

## 4. 行业对标（审计依据）

1. Apple：Bottom sheet 应使用可调整 detents，并结合内容高度/交互选择合适展示层级。  
https://developer.apple.com/videos/play/wwdc2021/10063/  
https://developer.apple.com/documentation/swiftui/view/presentationdetents%28_%3A%29

2. Apple：sheet 的内容交互和展示高度要协同设计，避免出现内容可达性问题。  
https://developer.apple.com/videos/play/wwdc2022/10068/  
https://developer.apple.com/documentation/swiftui/view/presentationcontentinteraction(_:)

3. Material：部分展开 bottom sheet 需允许用户上拉展开，不建议把复杂动作长期压在最小态。  
https://developer.android.com/develop/ui/compose/components/bottom-sheets-partial

4. Flutter：`showModalBottomSheet` 的默认关闭/拖拽语义强调“容器状态与内容复杂度匹配”。  
https://api.flutter.dev/flutter/material/showModalBottomSheet.html

## 5. 快速检索清单（后续对话可直接复用）

```bash
# A. 检索固定紧凑 detent
rg -n "previewSheetCompactDetent|fraction\\(0\\.33\\)|presentationDetents" Features/Map/MapTabRootView.swift

# B. 检索预览动作区复杂度（三动作结构）
rg -n "actionSection|map_preview_primary_action|map_preview_secondary_details|map_preview_close_action" Features/Map/MapTabRootView.swift YOMUITests/YOMUITests.swift

# C. 检索导航中额外文案导致的高度增长
rg -n "isChangingDestination|changeDestinationHint" Features/Map/MapTabRootView.swift

# D. 检索是否有“紧凑态排版稳定性”自动化覆盖
rg -n "testMapPinPreviewUsesOneThirdDetent|preview|sheet" YOMUITests/YOMUITests.swift
```

## 6. 判定规则（审计口径）

满足以下任一条即判定为“同类问题”：
1. 预览卡长期固定在 `<= 0.33` detent，且动作区含两个以上次级动作入口。
2. 在任一语言/状态下，次级动作行的 `frame` 与 Tab Bar 区域发生重叠或视觉压底。
3. 导航中附加文案后，主/次动作之间出现明显异常空洞，导致信息层级失衡。
4. 主 CTA 呈现明显窄胶囊观感，未体现“单一主操作”视觉优先级。

## 7. 整改建议（供后续任务引用）

1. detent 策略改为“内容感知”：避免固定 `0.33` 作为唯一紧凑态。
2. 紧凑态动作减负：只保留主 CTA，把次级操作收敛到上拉后或更多操作入口。
3. 预览内容容器具备可滚动兜底，确保在中文与大字体下动作可达。
4. 为两种状态分别建立 UI 回归断言，避免“默认态通过、导航态回归”。

## 8. 验收标准（DoD）

1. 在 PS-LAYOUT-001 与 PS-LAYOUT-002 下，动作区不与 Tab Bar 视觉重叠。  
2. 主 CTA 与次级操作间距稳定，不出现异常空白断层。  
3. 关键触控目标保持 `>= 44x44`。  
4. UI 自动化至少覆盖 1 条“紧凑态排版稳定性”断言。  

## 9. 当前基线记录（2026-03-04）

1. 现实现存在固定 `0.33` detent + 三动作结构。  
2. 已观察到“次级动作行贴近 Tab Bar”的排版风险。  
3. 已观察到主 CTA 的“窄胶囊观感”，与主操作视觉权重不匹配。  
4. 本 Spec 建立后，后续窗口可直接按第 0/5/6 节进行关键词检索与同类判定。  
