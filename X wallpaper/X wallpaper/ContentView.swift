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
        ZStack {
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .controlBackgroundColor)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header
                controlsCard
                settingsCard
                statusCard
                hintText
            }
            .padding(20)
        }
        .onChange(of: wc.isPlaying) { _, _ in refreshStatusBar() }
        .onChange(of: wc.defaultMuted) { _, newValue in
            wc.setMuted(newValue)
            refreshStatusBar()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Video Wallpaper")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("把本地视频钉到桌面背景层，支持自动循环、自动暂停和开机自启。")
                .foregroundStyle(.secondary)
        }
    }

    private var controlsCard: some View {
        card {
            HStack(spacing: 12) {
                Button("导入 MP4…") { wc.importVideo() }
                Button(wc.isPlaying ? "暂停" : "播放") { wc.togglePlay() }
                    .disabled(!wc.isReady)
                Button("移除壁纸") { wc.stopAndTearDown() }
            }
        }
    }

    private var settingsCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("默认静音", isOn: $wc.defaultMuted)
                Toggle("播完自动倒放再播（流畅循环）", isOn: $wc.enableBounce)
                Toggle("全屏/最大化时自动暂停", isOn: $wc.autoPauseOnFullscreen)
                Toggle("切到前台应用时自动暂停（后台停播）", isOn: $wc.autoPauseInBackground)
            }
        }
    }

    private var statusCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                infoRow("状态", wc.status)
                infoRow("当前视频", wc.currentFilename ?? "—")
            }
        }
    }

    private var hintText: some View {
        Text("若未见到壁纸，可先关闭两个自动暂停选项测试；若仍无画面，请在 系统设置 → 隐私与安全性 → 屏幕录制 中勾选本 App。")
            .foregroundStyle(.secondary)
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title + "：")
                .fontWeight(.semibold)
            Text(value)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08))
            )
    }

    private func refreshStatusBar() {
        (NSApp.delegate as? AppDelegate)?.status?.rebuildMenu()
    }
}

struct SettingsView: View {
    @EnvironmentObject var wc: WallpaperController
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("偏好设置")
                .font(.headline)

            Form {
                Toggle("开机自启", isOn: Binding(
                    get: { wc.launchAtLogin },
                    set: { v in
                        wc.launchAtLogin = v
                        wc.updateLaunchAgent(v)
                    }
                ))
                Toggle("启动后自动创建壁纸窗口", isOn: $wc.launchWithApp)
                Toggle("覆盖所有桌面空间（所有桌面都显示）", isOn: $wc.joinAllSpaces)
                Stepper(value: $wc.monitorInterval, in: 0.5...5, step: 0.5) {
                    Text("监控/保位间隔：\(String(format: "%.1f", wc.monitorInterval))s")
                }
            }
            .padding(.top, 4)

            Text("开机自启在沙盒环境中会跳转到系统的登录项设置；非沙盒版本则直接写入 LaunchAgent。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
    }
}
