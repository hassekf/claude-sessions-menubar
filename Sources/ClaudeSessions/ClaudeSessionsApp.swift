import SwiftUI
import AppKit

@main
struct ClaudeSessionsApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            DropdownView()
                .environmentObject(state)
        } label: {
            MenuBarLabelView(state: state)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        LaunchAtLogin.registerOnFirstLaunch()
    }
}
