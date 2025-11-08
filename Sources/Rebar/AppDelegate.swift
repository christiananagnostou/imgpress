import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var appState: AppState?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("Rebar applicationDidFinishLaunching invoked")
        ProcessInfo.processInfo.disableAutomaticTermination("RebarNeedsToStayRunning")
        NSApp.setActivationPolicy(.accessory)

        let appState = AppState()
        self.appState = appState
        NSLog("Rebar app state initialized")

        let contentView = ContentView()
            .environmentObject(appState)

        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 360, height: 460)
        popover.contentViewController = NSHostingController(rootView: contentView)

        menuBarController = MenuBarController(popover: popover, appState: appState)
        NSLog("Rebar menu bar controller ready")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            menuBarController?.showPopover()
        }
        return true
    }
}
