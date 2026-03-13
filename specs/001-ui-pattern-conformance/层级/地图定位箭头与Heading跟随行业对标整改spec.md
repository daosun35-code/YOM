# 001 地图定位箭头与 Heading 跟随行业对标整改 Spec

> 目的：基于 Apple / Mapbox / Google 官方资料，对当前地图页“自己点位箭头朝向 + 相机跟随 heading”能力做行业级对标，明确当前实现差距，并给出可分步落地的整改路径。  
> 文档日期：2026-03-13（America/New_York）  
> 适用范围：`Features/Map/MapTabRootView.swift`、`Features/Map/MapScreenState.swift`、`Features/Map/UserLocationProvider.swift`。  
> 方法约束：优先采用官方一手资料；本文中的“目标状态机设计”“阈值建议”属于基于官方能力的工程推断，不冒充平台原生强约束。

## 1. 问题范围

当前地图页已经具备：

1. 用户点位自定义渲染。
2. heading 存在时显示箭头、无 heading 时显示蓝点。
3. `Locate Me` 可进入一次 `followsHeading: true` 的用户位置相机。

但当前实现仍停留在“基础版定位跟随”，尚未达到行业里成熟地图/导航产品的标准形态。缺口主要集中在：

1. 缺少显式相机跟随状态机。
2. 缺少“用户拖图退出跟随”后的业务层状态同步。
3. bearing 仅用 heading，未结合 course / speed。
4. 没有对 heading 质量和 Reduced Accuracy 做治理。
5. 定位与 heading 更新启停过粗，功耗策略不足。

## 2. 当前实现快照（代码审计）

### 2.1 用户点位箭头如何工作

1. 地图使用 `UserAnnotation(anchor: .center)` 自绘用户点位。  
2. `CurrentUserLocationAnnotationView` 在 `headingDegrees != nil` 时显示 `location.north.fill`，并通过 `.rotationEffect(.degrees(headingDegrees))` 旋转；否则退化为纯蓝点。  
3. `headingDegrees` 优先取 `UserAnnotation` 回调里的 `userLocation.heading`，拿不到时 fallback 到 `UserLocationProvider.headingDegrees`。

代码锚点：

1. `Features/Map/MapTabRootView.swift` 中 `UserAnnotation`：约 365 行。  
2. `Features/Map/MapTabRootView.swift` 中 `resolvedUserHeadingDegrees(...)`：约 764 行。  
3. `Features/Map/MapTabRootView.swift` 中 `CurrentUserLocationAnnotationView`：约 1078 行。

### 2.2 heading 数据如何进入 UI

1. `UserLocationProvider` 在授权后调用 `startUpdatingLocation()`。  
2. 若 `CLLocationManager.headingAvailable()` 为真，则同时调用 `startUpdatingHeading()`。  
3. `headingFilter = 5`，即角度变化不足约 5 度时不触发新 heading。  
4. heading 解析顺序为：优先 `trueHeading`，否则 `magneticHeading`。

代码锚点：

1. `Features/Map/UserLocationProvider.swift` 中 `startIfAuthorized()`：约 29 行。  
2. `Features/Map/UserLocationProvider.swift` 中 `locationManager(_:didUpdateHeading:)`：约 102 行。  
3. `Features/Map/UserLocationProvider.swift` 中 `resolvedHeading(from:)`：约 117 行。

### 2.3 相机什么时候开始跟随 heading

1. 显式入口只有 `handleLocateMeAction()`。  
2. 点击 `Locate Me` 后，若已有坐标，则直接进入 `MapCameraPosition.userLocation(followsHeading: true, fallback: ...)`。  
3. 若还没有坐标，则先记住 `shouldCenterOnNextLocationUpdate = true` 和 `shouldFollowHeadingOnNextLocationUpdate = true`，等第一条坐标回来时再进入 heading-follow。

代码锚点：

1. `Features/Map/MapTabRootView.swift` 中 `handleLocateMeAction()`：约 600 行。  
2. `Features/Map/MapTabRootView.swift` 中 `handleLocationCoordinateChange(...)`：约 734 行。  
3. `Features/Map/MapScreenState.swift` 中 `followUserLocation(followsHeading:fallbackCoordinate:)`：约 62 行。

### 2.4 相机什么时候不会跟随 heading

