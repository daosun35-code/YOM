# 001 预览 Sheet 空白点击关闭迟滞整改 Spec

> 目的：把“预览 Sheet 点击空白后迟滞收起”问题沉淀为可复用、可分步执行、可回归的整改规范。  
> 文档日期：2026-03-05（America/New_York）  
> 适用范围：`Features/Map/MapTabRootView.swift`、`YOMUITests/YOMUITests.swift`、`docs/app-routine.md`。

## 0. 检索标签（建议原样复用）

`preview sheet 空白点击迟钝` `tap outside dismiss lag` `sheet scrim dismiss` `presentationBackgroundInteraction` `map tap arbitration` `dismiss latency`

## 1. 问题定义（当前基线）

### PS-DISMISS-LAG-001 体感迟滞

1. 现象：预览 Sheet 打开后，点击空白区域并非“立即收起”，会出现短暂等待。  
2. 用户感知：交互反馈不确定，接近“点击未生效”。  
3. 当前实现锚点（YOM）：
- `.sheet(item: $state.previewPoint)` 承载预览 Sheet。
- `.presentationBackgroundInteraction(.enabled(upThrough: ...))` 允许背景交互。
- 关闭链路为 `TapGesture -> handleMapBackgroundTap() -> dismissPreview()`，由地图容器手势承接而非 scrim 直连。

## 2. 行业对标结论（官方来源）

### 2.1 模态底部 Sheet 的主流默认：空白点击直接 dismiss

1. Flutter `showModalBottomSheet`：
- `isDismissible` 默认 `true`，用于“点 scrim 关闭”。
- `enableDrag` 默认 `true`，用于下滑关闭。  
来源：https://api.flutter.dev/flutter/material/showModalBottomSheet.html

2. Android Compose `ModalBottomSheetProperties`：
- `shouldDismissOnClickOutside` 默认 `true`。
- `shouldDismissOnBackPress` 默认 `true`。  
来源：https://developer.android.com/reference/kotlin/androidx/compose/material3/ModalBottomSheetProperties

3. Android Compose `ModalBottomSheet`：
- `onDismissRequest` 作为统一关闭入口。
- `SheetState.show/hide` 作为状态真源。  
来源：https://developer.android.com/develop/ui/compose/components/bottom-sheets

### 2.2 地图场景的主流默认：空白点按用于“取消临时选中态”

1. Google Maps iOS `didTapAtCoordinate`：仅在未点中 marker 时触发，且会先于默认取消选中行为。  
来源：https://developers.google.com/maps/documentation/ios-sdk/reference/objc/Protocols/GMSMapViewDelegate

2. Leaflet：`closePopupOnClick` 默认 `true`。  
来源：https://leafletjs.com/reference

3. MapLibre GL JS：`PopupOptions.closeOnClick` 默认 `true`。  
来源：https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/PopupOptions/

### 2.3 Apple 平台可用能力边界

1. SwiftUI `presentationBackgroundInteraction` 支持 `disabled / enabled / enabled(upThrough:)`。  
来源：https://developer.apple.com/documentation/swiftui/presentationbackgroundinteraction
2. `presentationDetents` 可声明分层高度语义。  
来源：https://developer.apple.com/documentation/swiftui/view/presentationdetents%28_%3A%29

## 3. 根因推断（基于代码与对标）

> 以下为工程推断，不是官方文档原文。

1. 当前关闭动作由地图层 `TapGesture` 触发，需先经过地图手势体系仲裁（拖拽/缩放/双击等）。
2. 手势识别完成后才会走 `dismissPreview()`，再叠加系统收起动画，形成“慢半拍”体感。
3. 当背景交互开启时，这种仲裁成本更容易暴露；而 scrim 直连 dismiss 通常反馈更确定。

## 4. 目标态（完成标准）

1. 点击空白关闭预览在主观体感上“即时可感知”。
2. 点击空白与点击 pin 的语义分流明确：
- 点击 pin：切换或打开预览。
- 点击空白：关闭当前预览。
3. 关闭入口统一：空白点击、下滑、Close 按钮落到同一状态机出口（`previewPoint = nil`）。
4. 不引入“关闭后补弹”或“先关后开闪烁”回归。

## 5. 推荐方案与备选方案

### 方案 A（推荐，稳定优先）：Scrim First

1. 预览态关闭交由系统 sheet 的 scrim + 下滑手势承接。
2. 预览态禁用背景交互（或至少在紧凑 detent 禁用），避免地图手势仲裁进入关闭主链路。
3. 保留显式 `Close` 按钮作为兜底。

适用：优先保证关闭反馈稳定与一致性。

### 方案 B（备选，地图交互优先）：Map Delegate First

