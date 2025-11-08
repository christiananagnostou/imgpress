import Cocoa

let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock")
print("Dock running: \(!runningApps.isEmpty)")
