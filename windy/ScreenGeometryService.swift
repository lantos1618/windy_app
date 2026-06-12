//
//  ScreenGeometryService.swift
//  windy
//
//  Created by Codex on 12/06/2026.
//

import AppKit

enum ScreenGeometryService {
    static let stableIDPrefix = "display:"

    static func id(for screen: NSScreen) -> String {
        "\(stableIDPrefix)\(screen.displayID)"
    }

    static func legacyId(for screen: NSScreen) -> String {
        "\(screen.hash):\(screen.localizedName)"
    }

    static func screen(for id: String, screens: [NSScreen] = NSScreen.screens) -> NSScreen? {
        if let displayID = displayID(from: id) {
            return screens.first { $0.displayID == displayID }
        }

        return screens.first { legacyId(for: $0) == id }
    }

    static func displayID(from id: String) -> CGDirectDisplayID? {
        guard id.hasPrefix(stableIDPrefix) else {
            return nil
        }

        let rawValue = String(id.dropFirst(stableIDPrefix.count))
        guard let value = UInt32(rawValue) else {
            return nil
        }

        return CGDirectDisplayID(value)
    }

    static func activeScreenIds(for screens: [NSScreen] = NSScreen.screens) -> [String] {
        screens.map { id(for: $0) }
    }

    static func mainScreenId(screens: [NSScreen] = NSScreen.screens) -> String {
        guard let screen = NSScreen.main ?? screens.first else {
            return ""
        }

        return id(for: screen)
    }

    static func appKitFrame(for screen: NSScreen) -> NSRect {
        screen.frame
    }

    static func appKitVisibleFrame(for screen: NSScreen) -> NSRect {
        screen.visibleFrame
    }

    static func accessibilityFrame(for screen: NSScreen) -> NSRect {
        CGDisplayBounds(screen.displayID)
    }

    static func accessibilityVisibleFrame(for screen: NSScreen) -> NSRect {
        accessibilityRect(
            fromAppKitRect: screen.visibleFrame,
            appKitScreenFrame: screen.frame,
            accessibilityScreenFrame: accessibilityFrame(for: screen)
        )
    }

    static func accessibilityRect(
        fromAppKitRect rect: NSRect,
        appKitScreenFrame: NSRect,
        accessibilityScreenFrame: NSRect
    ) -> NSRect {
        NSRect(
            x: accessibilityScreenFrame.minX + (rect.minX - appKitScreenFrame.minX),
            y: accessibilityScreenFrame.minY + (appKitScreenFrame.maxY - rect.maxY),
            width: rect.width,
            height: rect.height
        )
    }

    static func accessibilityFrame(fromAppKitRect rect: NSRect, screens: [NSScreen] = NSScreen.screens) -> NSRect {
        guard let screen = screen(containingAppKitRect: rect, screens: screens) ?? NSScreen.main ?? screens.first else {
            return rect
        }

        return accessibilityRect(
            fromAppKitRect: rect,
            appKitScreenFrame: screen.frame,
            accessibilityScreenFrame: accessibilityFrame(for: screen)
        )
    }

    static func screen(containingAppKitPoint point: NSPoint, screens: [NSScreen] = NSScreen.screens) -> NSScreen? {
        screens.first { $0.frame.contains(point) } ?? NSScreen.main
    }

    static func screen(containingAccessibilityPoint point: NSPoint, screens: [NSScreen] = NSScreen.screens) -> NSScreen? {
        screens.first { accessibilityFrame(for: $0).contains(point) } ?? NSScreen.main
    }

    static func screen(containingAppKitRect rect: NSRect, screens: [NSScreen] = NSScreen.screens) -> NSScreen? {
        let center = rect.centerPoint()
        if let centeredScreen = screens.first(where: { $0.frame.contains(center) }) {
            return centeredScreen
        }

        return screens.max { left, right in
            intersectionArea(left.frame, rect) < intersectionArea(right.frame, rect)
        }
    }

    static func mirroredPointAcrossPrimaryDisplay(_ point: NSPoint, screens: [NSScreen] = NSScreen.screens) -> NSPoint {
        guard let screen = NSScreen.main ?? screens.first else {
            return point
        }

        return NSPoint(
            x: point.x,
            y: screen.frame.minY + screen.frame.maxY - point.y
        )
    }

    private static func intersectionArea(_ first: NSRect, _ second: NSRect) -> CGFloat {
        let intersection = first.intersection(second)
        guard !intersection.isNull else {
            return 0
        }

        return intersection.width * intersection.height
    }
}
