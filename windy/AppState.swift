//
//  AppState.swift
//  windy
//
//  Created by Lyndon Leong on 27/01/2023.
//

import Foundation
import AppKit

// MARK: - App State
/// Manages transient, non-persistent application state for the Windy app
class AppState: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isGridPreviewVisible: Bool = false
    @Published var activeScreens: [NSScreen] = []
    @Published var activeSettingScreen: String = ""
    
    // MARK: - Private Properties
    private var screenChangeObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    init() {
        updateActiveScreens()
        setupScreenChangeObserver()
        
        // Set initial active setting screen
        if let mainScreen = NSScreen.main {
            activeSettingScreen = mainScreen.getIdString()
        }
    }
    
    deinit {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    
    /// Toggle the grid preview visibility
    func toggleGridPreview() {
        isGridPreviewVisible.toggle()
    }
    
    /// Show the grid preview
    func showGridPreview() {
        isGridPreviewVisible = true
    }
    
    /// Hide the grid preview
    func hideGridPreview() {
        isGridPreviewVisible = false
    }
    
    /// Update the active setting screen
    func setActiveSettingScreen(_ screenId: String) {
        activeSettingScreen = screenId
    }
    
    /// Get the currently active setting screen
    func getActiveSettingScreen() -> String {
        return activeSettingScreen
    }
    
    /// Get all active screen IDs as strings
    func getActiveScreenIds() -> [String] {
        return activeScreens.map { $0.getIdString() }
    }
    
    /// Check if a screen is currently connected
    func isScreenConnected(_ screenId: String) -> Bool {
        return getActiveScreenIds().contains(screenId)
    }
    
    /// Get screen by ID
    func getScreen(by id: String) -> NSScreen? {
        return activeScreens.first { $0.getIdString() == id }
    }
    
    // MARK: - Private Methods
    
    private func updateActiveScreens() {
        activeScreens = NSScreen.screens
        
        // Ensure active setting screen is still valid
        if !isScreenConnected(activeSettingScreen) {
            if let mainScreen = NSScreen.main {
                activeSettingScreen = mainScreen.getIdString()
            } else if !activeScreens.isEmpty {
                activeSettingScreen = activeScreens[0].getIdString()
            }
        }
    }
    
    private func setupScreenChangeObserver() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared,
            queue: OperationQueue.main
        ) { [weak self] _ in
            self?.handleScreenChange()
        }
    }
    
    private func handleScreenChange() {
        let oldActiveScreens = Set(activeScreens.map { $0.getIdString() })
        updateActiveScreens()
        let newActiveScreens = Set(getActiveScreenIds())
        
        // If screens changed, hide grid preview to refresh
        if oldActiveScreens != newActiveScreens {
            hideGridPreview()
        }
    }
} 