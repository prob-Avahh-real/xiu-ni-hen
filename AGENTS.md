# AGENTS.md — 嗅你狠

iOS / macOS SwiftUI 应用，用于室内气味检测与追踪。

## 技术栈

Swift 5.9 · SwiftUI · iOS 17+ / macOS 14+

## 文件结构

```
Sources/OdorWatch/
  App/              — @main 入口
  Models/           — 数据模型（OdorType, OdorEvent, Room 等）
  Services/
    Protocols/      — 服务协议（Storage, PatternEngine, Notification）
    StorageService.swift
    PatternEngine.swift
    NotificationService.swift
  ViewModels/       — OdorViewModel（依赖注入）
  Views/
    ContentView.swift
    Home/             — 极简主屏（单房间聚焦 + 语音）
    Components/       — 可复用 UI 组件
    Dashboard/        — 旧版（已弃用，保留参考）
    Timeline/ Guidance/ Settings/
  DesignSystem/       — DesignTokens, VoiceButton, FocusCard
Tests/OdorWatchTests/
```

## 架构约定

- **单一源码目录**：仅 `Sources/OdorWatch/`，XcodeGen 通过 `project.yml` 引用
- **极简 + 探索式**：主屏只展示一个房间焦点，历史/指引/设置通过语音或「探索」抽屉进入
- **语音调度**：`VoiceService` 识别意图 → TTS 确认 → 打开对应 Sheet
- **依赖注入**：ViewModel 通过协议接收 Storage / PatternEngine / Notification 服务
- **跨平台**：iOS 专属 API 使用 `#if os(iOS)` 或 `Extensions/PlatformColor.swift`

## 常用命令

```bash
swift build          # 编译
swift test           # 单元测试
swiftlint            # 代码检查
xcodegen             # 生成 Xcode 工程
```
