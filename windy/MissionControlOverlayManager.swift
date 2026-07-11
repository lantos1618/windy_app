//
//  MissionControlOverlayManager.swift
//  windy
//
//  Created by Codex on 11/07/2026.
//

import AppKit
import ApplicationServices
import OSLog

enum MissionControlBarState: Equatable {
    case closed
    case compact
    case expanded
}

enum MissionControlOverlayLayout {
    static let expandedButtonHeight: CGFloat = 40

    static func state(for buttonFrames: [NSRect]) -> MissionControlBarState {
        guard !buttonFrames.isEmpty else {
            return .closed
        }

        return buttonFrames.contains { $0.height > expandedButtonHeight } ? .expanded : .compact
    }

    static func labelFrame(for buttonFrame: NSRect, state: MissionControlBarState) -> NSRect {
        switch state {
        case .closed:
            return .zero
        case .compact:
            let width = max(buttonFrame.width, 86)
            return NSRect(
                x: buttonFrame.midX - width / 2,
                y: buttonFrame.minY,
                width: width,
                height: buttonFrame.height
            )
        case .expanded:
            let width = min(max(buttonFrame.width - 20, 88), 150)
            let height: CGFloat = 23
            return NSRect(
                x: buttonFrame.midX - width / 2,
                y: buttonFrame.minY - height - 3,
                width: width,
                height: height
            )
        }
    }

    static func compactButtonFrame(_ buttonFrame: NSRect, spacesBarFrame: NSRect) -> NSRect {
        var result = buttonFrame
        let lowerHalfCenterY = spacesBarFrame.minY + spacesBarFrame.height * 0.75
        result.origin.y = lowerHalfCenterY - buttonFrame.height / 2
        return result
    }
}

private final class MissionControlLabelView: NSView {
    private let label = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 0.94).cgColor
        layer?.cornerRadius = 5
        layer?.borderWidth = 2

        label.alignment = .center
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        label.lineBreakMode = .byTruncatingTail
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        label.frame = bounds.insetBy(dx: 7, dy: 2)
    }

    func update(name: String, colour: NSColor) {
        label.stringValue = name
        layer?.borderColor = colour.cgColor
    }
}