1. 保留背景可交互。
2. 关闭动作改由地图 SDK 的“空白点击回调”承接（非通用容器 `TapGesture`）。
3. 所有关闭入口统一写回同一 dismiss 状态。

适用：必须在预览态持续保留地图可操作性时。

### 方案 C（混合）：按 detent 分流

1. 紧凑态使用方案 A（优先快速关）。
2. 大卡态使用方案 B（允许更强地图交互）。

适用：既要紧凑态效率，也要展开态操作自由。

## 6. 分步执行协议（供其他会话直接开工）

> 规则：一步一提交；每步只改允许文件；不得跨步夹带。

### Step 1（状态链路收敛）

- 目标：把“关闭”统一到单一状态出口。  
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
- 必做事项：
1. 盘点并收敛所有关闭入口到 `dismissPreview()` 或同一等价函数。  
2. 删除/降级地图容器层与关闭相关的重复触发路径。  
- DoD：
1. 关闭逻辑只有一条真源，不存在并行分叉。

### Step 2（落地推荐方案）

- 目标：消除“空白点击迟滞”体感。  
- 允许改动文件：
1. `Features/Map/MapTabRootView.swift`
- 必做事项：
1. 按方案 A 实施：紧凑态关闭交由系统 scrim 承接，不再依赖地图层 tap 仲裁。  
2. 保留 `Close` 与下滑关闭语义。  
3. 校验点 pin 切换不出现“先关后开闪烁”。  
- DoD：
1. 点击空白收起反馈稳定且无明显等待。

### Step 3（测试加固）

- 目标：把“迟滞”问题固化为可回归断言。  
- 允许改动文件：
1. `YOMUITests/YOMUITests.swift`
- 必做事项：
1. 现有 `testPreviewTapOutsideDismissesSheet` 补充更严格时序断言（例如更短超时窗口）。  
2. 增加 `Close` 与空白点击的一致性断言（两者均可稳定收起）。  
3. 增加“点击 pin 切换目标时不闪烁”的回归用例。  
- DoD：
1. 新增/更新用例稳定通过，且能覆盖本问题。

### Step 4（文档对齐）

- 目标：确保实现、测试、文档一致。  
- 允许改动文件：
1. `docs/app-routine.md`
2. `specs/001-ui-pattern-conformance/spec.md`（仅执行记录）
- 必做事项：
1. 明确“Tap outside”触发路径与关闭语义。  
2. 记录采用方案（A/B/C）与未采纳方案理由。  
- DoD：
1. 新会话可仅凭文档复现正确设计意图。

## 7. 验收模板（每步统一）

1. 功能：是否达到本步目标交互。  
2. 稳定性：是否消除迟滞、补弹、闪烁回归。  
3. 可访问性：关闭入口是否可发现、可点击、可读。  
4. 回归：是否新增/更新至少 1 条自动化断言。

## 8. 非目标（本轮不做）

1. 不改路线规划算法、ETA、导航任务计算。
2. 不重做地图视觉皮肤。
3. 不扩展到 Archive/Settings 页。

## 9. 可复制执行指令（给后续会话）

### 会话 A（Step 1）
“按 `预览Sheet空白点击关闭迟滞整改spec.md` 的 Step 1 执行：收敛关闭状态链路，只改允许文件，回传状态机前后对比与风险。”

### 会话 B（Step 2）
“按 Step 2 执行方案 A：把紧凑态空白关闭改为 scrim 主链路，避免地图 tap 仲裁；回传代码锚点与交互对比。”

### 会话 C（Step 3）
“按 Step 3 补齐 UI Test：收紧空白关闭时序断言，并新增 pin 切换不闪烁回归。”

### 会话 D（Step 4）
“按 Step 4 做文档对齐：更新 `app-routine` 与总控 spec 执行记录，回传差异摘要。”

## 10. 资料清单（审计留痕）

1. Apple SwiftUI `PresentationBackgroundInteraction`：
https://developer.apple.com/documentation/swiftui/presentationbackgroundinteraction
2. Apple SwiftUI `presentationDetents(_:)`：
https://developer.apple.com/documentation/swiftui/view/presentationdetents%28_%3A%29
3. Android Compose Bottom sheets：
https://developer.android.com/develop/ui/compose/components/bottom-sheets
4. Android Compose `ModalBottomSheetProperties`：
https://developer.android.com/reference/kotlin/androidx/compose/material3/ModalBottomSheetProperties
5. Flutter `showModalBottomSheet`：
https://api.flutter.dev/flutter/material/showModalBottomSheet.html
6. Google Maps iOS `GMSMapViewDelegate`：
https://developers.google.com/maps/documentation/ios-sdk/reference/objc/Protocols/GMSMapViewDelegate
7. Leaflet Reference：
https://leafletjs.com/reference
8. MapLibre `PopupOptions`：
https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/PopupOptions/