1. 首次自然拿到定位时，只做一次居中，不进入 heading-follow。  
2. 点 pin 时，相机改写为 `.region(...)`。  
3. 选搜索结果时，相机改写为 `.region(...)`。  
4. 路线算出后，相机改写为 `.rect(...)` 的整路线总览。  
5. 结束导航只清业务状态，不会自动回到 follow 模式。

代码锚点：

1. `Features/Map/MapTabRootView.swift` 中首次定位只传 `followsHeading: false`：约 750 行。  
2. `Features/Map/MapScreenState.swift` 中 `selectPoint(...)`：约 81 行。  
3. `Features/Map/MapScreenState.swift` 中 `selectSearchPlace(...)`：约 100 行。  
4. `Features/Map/MapScreenState.swift` 中 `focusOnRoute(...)`：约 145 行。

### 2.5 当前缺失点

1. 没有显式 `trackingMode` / `cameraMode` 状态枚举。  
2. 没有 `onMapCameraChange` 或 `positionedByUser` 消费逻辑。  
3. 没有 `stopUpdatingLocation()` / `stopUpdatingHeading()`。  
4. 没有使用 `CLLocation.course`、`speed`、`headingAccuracy`、`accuracyAuthorization`。  
5. 没有针对“用户拖图后退出跟随”显示 Recenter 的业务层处理。

## 3. 行业级最佳方案（官方资料归纳）

### 3.1 相机必须是显式状态机，而不是隐式布尔拼接

行业产品通常至少区分：

1. `free`：用户自由浏览地图。  
2. `follow`：相机跟随用户。  
3. `overview`：展示整段路线或目标上下文。  

Google Navigation SDK 直接把相机模式定义为 `following`、`overview`、`free`，并明确说明用户 pan / zoom 会自动进入 `free`，同时显示 Re-center 按钮返回 `following`。  
Mapbox Viewport 也把 `follow puck` 与 `overview` 视为两个核心状态，并提供从手势触发的状态切换。  
Apple MapKit for SwiftUI 虽未给出完整状态机实现，但 `MapCameraPosition.positionedByUser` 与 WWDC 示例明确表明：相机是否被用户手动操控，应成为一等信息。

### 3.2 bearing 源应在 heading 与 course 间切换

Apple 官方将 heading 和 course 明确区分：

1. `heading` 表示设备朝向。  
2. `course` 表示移动方向。  

Apple 文档明确指出：导航类 App 可以根据当前速度在二者之间切换，步行时 heading 更有用，车行时 course 更有用。  
Mapbox 也把 puck bearing source 拆成 `.heading` 与 `.course` 两种，并允许 viewport bearing 跟随其一。

### 3.3 跟随状态退出后，需要给用户明确“回到跟随”的入口

Google 官方明确建议：

1. 用户拖图后退出 follow，进入 `free`。  
2. 此时显示 Re-center 按钮。  
3. 需要时甚至可用 timer 自动回到 `following`。  

Mapbox 的 follow/overview 示例也是同一路径。  
Apple 在 WWDC23 的 MapKit for SwiftUI 演示中也强调：当用户交互地图后，相机位置会体现为 `positionedByUser`，App 可再把它设回 `userLocation`。

### 3.4 heading 不是“有值就可信”，需要做质量门控

Apple 在 heading 文档中明确指出：

1. 处理 heading 前应检查 `headingAccuracy`。  
2. 当 `headingAccuracy < 0` 时，不应使用该 heading。  
3. 若要依赖 true heading，通常需要同时启用位置更新。

因此导航 UI 不应在低可信度 heading 下继续展示“确定方向”的箭头。

### 3.5 定位与 heading 更新应按场景启停

Apple Energy Guide 明确建议：

1. 仅需要一次定位时优先 `requestLocation()`。  
2. 非 turn-by-turn 导航类 App，不应长期开启标准定位。  
3. 不需要时应及时 `stopUpdatingLocation()`。  
4. 应根据业务设置 `desiredAccuracy`、`distanceFilter`、`activityType`。  
5. 后台持续定位时，应结合 `pausesLocationUpdatesAutomatically` 等节能配置。

### 3.6 精确定位权限要纳入产品设计

Apple Core Location 现在把 `accuracyAuthorization` 单独暴露，并支持 `requestTemporaryFullAccuracyAuthorization(withPurposeKey:)`。  
这意味着：“App 已拿到 while-in-use 授权”不等于“App 拿到了足够精度的定位数据”。  
如果业务依赖接近解锁、近距离判定、到点触发，Reduced Accuracy 需要显式治理。

