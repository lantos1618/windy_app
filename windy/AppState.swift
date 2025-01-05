import Foundation
import SwiftUI
import Combine

// MARK: - App State
final class AppState: ObservableObject {
    // MARK: - Display Settings
    @Published private(set) var displaySettings: [String: NSPoint] = [:] {
        didSet {
            storeDisplaySettings()
            updateRects()
        }
    }
    
    @Published private(set) var rectsDict: [String: [[NSRect]]] = [:]
    @Published var activeSettingScreen: String = NSScreen.main!.getIdString()
    @Published var activeScreens: [String] = []
    
    // MARK: - UI State
    @Published var isShown: Bool = false
    @Published var isShownTimeout: Timer?
    @Published var accentColour: Color = .accentColor {
        didSet {
            UserDefaults.standard.set(self.accentColour, forKey: "accentColour")
        }
    }
    
    // MARK: - License State
    @Published var email: String = UserDefaults.standard.string(forKey: "email") ?? "" {
        didSet {
            UserDefaults.standard.set(email, forKey: "email")
        }
    }
    @Published var licenseKey: String = UserDefaults.standard.string(forKey: "licenseKey") ?? "" {
        didSet {
            UserDefaults.standard.set(licenseKey, forKey: "licenseKey")
        }
    }
    @Published var licenseStatus: String = ""
    
    // MARK: - Private Properties
    private var screenObserver: AnyCancellable?
    
    // MARK: - Initialization
    init() {
        setupDefaults()
        loadState()
        setupScreenObserver()
    }
    
    // MARK: - Public Methods
    func resetSettings() {
        self.displaySettings = generateDisplaySettingsFromActiveScreens()
    }
    
    func updateDisplaySettings(for screenId: String, columns: Double, rows: Double) {
        displaySettings[screenId] = NSPoint(x: columns, y: rows)
    }
    
    // MARK: - Private Methods
    private func setupDefaults() {
        if UserDefaults.standard.bool(forKey: "defaultsSet") == false {
            createDefaultAccentColor()
            createDefaultDisplaySettings()
            UserDefaults.standard.set(true, forKey: "defaultsSet")
        }
    }
    
    private func loadState() {
        activeScreens = NSScreen.screens.map { $0.getIdString() }
        loadDisplaySettings()/Users/lyndon/Desktop/windy_app/windy/windyApp.swift
        loadAccentColor()
    }
    
    private func loadDisplaySettings() {
        do {
            let oldDisplaySettings = try UserDefaults.standard.getDictPoints(forKey: "displaySettings")
            let newDisplaySettings = generateDisplaySettingsFromActiveScreens()
            displaySettings = mergeDisplaySettings(left: oldDisplaySettings, right: newDisplaySettings)
        } catch {
            displaySettings = generateDisplaySettingsFromActiveScreens()
        }
    }
    
    private func loadAccentColor() {
        accentColour = UserDefaults.standard.color(forKey: "accentColour")
    }
    
    private func setupScreenObserver() {
        screenObserver = NotificationCenter.default.publisher(
            for: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared
        )
        .receive(on: OperationQueue.main)
        .sink { [weak self] _ in
            self?.handleScreenChange()
        }
    }
    
    private func handleScreenChange() {
        let oldDisplaySettings = self.displaySettings
        let newDisplaySettings = generateDisplaySettingsFromActiveScreens()
        displaySettings = mergeDisplaySettings(left: oldDisplaySettings, right: newDisplaySettings)
        activeScreens = NSScreen.screens.map { $0.getIdString() }
        
        if isShown {
            isShown = false
        }
    }
    
    private func storeDisplaySettings() {
        do {
            try UserDefaults.standard.set(dict: displaySettings, forKey: "displaySettings")
        } catch {
            debugPrint("Failed to store display settings")
        }
    }
    
    private func updateRects() {
        for (screenId, settings) in displaySettings {
            guard let screen = NSScreen.fromIdString(str: screenId) else { continue }
            let rects = createRects(
                columns: Double(settings.x),
                rows: Double(settings.y),
                screen: screen
            )
            rectsDict[screenId] = rects
        }
    }
    
    // MARK: - Helper Methods
    private func createDefaultAccentColor() {
        let defaultAccentColour = Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2)
        UserDefaults.standard.set(defaultAccentColour, forKey: "accentColour")
    }
    
    private func createDefaultDisplaySettings() {
        do {
            try UserDefaults.standard.set(
                dict: generateDisplaySettingsFromActiveScreens(),
                forKey: "displaySettings"
            )
        } catch {
            debugPrint("Failed to create default display settings")
        }
    }
} 