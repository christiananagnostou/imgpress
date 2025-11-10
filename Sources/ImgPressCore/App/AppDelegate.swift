import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("ImgPressNeedsToStayRunning")
        NSApp.setActivationPolicy(.accessory)

        let appState = AppState()

        let contentView = ContentView()
            .environmentObject(appState)

        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 420, height: 600)
        popover.contentViewController = NSHostingController(rootView: contentView)

        menuBarController = MenuBarController(popover: popover, appState: appState)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
        -> Bool
    {
        if !flag {
            menuBarController?.showPopover()
        }
        return true
    }
}