## 4. 当前实现与行业最佳方案的差距

### GAP-001 缺少显式相机状态机

当前问题：

1. 只在局部用 `shouldCenterOnNextLocationUpdate` / `shouldFollowHeadingOnNextLocationUpdate` 承接一次性行为。  
2. 没有可观察的 `free / follow / overview` 业务状态。  

影响：

1. 无法稳定表达“当前是跟随中、概览中、还是用户自由浏览中”。  
2. 很难在 UI 上正确决定是否显示 Recenter、是否允许自动回到跟随。

### GAP-002 没消费用户拖图退出跟随的信号

当前问题：

1. 代码未读取 `positionedByUser`。  
2. 代码未用 `onMapCameraChange` 观察相机变化。  

影响：

1. MapKit 内部可能已经退出用户跟随，但业务层并不知道。  
2. 当前 UI 无法稳定提示“你已脱离跟随模式”。

### GAP-003 导航态只有路线总览，没有 follow 导航态

当前问题：

1. 路线计算完成后直接 `focusOnRoute()`。  
2. 相机转成 `.rect(...)` 总览后，不会自动回到用户跟随。  

影响：

1. 更像“看路线”，不像“跟着人走”。  
2. 对步行/到点引导体验不够强。

### GAP-004 bearing 只用 heading，没做 heading/course 策略

当前问题：

1. 箭头旋转完全基于 heading。  
2. 没有结合 `CLLocation.course` 与 `speed`。  

影响：

1. 高速移动时方向可能不稳。  
2. 车行、骑行、快速步行时体验不如行业成熟方案。

### GAP-005 没有 heading 质量降级

当前问题：

1. 当前只校验 heading 是否为负值。  
2. 没有把 `headingAccuracy` 纳入决策。  

影响：

1. 低质量 heading 仍可能驱动箭头旋转。  
2. 用户会看到“方向在跳，但不可信”。

### GAP-006 功耗策略偏重

当前问题：

1. 默认 `desiredAccuracy = kCLLocationAccuracyBest`。  
2. 授权后直接常驻 `startUpdatingLocation()` 和可能的 `startUpdatingHeading()`。  
3. 没有 stop 路径。  

影响：

1. 浏览态功耗偏高。  
2. 会把 turn-by-turn 才应承担的成本带到普通地图浏览态。

### GAP-007 Reduced Accuracy / 全局定位关闭分支未收口

当前问题：

1. 只处理 App 级授权状态。  
2. 没有先检查 `locationServicesEnabled()`。  
3. 没有处理 `accuracyAuthorization`。  

影响：

1. 用户可能已关闭系统级定位，但当前错误引导仍偏向“去设置打开 App 权限”。  
2. 用户给了 Approximate 位置时，解锁/到点能力可能悄悄失效。

## 5. 目标态（建议的工程设计）

### 5.1 建议新增统一相机状态

建议新增：

```swift
enum MapTrackingMode: Equatable {
    case free
    case followNorthUp
    case followBearing
    case routeOverview
}
```

说明：

1. `free`：用户浏览地图，允许任意手势。  
2. `followNorthUp`：以用户位置为中心，但地图朝北。  
3. `followBearing`：以用户位置为中心，地图或相机朝向随 bearing。  
4. `routeOverview`：看路线全局。  

此状态机是基于 Apple / Mapbox / Google 官方能力做的工程抽象，不是平台强制 API。

### 5.2 建议把“用户点位朝向”和“相机跟随朝向”拆开管理

建议区分：

1. `userMarkerBearing`：只控制点位箭头朝向。  
2. `cameraTrackingMode`：只控制地图相机。  

这样即便用户拖图退出相机跟随，点位箭头依然可以继续转，产品语义会更清楚。

### 5.3 建议的 bearing 策略

建议：

1. 步行或低速时，优先使用 `heading`。  
2. 当速度持续超过阈值时，改用 `course`。  
3. 当 `headingAccuracy` 过差或 heading 无效时，隐藏箭头或降级到蓝点。  

建议阈值：

1. 初始可以从 `speed >= 1.5 ~ 2.0 m/s` 切 `course` 开始。  
2. 该阈值需结合真机步行测试再收口。  

该阈值属于工程建议，不是官方硬编码阈值。

### 5.4 建议的导航相机策略

建议导航态支持双模式：

1. `routeOverview`：展示整条路线。  
2. `followBearing`：回到以用户为主的跟随视角。  

