//
//  X_wallpaperApp.swift
//  X wallpaper
//
//  Created by louiszliu on 9/7/25.
//

import SwiftUI
import AppKit

// 菜单栏控制器（常驻）
final class StatusBarController {
    private var statusItem: NSStatusItem!
    private weak var controller: WallpaperController?

    init(controller: WallpaperController) {
        self.controller = controller
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🎞️"
        statusItem.button?.toolTip = "Video Wallpaper"
        rebuildMenu()
    }

    func rebuildMenu() {
        guard let language = controller?.language else { return }
        let menu = NSMenu()
        menu.addItem(withTitle: Localization.string(.showControlPanel, for: language), action: #selector(showPanel), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: controller?.isPlaying == true ? Localization.string(.pause, for: language) : Localization.string(.play, for: language),
                     action: #selector(togglePlay), keyEquivalent: "")
        menu.addItem(withTitle: Localization.string(.importVideo, for: language), action: #selector(importVideo), keyEquivalent: "")
        let muteTitle = controller?.defaultMuted == true ? Localization.string(.unmute, for: language) : Localization.string(.mute, for: language)
        let mute = NSMenuItem(title: muteTitle,
                              action: #selector(toggleMute), keyEquivalent: "")
        menu.addItem(mute)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: Localization.string(.quit, for: language), action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    @objc private func showPanel() {
        NSApp.activate(ignoringOtherApps: true)
        let title = Localization.string(.controlPanel, for: controller?.language ?? .chinese)
        if let win = NSApp.windows.first(where: { $0.title == title }) {
            win.makeKeyAndOrderFront(nil)
        } else {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
    @objc private func togglePlay() { controller?.togglePlay(); rebuildMenu() }
    @objc private func importVideo() { controller?.importVideo() }
    @objc private func toggleMute() {
        guard let c = controller else { return }
        c.defaultMuted.toggle()
        c.setMuted(c.defaultMuted)
        rebuildMenu()
    }
    @objc private func quit() { NSApp.terminate(nil) }
}

// AppDelegate：用于创建菜单栏
final class AppDelegate: NSObject, NSApplicationDelegate {
    var status: StatusBarController?
    var controller: WallpaperController?
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let c = controller { status = StatusBarController(controller: c) }
    }
}

@main
struct VideoWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var controller = WallpaperController()

    

    var body: some Scene {
        WindowGroup(Localization.string(.controlPanel, for: controller.language)) {
            ContentView()
                .environmentObject(controller)
                .frame(minWidth: 460, minHeight: 320)
                .onAppear { appDelegate.controller = controller }
        }
        Settings {
            SettingsView()
                .environmentObject(controller)
                .frame(width: 380, height: 260)
        }
    }
}
