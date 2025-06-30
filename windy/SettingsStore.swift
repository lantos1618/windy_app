//
//  SettingsStore.swift
//  windy
//
//  Created by Lyndon Leong on 27/01/2023.
//

import Foundation
import SwiftUI

// MARK: - Grid Settings Struct
/// Type-safe grid configuration for each screen
struct GridSettings: Codable, Equatable {
    var columns: Int
    var rows: Int
    
    init(columns: Int = 2, rows: Int = 2) {
        self.columns = max(1, min(6, columns)) // Clamp to 1-6 range
        self.rows = max(1, min(6, rows)) // Clamp to 1-6 range
    }
    
    /// Convert to NSPoint for backward compatibility during transition
    var asNSPoint: NSPoint {
        return NSPoint(x: Double(columns), y: Double(rows))
    }
    
    /// Create from NSPoint for backward compatibility during transition
    static func fromNSPoint(_ point: NSPoint) -> GridSettings {
        return GridSettings(columns: Int(point.x), rows: Int(point.y))
    }
}

// MARK: - Settings Store
/// Manages all persistent user settings for the Windy app
class SettingsStore: ObservableObject {
    
    // MARK: - Published Properties
    @Published var gridSettingsPerScreen: [String: GridSettings] = [:] {
        didSet {
            saveGridSettings()
        }
    }
    
    @Published var accentColour: Color = Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2) {
        didSet {
            UserDefaults.standard.set(accentColour, forKey: "accentColour")
        }
    }
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    init() {
        loadSettings()
        setupScreenChangeObserver()
    }
    
    // MARK: - Public Methods
    
    /// Get grid settings for a specific screen, creating defaults if needed
    func getGridSettings(for screenId: String) -> GridSettings {
        if let settings = gridSettingsPerScreen[screenId] {
            return settings
        }
        
        // Create default settings for new screen
        let defaultSettings = GridSettings()
        gridSettingsPerScreen[screenId] = defaultSettings
        return defaultSettings
    }
    
    /// Update grid settings for a specific screen
    func updateGridSettings(for screenId: String, columns: Int? = nil, rows: Int? = nil) {
        var currentSettings = getGridSettings(for: screenId)
        
        if let columns = columns {
            currentSettings.columns = max(1, min(6, columns))
        }
        
        if let rows = rows {
            currentSettings.rows = max(1, min(6, rows))
        }
        
        gridSettingsPerScreen[screenId] = currentSettings
    }
    
    /// Reset all grid settings to defaults
    func resetGridSettings() {
        let defaultSettings = generateDefaultGridSettings()
        gridSettingsPerScreen = defaultSettings
    }
    
    /// Generate grid settings for all currently connected screens
    func generateDefaultGridSettings() -> [String: GridSettings] {
        var result: [String: GridSettings] = [:]
        for screen in NSScreen.screens {
            let screenId = screen.getIdString()
            result[screenId] = GridSettings()
        }
        return result
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        // Load accent color
        accentColour = userDefaults.color(forKey: "accentColour") ?? Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2)
        
        // Load grid settings (with backward compatibility)
        loadGridSettings()
    }
    
    private func loadGridSettings() {
        // Try to load new format first
        if let data = userDefaults.data(forKey: "gridSettingsPerScreen"),
           let decodedSettings = try? JSONDecoder().decode([String: GridSettings].self, from: data) {
            gridSettingsPerScreen = decodedSettings
        } else {
            // Fallback to old format for backward compatibility
            loadLegacyGridSettings()
        }
        
        // Ensure all current screens have settings
        mergeWithCurrentScreens()
    }
    
    private func loadLegacyGridSettings() {
        do {
            let legacySettings = try userDefaults.getDictPoints(forKey: "displaySettings")
            gridSettingsPerScreen = legacySettings.mapValues { GridSettings.fromNSPoint($0) }
        } catch {
            debugPrint("Failed to load legacy display settings: \(error)")
            gridSettingsPerScreen = generateDefaultGridSettings()
        }
    }
    
    private func saveGridSettings() {
        do {
            let data = try JSONEncoder().encode(gridSettingsPerScreen)
            userDefaults.set(data, forKey: "gridSettingsPerScreen")
            
            // Also save in legacy format for backward compatibility during transition
            let legacyFormat = gridSettingsPerScreen.mapValues { $0.asNSPoint }
            try userDefaults.set(dict: legacyFormat, forKey: "displaySettings")
        } catch {
            debugPrint("Failed to save grid settings: \(error)")
        }
    }
    
    private func mergeWithCurrentScreens() {
        let currentScreenIds = Set(NSScreen.screens.map { $0.getIdString() })
        let existingScreenIds = Set(gridSettingsPerScreen.keys)
        
        // Add settings for new screens
        for screenId in currentScreenIds {
            if !existingScreenIds.contains(screenId) {
                gridSettingsPerScreen[screenId] = GridSettings()
            }
        }
        
        // Remove settings for disconnected screens (optional - you might want to keep them)
        // for screenId in existingScreenIds {
        //     if !currentScreenIds.contains(screenId) {
        //         gridSettingsPerScreen.removeValue(forKey: screenId)
        //     }
        // }
    }
    
    private func setupScreenChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared,
            queue: OperationQueue.main
        ) { [weak self] _ in
            self?.handleScreenChange()
        }
    }
    
    private func handleScreenChange() {
        mergeWithCurrentScreens()
    }
}

// MARK: - UserDefaults Extensions (if not already defined)
extension UserDefaults {
    func color(forKey key: String) -> Color? {
        guard let data = data(forKey: key) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data).map { Color($0) }
    }
    
    func set(_ color: Color, forKey key: String) {
        let nsColor = NSColor(color)
        let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false)
        set(data, forKey: key)
    }
} 