private final class MissionControlLabelPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class MissionControlOverlayManager {
    private static let observerCallback: AXObserverCallback = { _, _, _, context in
        guard let context else { return }
        let manager = Unmanaged<MissionControlOverlayManager>.fromOpaque(context).takeUnretainedValue()
        DispatchQueue.main.async {
            manager.refresh()
        }
    }

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "zug.dev.windy",
        category: "MissionControl"
    )
    private let spaceLabelManager: SpaceLabelManager

    private var dockElement: AXUIElement?
    private var observer: AXObserver?
    private var watchdogTimer: Timer?
    private var trackingTimer: Timer?
    private var panels: [String: MissionControlLabelPanel] = [:]
    private var observedElementHashes = Set<CFHashCode>()
    private var state: MissionControlBarState = .closed
    private var isRunning = false

    init(spaceLabelManager: SpaceLabelManager) {
        self.spaceLabelManager = spaceLabelManager
    }

    func start() {
        guard !isRunning, AXIsProcessTrusted() else { return }
        guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else {
            logger.error("Dock process was unavailable")
            return
        }

        isRunning = true
        dockElement = AXUIElementCreateApplication(dock.processIdentifier)
        installObserver(processIdentifier: dock.processIdentifier)

        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            guard self?.state == .closed else { return }
            self?.refresh()
        }
        refresh()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        watchdogTimer?.invalidate()
        watchdogTimer = nil
        stopTrackingAnimation()
        hideAllPanels()

        if let observer {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        }
        observer = nil
        dockElement = nil
        observedElementHashes.removeAll()
        state = .closed
    }

    func refresh() {
        guard isRunning, let dockElement else { return }

        let spacesLists = missionControlSpacesLists(in: dockElement)
        guard !spacesLists.isEmpty else {
            transition(to: .closed)
            return
        }

        observeVisibleElements(spacesLists)
        let buttonGroups = spacesLists.map(desktopButtons(in:))
        let spacesBarFrames = spacesLists.map(accessibilityFrame(for:))
        let allButtons = buttonGroups.flatMap { $0 }
        let accessibilityFrames = allButtons.compactMap(accessibilityFrame(for:))
        let newState = MissionControlOverlayLayout.state(for: accessibilityFrames)
        if state == .closed, newState != .closed {
            spaceLabelManager.refresh()
        }
        transition(to: newState)

        guard newState != .closed else { return }

        var activePanelKeys = Set<String>()
        for (displayIndex, buttons) in buttonGroups.enumerated() {
            for (desktopIndex, button) in buttons.enumerated() {
                guard let accessibilityFrame = accessibilityFrame(for: button) else { continue }
                let effectiveAccessibilityFrame: NSRect
                if newState == .compact, let spacesBarFrame = spacesBarFrames[displayIndex] {
                    effectiveAccessibilityFrame = MissionControlOverlayLayout.compactButtonFrame(
                        accessibilityFrame,
                        spacesBarFrame: spacesBarFrame
                    )
                } else {
                    effectiveAccessibilityFrame = accessibilityFrame
                }
                let buttonFrame = ScreenGeometryService.appKitFrame(fromAccessibilityRect: effectiveAccessibilityFrame)
                let panelKey = "\(displayIndex):\(desktopIndex)"
                let panel = panel(for: panelKey)
                let labelFrame = MissionControlOverlayLayout.labelFrame(for: buttonFrame, state: newState)
                let space = spaceLabelManager.space(displayIndex: displayIndex, desktopIndex: desktopIndex)
                let fallbackIndex = desktopIndex + 1

                panel.setFrame(labelFrame, display: true)
                if let contentView = panel.contentView as? MissionControlLabelView {
                    contentView.update(
                        name: spaceLabelManager.name(for: space, fallbackIndex: fallbackIndex),
                        colour: spaceLabelManager.colour(for: space, fallbackIndex: fallbackIndex).nsColor
                    )
                }
                panel.orderFrontRegardless()
                activePanelKeys.insert(panelKey)
            }
        }

        for (key, panel) in panels where !activePanelKeys.contains(key) {
            panel.orderOut(nil)
        }
    }

    private func installObserver(processIdentifier: pid_t) {
        var newObserver: AXObserver?
        guard AXObserverCreate(processIdentifier, Self.observerCallback, &newObserver) == .success,
              let newObserver,
              let dockElement else {
            logger.error("Unable to install Dock Accessibility observer")
            return
        }

        observer = newObserver
        let context = Unmanaged.passUnretained(self).toOpaque()
        let notifications = [
            kAXCreatedNotification,
            kAXLayoutChangedNotification,
            kAXUIElementDestroyedNotification
        ]

        for notification in notifications {
            _ = AXObserverAddNotification(newObserver, dockElement, notification as CFString, context)
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(newObserver), .commonModes)
    }

    private func observeVisibleElements(_ spacesLists: [AXUIElement]) {
        guard let observer else { return }
        let context = Unmanaged.passUnretained(self).toOpaque()

        for element in spacesLists + spacesLists.flatMap(desktopButtons(in:)) {
            let hash = CFHash(element)
            guard observedElementHashes.insert(hash).inserted else { continue }

            for notification in [kAXLayoutChangedNotification, kAXMovedNotification, kAXResizedNotification, kAXUIElementDestroyedNotification] {
                _ = AXObserverAddNotification(observer, element, notification as CFString, context)
            }
        }
    }

    private func transition(to newState: MissionControlBarState) {
        guard state != newState else { return }
        logger.debug("Mission Control state: \(String(describing: newState), privacy: .public)")
        state = newState

        if newState == .closed {
            stopTrackingAnimation()
            observedElementHashes.removeAll()
            hideAllPanels()
        } else {
            startTrackingAnimation()
        }
    }

    private func startTrackingAnimation() {
        guard trackingTimer == nil else { return }
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func stopTrackingAnimation() {
        trackingTimer?.invalidate()
        trackingTimer = nil
    }

    private func panel(for key: String) -> MissionControlLabelPanel {
        if let panel = panels[key] {
            return panel
        }

        let panel = MissionControlLabelPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.contentView = MissionControlLabelView(frame: .zero)
        panels[key] = panel
        return panel
    }

    private func hideAllPanels() {
        panels.values.forEach { $0.orderOut(nil) }
    }

    private func desktopButtons(in spacesList: AXUIElement) -> [AXUIElement] {
        children(of: spacesList).filter { element in
            guard stringAttribute(kAXTitleAttribute as CFString, from: element)?.hasPrefix("Desktop ") == true else {
                return false
            }

            var actionNames: CFArray?
            guard AXUIElementCopyActionNames(element, &actionNames) == .success else { return false }
            return (actionNames as? [String])?.contains("AXRemoveDesktop") == true
        }
    }

    private func elements(withIdentifier identifier: String, in root: AXUIElement) -> [AXUIElement] {
        var matches: [AXUIElement] = []
        var visited = Set<CFHashCode>()

        func visit(_ element: AXUIElement, depth: Int) {
            guard depth <= 12 else { return }
            let hash = CFHash(element)
            guard visited.insert(hash).inserted else { return }

            if stringAttribute(kAXIdentifierAttribute as CFString, from: element) == identifier {
                matches.append(element)
                return
            }

            for child in children(of: element) {
                visit(child, depth: depth + 1)
            }
        }

        visit(root, depth: 0)
        return matches
    }

    private func missionControlSpacesLists(in dockElement: AXUIElement) -> [AXUIElement] {
        guard let missionControl = children(of: dockElement).first(where: {
            stringAttribute(kAXIdentifierAttribute as CFString, from: $0) == "mc"
        }) else {
            return []
        }

        return elements(withIdentifier: "mc.spaces.list", in: missionControl)
    }

    private func accessibilityFrame(for element: AXUIElement) -> NSRect? {
        guard
            let position = pointAttribute(kAXPositionAttribute as CFString, from: element),
            let size = sizeAttribute(kAXSizeAttribute as CFString, from: element)
        else {
            return nil
        }

        return NSRect(origin: position, size: size)
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        attribute(kAXChildrenAttribute as CFString, from: element) as? [AXUIElement] ?? []
    }

    private func stringAttribute(_ name: CFString, from element: AXUIElement) -> String? {
        attribute(name, from: element) as? String
    }

    private func pointAttribute(_ name: CFString, from element: AXUIElement) -> CGPoint? {
        guard let value = axValueAttribute(name, from: element) else { return nil }
        var point = CGPoint.zero
        return AXValueGetValue(value, .cgPoint, &point) ? point : nil
    }

    private func sizeAttribute(_ name: CFString, from element: AXUIElement) -> CGSize? {
        guard let value = axValueAttribute(name, from: element) else { return nil }
        var size = CGSize.zero
        return AXValueGetValue(value, .cgSize, &size) ? size : nil
    }

    private func axValueAttribute(_ name: CFString, from element: AXUIElement) -> AXValue? {
        guard let value = attribute(name, from: element), CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }
        return unsafeBitCast(value, to: AXValue.self)
    }

    private func attribute(_ name: CFString, from element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name, &value) == .success else { return nil }
        return value
    }
}