典型交互：

1. 刚进入导航时先给一次 overview。  
2. 用户点 Recenter 或短延时后回到 follow。  
3. 用户拖图则切回 `free`。  
4. 顶部或浮层显示“回到跟随”入口。  

### 5.5 建议的定位更新治理

建议拆成三档：

1. 浏览默认态：优先 `requestLocation()` 或低频标准定位。  
2. follow 态：开启标准定位；按是否需要箭头决定是否开 heading。  
3. 主动导航态：高精度持续定位 + bearing 更新；退出导航及时 stop。  

## 6. 整改优先级

### P0 必做

1. 引入显式 `MapTrackingMode`。  
2. 接入 `positionedByUser` / `onMapCameraChange`，完成用户拖图退出跟随。  
3. 增加 Recenter 入口。  
4. 增加 `stopUpdatingLocation()` / `stopUpdatingHeading()` 管理。  

### P1 应做

1. 引入 heading / course 双源 bearing。  
2. 加入 `headingAccuracy` 质量门控。  
3. 导航态支持 `routeOverview <-> followBearing` 双模式。  
4. 加入 `locationServicesEnabled()` 和 `accuracyAuthorization` 分支处理。

### P2 可做

1. 针对导航态增加自动回到 follow 的定时器策略。  
2. 针对 follow 模式调整用户点位在屏幕中的视觉位置。  
3. 评估是否切换到系统 `LocationButton` 或借鉴其权限引导模式。

## 7. 验收标准

### FUNC-001 跟随状态正确

1. 点击 `Locate Me` 后，相机进入 `followBearing` 或 `followNorthUp`。  
2. 用户拖图后，状态切到 `free`。  
3. 点击 Recenter 后，状态回到跟随。  

### FUNC-002 箭头策略正确

1. heading 有效且精度足够时显示箭头。  
2. heading 无效或精度过差时退化为蓝点。  
3. 高速移动时可切 course，方向不抖。

### FUNC-003 导航相机正确

1. 进入导航可看 overview。  
2. 之后可一键回到 follow。  
3. 用户拖图后不会被业务状态“误认为还在跟随”。

### PERF-001 功耗合理

1. 默认地图浏览态不再长期常驻最高精度定位。  
2. 退出 follow / 导航后，定位与 heading 更新能回落或停止。

### PERM-001 权限体验完整

1. 系统级定位关闭、App 权限拒绝、Reduced Accuracy 三条链路能区分。  
2. 需要精确定位时，有明确升级提示或临时 Full Accuracy 入口。

## 8. 参考资料（官方）

### Apple

1. MapKit for SwiftUI / WWDC23  
   https://developer.apple.com/videos/play/wwdc2023/10043/
2. `MapCameraPosition.fallbackPosition`（同页可见 `positionedByUser`）  
   https://developer.apple.com/documentation/mapkit/mapcameraposition/fallbackposition
3. Core Location `CLLocationManager`  
   https://developer.apple.com/documentation/corelocation/cllocationmanager
4. Getting the Heading and Course of a Device  
   https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/LocationAwarenessPG/GettingHeadings/GettingHeadings.html
5. Reduce Location Accuracy and Duration  
   https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/LocationBestPractices.html
6. `requestTemporaryFullAccuracyAuthorization(withPurposeKey:)`  
   https://developer.apple.com/documentation/corelocation/cllocationmanager/requesttemporaryfullaccuracyauthorization(withpurposekey:)
7. WWDC21 认识位置按钮  
   https://developer.apple.com/videos/play/wwdc2021/10102/

### Mapbox

1. User Location Guide  
   https://docs.mapbox.com/ios/maps/guides/user-location/
2. Viewport Guide / 示例  
   https://docs.mapbox.com/ios/maps/guides/camera-and-animation/viewport/  
   https://docs.mapbox.com/ios/maps/examples/viewport/
3. `PuckBearing` / `PuckBearingSource` / `FollowPuckViewportStateBearing`  
   https://docs.mapbox.com/ios/maps/api/10.16.1/Enums/PuckBearing.html  
   https://docs.mapbox.com/ios/maps/api/10.13.0/Enums/PuckBearingSource.html  
   https://docs.mapbox.com/ios/maps/api/10.16.2/Enums/FollowPuckViewportStateBearing.html

### Google

1. Navigation SDK for iOS - Adjust the camera  
   https://developers.google.com/maps/documentation/navigation/ios-sdk/camera
