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
        .onChange(of: wc.language) { _, _ in
            refreshStatusBar()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Localization.string(.videoWallpaper, for: wc.language))
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text(Localization.string(.appDescription, for: wc.language))
                .foregroundStyle(.secondary)
        }
    }

    private var controlsCard: some View {
        card {
            HStack(spacing: 12) {
                Button(Localization.string(.importVideo, for: wc.language)) { wc.importVideo() }
                Button(wc.isPlaying ? Localization.string(.pause, for: wc.language) : Localization.string(.play, for: wc.language)) { wc.togglePlay() }
                    .disabled(!wc.isReady)
                Button(Localization.string(.removeWallpaper, for: wc.language)) { wc.stopAndTearDown() }
            }
        }
    }

    private var settingsCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(Localization.string(.defaultMuted, for: wc.language), isOn: $wc.defaultMuted)
                Toggle(Localization.string(.enableBounce, for: wc.language), isOn: $wc.enableBounce)
                Toggle(Localization.string(.autoPauseFullscreen, for: wc.language), isOn: $wc.autoPauseOnFullscreen)
                Toggle(Localization.string(.autoPauseBackground, for: wc.language), isOn: $wc.autoPauseInBackground)
            }
        }
    }

    private var statusCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                infoRow(Localization.string(.status, for: wc.language), wc.status)
                infoRow(Localization.string(.currentVideo, for: wc.language), wc.currentFilename ?? "—")
            }
        }
    }

    private var hintText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string(.hintTitle, for: wc.language))
                .fontWeight(.bold)
            Text(Localization.string(.hintDescription, for: wc.language))
        }
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
            Text(Localization.string(.preferenceHeader, for: wc.language))
                .font(.headline)

            Form {
                Picker(Localization.string(.language, for: wc.language), selection: $wc.language) {
                    ForEach(Language.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)

                Toggle(Localization.string(.launchAtLogin, for: wc.language), isOn: Binding(
                    get: { wc.launchAtLogin },
                    set: { v in
                        wc.launchAtLogin = v
                        wc.updateLaunchAgent(v)
                    }
                ))
                Toggle(Localization.string(.launchWithApp, for: wc.language), isOn: $wc.launchWithApp)
                Toggle(Localization.string(.joinAllSpaces, for: wc.language), isOn: $wc.joinAllSpaces)
                Stepper(value: $wc.monitorInterval, in: 0.5...5, step: 0.5) {
                    Text("\(Localization.string(.monitorInterval, for: wc.language))：\(String(format: "%.1f", wc.monitorInterval))s")
                }
            }
            .padding(.top, 4)

            Text(Localization.string(.launchAgentNotice, for: wc.language))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
    }
}
