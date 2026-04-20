# X_wallpaper
# X_wallpaper

X_wallpaper is a macOS video wallpaper app. It keeps a local video playing behind the desktop, with options for looping, muting, auto-pause on fullscreen or background usage, and launch-at-login support.

## Features

- Play a local video as a desktop wallpaper.
- Keep the wallpaper pinned behind desktop icons and windows.
- Loop playback with a bounce-style repeat mode for smoother seams.
- Automatically pause when another app goes fullscreen or when a non-Finder app becomes active.
- Restore the last loaded video on launch.
- Toggle mute, wallpaper creation on launch, and login-item behavior from the app UI.

## Requirements

- macOS 13.5 or later.
- Xcode 16 or later recommended.
- A local video file, ideally MP4.

## Permissions

The app can request Accessibility permission to detect fullscreen state more reliably. If wallpaper rendering looks blank or inconsistent, also allow the app under System Settings > Privacy & Security > Screen Recording.

## How To Use

1. Launch the app.
2. Open the control panel from the app window or menu bar item.
3. Click Import MP4 and choose a local video.
4. Adjust mute, looping, and auto-pause options as needed.
5. If you want the app to start automatically, enable Launch at Login in Settings.

## Project Layout

- [X wallpaper/X wallpaper/X_wallpaperApp.swift](X%20wallpaper/X%20wallpaper/X_wallpaperApp.swift) contains the app entry point and menu bar controller.
- [X wallpaper/X wallpaper/ContentView.swift](X%20wallpaper/X%20wallpaper/ContentView.swift) contains the main control panel and Settings view.
- [X wallpaper/X wallpaper/WallpaperController.swift](X%20wallpaper/X%20wallpaper/WallpaperController.swift) contains playback, wallpaper window, and auto-pause logic.

## Notes

- The repository still contains the standard Xcode test targets, but their placeholder test files have been removed because they were not providing coverage.
- If you add tests later, recreate them under the existing test targets.