2. `GMSNavigationCameraMode`  
   https://developers.google.com/maps/documentation/navigation/ios-sdk/reference/objc/Enums/GMSNavigationCameraMode
3. `GMSNavigationCameraPerspective`  
   https://developers.google.com/maps/documentation/navigation/ios-sdk/reference/objc/Enums/GMSNavigationCameraPerspective

## 9. 结论

当前实现已经具备：

1. 用户点位箭头渲染。  
2. heading 输入链路。  
3. 基础版 `Locate Me -> followsHeading`。  

但距离行业成熟方案还差一层“产品级相机模型”。  
核心不是再补一个布尔值，而是把“点位箭头朝向”“相机是否跟随”“路线概览”“用户手势退出”收束为一套显式状态机，并让定位、heading、权限、功耗都围绕这套状态机工作。

## 10. 分步解决步骤（建议按顺序执行）

### Step 1：补状态机骨架

1. 在 `MapScreenState` 新增 `MapTrackingMode`。  
2. 将当前 `Locate Me`、首次定位、点 pin、选搜索结果、路线概览等入口全部改为显式写入 `trackingMode`。  
3. 保留现有 `cameraPosition`，但不再让它承担“唯一状态源”职责。

完成定义：

1. 代码里能一眼看出当前是 `free`、`followNorthUp`、`followBearing` 还是 `routeOverview`。  

### Step 2：接入用户手势退出跟随

1. 为 `Map` 增加相机变化监听。  
2. 消费 `positionedByUser` 或等价相机变更上下文。  
3. 一旦用户拖图/缩放/旋转，切换到 `free`。  
4. 新增 Recenter 按钮，仅在 `free` / `routeOverview` 显示。

完成定义：

1. 用户拖图后，业务状态与相机状态一致。  
2. 可以稳定从 `free` 返回 `follow`。

### Step 3：把“箭头朝向”和“相机朝向”拆开

1. 为用户点位新增统一 bearing 解析函数。  
2. 输出 `userMarkerBearing`，只驱动箭头。  
3. 相机是否跟随 bearing 由 `trackingMode` 决定。  

完成定义：

1. 即便相机不跟随，箭头仍可继续转。  
2. 代码语义不再混淆。

### Step 4：加入 heading / course 双源策略

1. 读取 `CLLocation.course` 与 `speed`。  
2. 低速优先 heading，高速优先 course。  
3. 在切换阈值附近做简单去抖，避免来回抖动。  

完成定义：

1. 步行和快速移动两种场景的方向体验都更稳定。

### Step 5：加入 heading 质量门控

1. 将 `headingAccuracy` 纳入 bearing 选择。  
2. heading 无效或精度过差时，退回蓝点。  
3. 必要时在调试日志里输出“当前为何降级”。

完成定义：

1. 不再出现“低质量方向数据也强制显示箭头”的情况。

### Step 6：重构定位与 heading 启停

1. 浏览态优先用一次性定位或低频定位。  
2. follow 态按需开启标准定位与 heading。  
3. 导航态使用高精度持续定位。  
4. 退出 follow / 导航及时 stop。

完成定义：

1. 浏览态功耗明显下降。  
2. 导航态仍保留足够实时性。

### Step 7：补权限与精度分支

1. 在请求授权前先判断 `locationServicesEnabled()`。  
2. 区分系统级关闭、App 级拒绝、Reduced Accuracy。  
3. 对需要精确位置的链路评估 `requestTemporaryFullAccuracyAuthorization(...)`。

完成定义：

1. 用户看到的提示与真实阻塞原因一致。  
2. 近距离解锁类功能不再在 Approximate 模式下静默失败。

### Step 8：升级导航态相机体验

1. 路线生成后先给 overview。  
2. 提供一键返回 `followBearing`。  
3. 评估是否在导航开始后若干秒自动回到 follow。  

完成定义：

1. 既能看清路线全局，也能回到“跟着人走”的导航体验。

### Step 9：补 UI Test 与真机验证

1. 覆盖 `Locate Me -> Follow -> User Pan -> Free -> Recenter -> Follow`。  
2. 覆盖 heading 无效时箭头降级。  
3. 覆盖 overview 与 follow 间切换。  
4. 补真机步行测试，校准 `speed` 阈值和 heading 降级阈值。

完成定义：

1. 关键状态迁移有自动化用例。  
2. bearing 策略经过真机验证，而非仅凭模拟器判断。
