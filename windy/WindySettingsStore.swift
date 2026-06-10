//
//  WindySettingsStore.swift
//  windy
//
//  Created by Codex on 10/06/2026.
//

import Foundation
import SwiftUI

enum WindySettingsStore {
    static let accentColourKey = "accentColour"
    static let defaultsSetKey = "defaultsSet"
    static let displaySettingsKey = "displaySettings"

    static let defaultAccentColour = Color(
        red: 0.4,
        green: 0.4,
        blue: 0.4,
        opacity: 0.2
    )

    static func defaultDisplaySettings(for screens: [NSScreen] = NSScreen.screens) -> [String: NSPoint] {
        var result: [String: NSPoint] = [:]

        for screen in screens {
            result[screen.getIdString()] = NSPoint(x: 2.0, y: 2.0)
        }

        return result
    }

    static func mergeDisplaySettings(existing: [String: NSPoint], defaults: [String: NSPoint]) -> [String: NSPoint] {
        defaults.reduce(into: existing) { result, setting in
            if result[setting.key] == nil {
                result[setting.key] = setting.value
            }
        }
    }

    static func ensureDefaultsExist() {
        guard UserDefaults.standard.bool(forKey: defaultsSetKey) == false else {
            return
        }

        UserDefaults.standard.set(defaultAccentColour, forKey: accentColourKey)
        saveDisplaySettings(defaultDisplaySettings())
        UserDefaults.standard.set(true, forKey: defaultsSetKey)
    }

    static func loadDisplaySettings() throws -> [String: NSPoint] {
        try UserDefaults.standard.getDictPoints(forKey: displaySettingsKey)
    }

    static func saveDisplaySettings(_ settings: [String: NSPoint]) {
        do {
            try UserDefaults.standard.set(dict: settings, forKey: displaySettingsKey)
        } catch {
            debugPrint("failed to set default displaySettings")
        }
    }

    static func loadAccentColour() -> Color {
        UserDefaults.standard.color(forKey: accentColourKey)
    }

    static func saveAccentColour(_ colour: Color) {
        UserDefaults.standard.set(colour, forKey: accentColourKey)
    }
}
