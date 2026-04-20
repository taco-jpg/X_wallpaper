import Foundation

enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }
}

struct Localization {
    static func string(_ key: LocalizationKey, for language: Language) -> String {
        return strings[language]?[key] ?? key.rawValue
    }
    
    enum LocalizationKey: String {
        // Menu & Panel Titles
        case controlPanel = "Control Panel"
        case settings = "Settings"
        case showControlPanel = "Show Control Panel"
        case quit = "Quit"
        case videoWallpaper = "Video Wallpaper"
        
        // Actions
        case importVideo = "Import MP4…"
        case play = "Play"
        case pause = "Pause"
        case removeWallpaper = "Remove Wallpaper"
        case mute = "Mute"
        case unmute = "Unmute"
        
        // Toggles & Settings
        case defaultMuted = "Default Muted"
        case enableBounce = "Smooth Loop (Bounce)"
        case autoPauseFullscreen = "Auto Pause on Fullscreen"
        case autoPauseBackground = "Auto Pause in Background"
        case launchAtLogin = "Launch at Login"
        case launchWithApp = "Create Window on Launch"
        case joinAllSpaces = "Show on All Spaces"
        case monitorInterval = "Monitor Interval"
        case language = "Language"
        
        // Status & Info
        case status = "Status"
        case currentVideo = "Current Video"
        case waitingImport = "Waiting for Import"
        case loading = "Loading…"
        case playableError = "Cannot play this video"
        case ready = "Ready"
        case playing = "Playing"
        case paused = "Paused"
        case removed = "Removed"
        case waitingCondition = "Waiting for focus/screen condition..."
        case appStoreNotice = "App Store version does not support built-in launch at login. Please add it in System Settings."
        case launchAgentError = "Failed to set launch agent"
        case hintTitle = "If you don't see the wallpaper:"
        case hintDescription = "Try disabling auto-pause options, or ensure Screen Recording permission is granted in System Settings."
        case preferenceHeader = "Preferences"
        case launchAgentNotice = "Launch at login will open System Settings in sandbox mode, or write to LaunchAgent in non-sandbox mode."
        case appDescription = "Pins local videos to your desktop background with auto-loop, auto-pause, and login support."
    }
    
    private static let strings: [Language: [LocalizationKey: String]] = [
        .english: [
            .controlPanel: "Control Panel",
            .settings: "Settings",
            .showControlPanel: "Show Control Panel",
            .quit: "Quit",
            .videoWallpaper: "Video Wallpaper",
            .importVideo: "Import MP4…",
            .play: "Play",
            .pause: "Pause",
            .removeWallpaper: "Remove Wallpaper",
            .mute: "Mute",
            .unmute: "Unmute",
            .defaultMuted: "Default Muted",
            .enableBounce: "Smooth Loop (Bounce)",
            .autoPauseFullscreen: "Auto Pause on Fullscreen",
            .autoPauseBackground: "Auto Pause in Background",
            .launchAtLogin: "Launch at Login",
            .launchWithApp: "Create Window on Launch",
            .joinAllSpaces: "Show on All Spaces",
            .monitorInterval: "Monitor Interval",
            .language: "Language",
            .status: "Status",
            .currentVideo: "Current Video",
            .waitingImport: "Waiting for Import",
            .loading: "Loading…",
            .playableError: "Cannot play this video",
            .ready: "Ready",
            .playing: "Playing",
            .paused: "Paused",
            .removed: "Removed",
            .waitingCondition: "Waiting for focus/screen condition...",
            .appStoreNotice: "App Store version does not support built-in launch at login. Please add it in System Settings.",
            .launchAgentError: "Failed to set launch agent",
            .hintTitle: "If you don't see the wallpaper:",
            .hintDescription: "Try disabling auto-pause options, or ensure Screen Recording permission is granted in System Settings.",
            .preferenceHeader: "Preferences",
            .launchAgentNotice: "Launch at login will open System Settings in sandbox mode, or write to LaunchAgent in non-sandbox mode.",
            .appDescription: "Pins local videos to your desktop background with auto-loop, auto-pause, and login support."
        ],
        .chinese: [
            .controlPanel: "控制面板",
            .settings: "偏好设置",
            .showControlPanel: "显示控制面板",
            .quit: "退出",
            .videoWallpaper: "视频壁纸",
            .importVideo: "导入 MP4…",
            .play: "播放",
            .pause: "暂停",
            .removeWallpaper: "移除壁纸",
            .mute: "静音",
            .unmute: "取消静音",
            .defaultMuted: "默认静音",
            .enableBounce: "播完自动倒放再播（流畅循环）",
            .autoPauseFullscreen: "全屏/最大化时自动暂停",
            .autoPauseBackground: "切到前台应用时自动暂停（后台停播）",
            .launchAtLogin: "开机自启",
            .launchWithApp: "启动后自动创建壁纸窗口",
            .joinAllSpaces: "覆盖所有桌面空间（所有桌面都显示）",
            .monitorInterval: "监控/保位间隔",
            .language: "语言",
            .status: "状态",
            .currentVideo: "当前视频",
            .waitingImport: "等待导入",
            .loading: "加载中…",
            .playableError: "无法播放该视频",
            .ready: "就绪",
            .playing: "播放中",
            .paused: "已暂停",
            .removed: "已移除",
            .waitingCondition: "等待全屏或后台条件解除后继续播放",
            .appStoreNotice: "App Store 版本不支持内置开机自启，请到 系统设置 → 通用 → 登录项 手动添加。",
            .launchAgentError: "设置开机自启失败",
            .hintTitle: "若未见到壁纸：",
            .hintDescription: "可先关闭两个自动暂停选项测试；若仍无画面，请在 系统设置 → 隐私与安全性 → 屏幕录制 中勾选本 App。",
            .preferenceHeader: "偏好设置",
            .launchAgentNotice: "开机自启在沙盒环境中会跳转到系统的登录项设置；非沙盒版本则直接写入 LaunchAgent。",
            .appDescription: "把本地视频钉到桌面背景层，支持自动循环、自动暂停和开机自启。"
        ]
    ]
}

extension String {
    static func localized(_ key: Localization.LocalizationKey, _ language: Language) -> String {
        return Localization.string(key, for: language)
    }
}
