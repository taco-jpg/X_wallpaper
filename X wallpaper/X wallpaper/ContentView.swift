//
//  ContentView.swift
//  X wallpaper
//
//  Created by louiszliu on 9/7/25.
//
import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var wc: WallpaperController

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Button("导入 MP4…") { wc.importVideo() }
                Button(wc.isPlaying ? "暂停" : "播放") { wc.togglePlay() }
                    .disabled(!wc.isReady)
                Button("移除壁纸") { wc.stopAndTearDown() }
            }

            Toggle("默认静音", isOn: $wc.defaultMuted)
            Toggle("播完自动倒放再播（流畅循环）", isOn: $wc.enableBounce)
            Toggle("全屏/最大化时自动暂停", isOn: $wc.autoPauseOnFullscreen)
            Toggle("切到前台应用时自动暂停（后台停播）", isOn: $wc.autoPauseInBackground)

            Divider()
            infoRow("状态", wc.status)
            infoRow("当前视频", wc.currentFilename ?? "—")

            Spacer()
            Text("若未见到壁纸：先关两项自动暂停测试；或在 系统设置→隐私与安全性→屏幕录制 勾本 App 更稳。")
                .foregroundColor(.secondary)
                .font(.footnote)
        }
        .padding(16)
        .onReceive(wc.$isPlaying) { _ in
            (NSApp.delegate as? AppDelegate)?.status?.rebuildMenu()
        }
    }

    @ViewBuilder
    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack { Text(title + "：").bold(); Text(value).lineLimit(1) }
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsView: View {
    @EnvironmentObject var wc: WallpaperController
    var body: some View {
        Form {
            Toggle("开机自启", isOn: Binding(
                get: { wc.launchAtLogin },
                set: { v in wc.launchAtLogin = v; wc.updateLaunchAgent(v) }
            ))
            Toggle("启动后自动创建壁纸窗口", isOn: $wc.launchWithApp)
            Toggle("覆盖所有桌面空间（所有桌面都显示）", isOn: $wc.joinAllSpaces)
            Stepper(value: $wc.monitorInterval, in: 0.5...5, step: 0.5) {
                Text("监控/保位间隔：\(String(format: "%.1f", wc.monitorInterval))s")
            }
        }
        .padding(16)
    }
}
