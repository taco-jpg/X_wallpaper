//
//  WallpaperController.swift
//  X wallpaper
//
//  Created by louiszliu on 9/7/25.
//
import SwiftUI
import AVFoundation
import AppKit
import UniformTypeIdentifiers
import ApplicationServices   // ⬅️ 新增：AX 辅助功能 API

// MARK: - Player Hosting View
final class PlayerHostingView: NSView {
    let playerLayer = AVPlayerLayer()
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        playerLayer.videoGravity = .resizeAspectFill
        self.layer?.addSublayer(playerLayer)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layout() {
        super.layout()
        CATransaction.begin(); CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

struct PlayerContainer: NSViewRepresentable {
    let player: AVPlayer?
    func makeNSView(context: Context) -> PlayerHostingView { PlayerHostingView() }
    func updateNSView(_ nsView: PlayerHostingView, context: Context) { nsView.playerLayer.player = player }
}

// MARK: - Controller
final class WallpaperController: NSObject, ObservableObject {
    // 持久化设置
    @AppStorage("defaultMuted") var defaultMuted: Bool = true
    @AppStorage("enableBounce") var enableBounce: Bool = true
    @AppStorage("autoPauseOnFullscreen") var autoPauseOnFullscreen: Bool = true
    @AppStorage("autoPauseInBackground") var autoPauseInBackground: Bool = true
    @AppStorage("launchWithApp") var launchWithApp: Bool = true
    @AppStorage("joinAllSpaces") var joinAllSpaces: Bool = true
    @AppStorage("monitorInterval") var monitorInterval: Double = 1.0
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("lastVideoPath") private var lastVideoPath: String = ""   // 记住上次壁纸
    
    // 状态（只保留这一份）
    @Published var status: String = "等待导入"
    @Published var isPlaying: Bool = false
    @Published var isReady: Bool = false
    @Published var currentFilename: String? = nil
    
    @Published var userPaused: Bool = false       // 手动暂停
    private var reasonPaused: Bool = false        // 规则导致的暂停
    
    private var player: AVQueuePlayer?
    private var wallpaperWindow: NSWindow?
    private var monitorTimer: Timer?
    
    override init() {
        super.init()
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(spaceChanged),
                                                          name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(activeAppChanged),
                                                          name: NSWorkspace.didActivateApplicationNotification, object: nil)
        if autoPauseOnFullscreen { ensureAXPermission() }   // ⬅️ 新增

        if launchWithApp { createWallpaperWindowIfNeeded() }
        ensureWindowOnDesktop()
        startMonitor()
        
        // 自动恢复上次壁纸
        if !lastVideoPath.isEmpty {
            let url = URL(fileURLWithPath: lastVideoPath)
            if FileManager.default.fileExists(atPath: url.path) {
                Task { await load(url: url) }
            }
        }
        
        // 开机自启配置（路径变化后刷新）
        updateLaunchAgent(launchAtLogin)
    }
    // === AX Fullscreen Support BEGIN ===
    // 需要在文件顶部: import ApplicationServices

    private func ensureAXPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
        let opts: CFDictionary = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    private func isFrontAppFullscreenAX() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        let whitelist: Set<String> = ["com.apple.finder", Bundle.main.bundleIdentifier ?? ""]
        if whitelist.contains(frontApp.bundleIdentifier ?? "") { return false }

        let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)
        var winObj: AnyObject?
        if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &winObj) != .success { return false }
        guard let win = winObj else { return false }

        var fullObj: AnyObject?
        if AXUIElementCopyAttributeValue(win as! AXUIElement, "AXFullScreen" as CFString, &fullObj) == .success {
            return (fullObj as? Bool) ?? false
        }
        return false
    }

    private func hasFullscreenOrMaximizedWindow() -> Bool {
        if isFrontAppFullscreenAX() { return true }

        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let infoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]],
              let screen = NSScreen.main else { return false }

        let whitelist: Set<String> = ["com.apple.finder", Bundle.main.bundleIdentifier ?? ""]
        if whitelist.contains(frontApp.bundleIdentifier ?? "") { return false }

        let windows = infoList.filter { ($0[kCGWindowOwnerPID as String] as? pid_t) == frontApp.processIdentifier }
        let screenRect = screen.frame
        let screenArea = screenRect.width * screenRect.height
        for win in windows {
            guard let b = win[kCGWindowBounds as String] as? [String: CGFloat] else { continue }
            let rect = CGRect(x: b["X"] ?? 0, y: b["Y"] ?? 0, width: b["Width"] ?? 0, height: b["Height"] ?? 0)
            if rect.width < 300 || rect.height < 300 { continue }
            let cover = (rect.width * rect.height) / screenArea
            if cover > 0.98 { return true }
        }
        return false
    }
    // === AX Fullscreen Support END ===

    deinit { stopMonitor(); NotificationCenter.default.removeObserver(self) }
    
    // MARK: 导入视频
    func importVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            Task { await load(url: url) }
        }
    }
    
    @MainActor
    func load(url: URL) async {
        status = "加载中…"
        currentFilename = url.lastPathComponent
        createWallpaperWindowIfNeeded()
        
        let asset = AVURLAsset(url: url)
        _ = try? await asset.load(.isPlayable)
        
        // 新 API 获取时长，拿不到时从 video track 的 timeRange 兜底
        let loadedDuration = try? await asset.load(.duration)
        var duration: CMTime = loadedDuration ?? .zero
        if CMTimeCompare(duration, .zero) <= 0 {
            if let tracks = try? await asset.load(.tracks),
               let v = tracks.first(where: { $0.mediaType == .video }),
               let tr = try? await v.load(.timeRange) {
                duration = tr.duration
            }
        }
        
        var playAsset: AVAsset = asset
        if enableBounce,
           CMTimeCompare(duration, .zero) > 0,
           let bounced = await makeBounceAsset(from: asset, duration: duration) {
            playAsset = bounced
        }
        
        let item = AVPlayerItem(asset: playAsset)
        let q = AVQueuePlayer(playerItem: item)
        q.isMuted = defaultMuted
        q.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(self, selector: #selector(itemEnded(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime, object: item)
        
        self.player = q
        attachPlayerToWindow()
        ensureWindowOnDesktop()
        self.isReady = true
        reasonPaused = false
        play()
        status = "就绪：\(currentFilename ?? "视频")"
        
        // 保存路径
        self.lastVideoPath = url.path
    }
    
    private func attachPlayerToWindow() {
        guard let window = wallpaperWindow else { return }
        let hosting = NSHostingView(rootView: PlayerContainer(player: self.player))
        hosting.frame = window.contentView?.bounds ?? .zero
        hosting.autoresizingMask = [.width, .height]
        window.contentView = hosting
    }
    
    // MARK: Bounce asset（正放 + 正放，视觉往返）
    private func makeBounceAsset(from asset: AVAsset, duration: CMTime) async -> AVAsset? {
        guard let videoTrack = try? await asset.load(.tracks)
            .first(where: { $0.mediaType == .video }) else { return nil }
        let comp = AVMutableComposition()
        guard let v = comp.addMutableTrack(withMediaType: .video,
                                           preferredTrackID: kCMPersistentTrackID_Invalid) else { return nil }
        let tr = CMTimeRange(start: .zero, duration: duration)
        try? v.insertTimeRange(tr, of: videoTrack, at: .zero)
        try? v.insertTimeRange(tr, of: videoTrack, at: duration)
        return comp
    }
    
    // MARK: 控制（含手动/规则暂停区分）
    func setMuted(_ muted: Bool) { player?.isMuted = muted }
    
    func togglePlay() {
        if isPlaying {
            userPaused = true
            pause()
        } else {
            userPaused = false
            play()
        }
    }
    
    func play() {
        guard !reasonPaused, !userPaused else { return }
        createWallpaperWindowIfNeeded()
        ensureWindowOnDesktop()
        player?.play()
        isPlaying = true
        status = "播放中"
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        status = "已暂停"
    }
    
    func stopAndTearDown() {
        pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        wallpaperWindow?.orderOut(nil)
        wallpaperWindow = nil
        status = "已移除"
        isReady = false
        currentFilename = nil
    }
    
    @objc private func itemEnded(_ n: Notification) {
        player?.seek(to: .zero)
        if !reasonPaused && !userPaused {
            player?.play()
            isPlaying = true
            status = "播放中"
        }
    }
    
    // MARK: 壁纸窗口 & 保位
    private func createWallpaperWindowIfNeeded() {
        guard wallpaperWindow == nil else { return }
        let frame = NSScreen.screens.first?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let win = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        
        var behavior: NSWindow.CollectionBehavior = [.stationary, .ignoresCycle]
        if joinAllSpaces { behavior.insert(.canJoinAllSpaces) }
        win.collectionBehavior = behavior
        win.ignoresMouseEvents = true
        win.isOpaque = true
        win.backgroundColor = .clear
        win.title = "Video Wallpaper"
        wallpaperWindow = win
        
        ensureWindowOnDesktop()
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged),
                                               name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    
    // 关键：把窗口钉在桌面背景与图标之间，且定时“保位”
    private func ensureWindowOnDesktop() {
        guard let win = wallpaperWindow else { return }
        if let screen = win.screen ?? NSScreen.main {
            win.setFrame(screen.frame, display: true)
        }
        let desktopLevel = CGWindowLevelForKey(.desktopWindow)
        let iconLevel    = CGWindowLevelForKey(.desktopIconWindow)
        let targetLevel  = Int(desktopLevel + (iconLevel - desktopLevel) / 2)
        if win.level.rawValue != targetLevel {
            win.level = NSWindow.Level(rawValue: targetLevel)
        }
        var behavior: NSWindow.CollectionBehavior = [.stationary, .ignoresCycle]
        if joinAllSpaces { behavior.insert(.canJoinAllSpaces) }
        if win.collectionBehavior != behavior { win.collectionBehavior = behavior }
        win.ignoresMouseEvents = true
        win.isOpaque = true
        win.backgroundColor = .clear
        win.orderFrontRegardless()
    }
    
    @objc private func screenChanged() { ensureWindowOnDesktop() }
    
    // MARK: 自动暂停 + 定时保位
    @objc private func spaceChanged() { ensureWindowOnDesktop(); evaluateAutoPauseReason() }
    @objc private func activeAppChanged() { evaluateAutoPauseReason() }
    
    private func startMonitor() {
        stopMonitor()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: monitorInterval, repeats: true) { [weak self] _ in
            self?.ensureWindowOnDesktop()
            self?.evaluateAutoPauseReason()
        }
    }
    private func stopMonitor() { monitorTimer?.invalidate(); monitorTimer = nil }
    
    private func evaluateAutoPauseReason() {
        var shouldPause = false
        if autoPauseOnFullscreen && hasFullscreenOrMaximizedWindow() { shouldPause = true }
        if autoPauseInBackground && frontmostAppIsNotFinderOrDesktop() { shouldPause = true }
        
        reasonPaused = shouldPause
        
        if reasonPaused {
            if isPlaying { pause() }      // 外部原因 → 必暂停
        } else {
            if isReady && !isPlaying && !userPaused { play() } // 无外因且用户未手动暂停 → 恢复
        }
        
        (NSApp.delegate as? AppDelegate)?.status?.rebuildMenu()
    }
    
    private func frontmostAppIsNotFinderOrDesktop() -> Bool {
        if let app = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
            return !(app == "com.apple.finder" || app == Bundle.main.bundleIdentifier)
        }
        return true
    }
    
    // MARK: - 开机自启 (兼容沙盒 & 非沙盒)
    func isSandboxed() -> Bool {
        // 判断是否处于 App Store / TestFlight 沙盒
        ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }
    
    func updateLaunchAgent(_ enabled: Bool) {
        if isSandboxed() {
            // ✅ 沙盒环境禁止 launchctl，避免崩溃
            status = "App Store 版本不支持内置开机自启，请到 系统设置 → 通用 → 登录项 手动添加。"
            
            // 可选：帮用户直接跳转到“登录项”设置 (macOS Ventura+)
            if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                NSWorkspace.shared.open(url)
            }
            return
        }
        
        // ✅ 开发版 (非沙盒) 使用 LaunchAgent
        let fm = FileManager.default
        let bundleID = Bundle.main.bundleIdentifier ?? "XWallpaper"
        let execPath = Bundle.main.bundlePath + "/Contents/MacOS/" + (Bundle.main.infoDictionary?["CFBundleExecutable"] as? String ?? "XWallpaper")
        let plistPath = (NSHomeDirectory() as NSString).appendingPathComponent("Library/LaunchAgents/\(bundleID).plist")
        
        if enabled {
            let plist: [String: Any] = [
                "Label": bundleID,
                "ProgramArguments": [execPath],
                "RunAtLoad": true,
                "KeepAlive": false,
                "ProcessType": "Interactive"
            ]
            do {
                let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
                try data.write(to: URL(fileURLWithPath: plistPath), options: .atomic)
                _ = runLaunchctl(["bootout", "gui/\(getuid())", plistPath])
                _ = runLaunchctl(["bootstrap", "gui/\(getuid())", plistPath])
                _ = runLaunchctl(["enable", "gui/\(getuid())/\(bundleID)"])
            } catch {
                status = "设置开机自启失败：\(error.localizedDescription)"
            }
        } else {
            _ = runLaunchctl(["bootout", "gui/\(getuid())", plistPath])
            try? fm.removeItem(atPath: plistPath)
        }
    }
    
    /// 执行 launchctl 命令 (仅非沙盒可用)
    @discardableResult
    private func runLaunchctl(_ args: [String]) -> Int32 {
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = args
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus
        } catch {
            return -1
        }
    }
}
