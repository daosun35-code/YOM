# 001 地图预览「空白点击关闭」交互对标 Spec

> 目的：将“点击 pin 后出现预览 Sheet，点击空白应关闭”沉淀为可检索规范，用于后续对话快速盘点当前 App 尚未采用该交互的页面。  
> 检索关键词：`tap outside dismiss` `map preview dismiss` `sheet background interaction` `closeOnClick` `isDismissible` `didTapAtCoordinate`

## 1. 问题定义

本 Spec 聚焦地图预览态中的“退出手势语义”：
1. 用户点击地图 pin 进入预览态后，应存在低成本、直觉化退出路径。
2. “点击空白关闭预览”需与地图选点行为共存，避免误触和语义冲突。
3. 规范要可被 `rg` 快速检索，以便持续审计全局一致性。

## 2. 行业对标结论（可审计来源）

### 2.1 模态底部卡片：点击背景关闭是主流默认

1. Flutter `showModalBottomSheet`：`isDismissible` 控制“点击 scrim 是否关闭”，默认 `true`；`enableDrag` 控制下滑关闭。  
来源：https://api.flutter.dev/flutter/material/showModalBottomSheet.html
2. Jetpack Compose `ModalBottomSheet`：通过 `onDismissRequest` 统一承接用户关闭动作，官方示例给出下滑关闭路径。  
来源：https://developer.android.com/develop/ui/compose/components/bottom-sheets-partial

### 2.2 地图浮层：点击空白用于清除临时选中态是常见语义

1. Google Maps iOS SDK：`didTapAtCoordinate` 在“无 marker 的坐标点击”触发，文档明确该行为也会触发当前 marker 的隐式取消选中。  
来源：https://developers.google.com/maps/documentation/ios-sdk/reference/objc/Protocols/GMSMapViewDelegate
2. Leaflet：`closePopupOnClick` 默认 `true`，点击地图会关闭 popup。  
来源：https://leafletjs.com/reference
3. MapLibre GL JS：`PopupOptions.closeOnClick` 默认 `true`。  
来源：https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/PopupOptions/

### 2.3 兜底原则：显式关闭入口仍需保留

1. Apple Maps 用户手册中的 Place Card 提供显式关闭入口（Close）。  
来源：https://support.apple.com/lt-lt/guide/ipod-touch/iph8c9c2528b/ios

## 3. YOM 交互规范（新增规则）

### MAP-DISMISS-001：预览态必须可快速退出

- 场景：Map pin 打开预览 Sheet（`previewPoint != nil`）。
- 要求：至少支持以下两种退出路径：
1. 点击空白区域关闭（scrim 或地图空白）。
2. 下滑关闭（系统 Sheet 默认手势）。

### MAP-DISMISS-002：空白点击与“点新 pin”语义分流

- 点击新 pin：切换目标并更新预览内容，不先执行“关闭再打开”的闪烁路径。
- 点击空白地图：关闭当前预览，并清空当前选中高亮。

### MAP-DISMISS-003：地图操作手势不得误关

- 地图拖拽、缩放、旋转不应触发预览关闭。
- 仅“离散点击空白”触发关闭逻辑。

### MAP-DISMISS-004：保留显式关闭兜底

- 即使支持空白点击关闭，仍建议保留可见关闭入口（例如关闭按钮或明确手势提示），保障可发现性与可访问性。

## 4. 当前代码基线（2026-03-04）

### 4.1 已有能力

1. 预览 Sheet 存在：`MapTabRootView` 使用 `.sheet(item: $state.previewPoint)`。  
锚点：`Features/Map/MapTabRootView.swift`
2. 已有关闭状态函数：`dismissPreview()` 会将 `previewPoint = nil`。  
锚点：`Features/Map/MapTabRootView.swift`

### 4.2 缺口（当前 App 还没用到的地方）

1. **GAP-MD-001（Map 预览空白点击关闭未接线）**  
`dismissPreview()` 当前未被 UI 事件调用；未见“点击地图空白 -> dismissPreview”闭环。
2. **GAP-MD-002（预览 Sheet 开启背景交互但未定义空白点击策略）**  
预览 Sheet 使用 `.presentationBackgroundInteraction(.enabled(upThrough: ...))`，当前实现未显式定义“背景点击时关闭还是透传”策略。
3. **GAP-MD-003（测试缺口）**  
`YOMUITests` 目前有“点 pin 打开预览”“点详情进入详情 Sheet”等测试，但没有“点击空白关闭预览”的断言用例。

## 5. 快速检索清单（给后续对话直接复用）

```bash
# A. 找所有底部容器与关闭相关配置
rg -n "\\.sheet\\(|\\.fullScreenCover\\(|presentationBackgroundInteraction|presentationDetents|onDismiss" Features

# B. 找“有状态函数但未接线”的预览关闭逻辑
rg -n "func dismissPreview|dismissPreview\\(" Features/Map/MapTabRootView.swift

# C. 找地图点击相关逻辑（排查空白点击是否承接 dismiss）
rg -n "Map\\(|Annotation\\(|onTapGesture|previewPoint|selectPoint\\(" Features/Map/MapTabRootView.swift

# D. 找测试是否覆盖“空白点击关闭”
rg -n "preview|dismiss|tap outside|map_preview" YOMUITests

# E. 找文档与实现是否存在“Tap outside”偏差
rg -n "Tap outside|tap outside|Dismiss|dismiss preview" docs specs
```

## 6. 验收标准（用于后续补齐任务）

1. 功能：点击 pin 打开预览后，点击空白可关闭预览。
2. 稳定性：点新 pin 不触发先关后开闪烁，直接切换目标内容。
3. 可访问性：不影响现有主 CTA（`Go/Change Destination`）和详情入口可达性。
4. 回归：新增 UI Test 覆盖“打开预览 -> 点击空白 -> 预览消失”链路。

