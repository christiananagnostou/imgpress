import AppKit

@MainActor
final class MenuBarController: NSObject {
    private let popover: NSPopover
    private let appState: AppState
    private let statusItem: NSStatusItem
    private let dropView = StatusItemDropView()

    init(popover: NSPopover, appState: AppState) {
        self.popover = popover
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        NSLog("MenuBarController init - status item created: \(statusItem)")
        statusItem.isVisible = true
        configureStatusItem()
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closePopover() {
        popover.performClose(nil)
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            NSLog("MenuBarController configureStatusItem - status item has no button")
            return
        }
        NSLog("MenuBarController configureStatusItem - configuring button")
        button.image = NSImage(systemSymbolName: "camera.aperture", accessibilityDescription: "Rebar")
        button.image?.isTemplate = true
        if button.image == nil {
            button.title = "Reb"
            button.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        }
        button.target = self
        button.action = #selector(togglePopover(_:))

        dropView.translatesAutoresizingMaskIntoConstraints = false
        dropView.onClick = { [weak self] in
            self?.togglePopover(nil)
        }
        dropView.onPerformDrop = { [weak self] urls in
            self?.handleDrop(urls: urls)
        }
        dropView.onDraggingHighlight = { [weak self] highlighted in
            self?.animateHighlight(isHighlighted: highlighted)
        }

        button.addSubview(dropView, positioned: .above, relativeTo: nil)
        NSLayoutConstraint.activate([
            dropView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            dropView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            dropView.topAnchor.constraint(equalTo: button.topAnchor),
            dropView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
    }

    private func animateHighlight(isHighlighted: Bool) {
        guard let button = statusItem.button else { return }
        let highlightColor = NSColor.controlAccentColor.withAlphaComponent(isHighlighted ? 0.35 : 0)
        if isHighlighted {
            if button.layer == nil {
                button.wantsLayer = true
            }
            button.layer?.backgroundColor = highlightColor.cgColor
            button.layer?.cornerRadius = 6
        } else {
            button.layer?.backgroundColor = highlightColor.cgColor
        }
    }

    private func handleDrop(urls: [URL]) {
        closePopover()
        appState.register(drop: urls)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showPopover()
        }
    }
}
