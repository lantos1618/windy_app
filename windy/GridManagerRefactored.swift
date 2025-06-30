//
//  GridManagerRefactored.swift
//  windy
//
//  Created by Lyndon Leong on 27/01/2023.
//

import Foundation
import SwiftUI
import Combine
import KeyboardShortcuts

// MARK: - Grid Visualization (Refactored)
struct GridViewRefactored: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var appState: AppState
    var screen: NSScreen
    
    var body: some View {
        let screenId = screen.getIdString()
        let gridSettings = settingsStore.getGridSettings(for: screenId)
        let rects = createGridRects(columns: gridSettings.columns, rows: gridSettings.rows, screen: screen)
        
        let path = Path { path in
            for col in 0..<rects.count {
                for row in 0..<rects[col].count {
                    path.addRect(rects[col][row].insetBy(dx: 5, dy: 5))
                }
            }
        }
        
        ZStack {
            path.fill(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: WindyConstants.UI.gridPreviewOpacity))
            path.strokedPath(StrokeStyle(lineWidth: 1.0))
        }
    }
    
    private func createGridRects(columns: Int, rows: Int, screen: NSScreen) -> [[NSRect]] {
        let screenFrameCG = CoordinateConverter.getScreenVisibleFrameCG(for: screen)
        let cellWidth = screenFrameCG.width / CGFloat(columns)
        let cellHeight = screenFrameCG.height / CGFloat(rows)
        
        var rects: [[NSRect]] = []
        
        for col in 0..<columns {
            var colRects: [NSRect] = []
            for row in 0..<rows {
                let x = screenFrameCG.minX + CGFloat(col) * cellWidth
                let y = screenFrameCG.minY + CGFloat(row) * cellHeight
                let rect = NSRect(x: x, y: y, width: cellWidth, height: cellHeight)
                colRects.append(rect)
            }
            rects.append(colRects)
        }
        
        return rects
    }
}

// MARK: - Grid Manager (Refactored)
/// Refactored GridManager that uses the new utilities to eliminate magic numbers and coordinate system issues
class GridManagerRefactored: ObservableObject {
    
    // MARK: - Properties
    private var windows: [String: NSWindow] = [:]
    private var gridViews: [String: GridViewRefactored] = [:]
    private var settingsStore: SettingsStore
    private var appState: AppState
    
    // MARK: - Combine Subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(settingsStore: SettingsStore, appState: AppState) {
        self.settingsStore = settingsStore
        self.appState = appState
        
        setupGridWindows()
        setupSubscriptions()
    }
    
    // MARK: - Setup Methods
    
    private func setupGridWindows() {
        for screen in NSScreen.screens {
            let screenId = screen.getIdString()
            
            // Create window with proper frame
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.fullSizeContentView, .resizable],
                backing: .buffered,
                defer: false
            )
            
            // Configure window properties
            window.backgroundColor = NSColor(settingsStore.accentColour)
            window.collectionBehavior = .canJoinAllSpaces
            
            // Create and set grid view
            let gridView = GridViewRefactored(settingsStore: settingsStore, appState: appState, screen: screen)
            window.contentView = NSHostingView(rootView: gridView)
            
            // Store references
            windows[screenId] = window
            gridViews[screenId] = gridView
        }
    }
    
    private func setupSubscriptions() {
        // Listen for accent color changes
        settingsStore.$accentColour
            .sink { [weak self] accentColor in
                for window in self?.windows.values ?? [] {
                    window.backgroundColor = NSColor(accentColor)
                }
            }
            .store(in: &cancellables)
        
        // Listen for grid visibility changes
        appState.$isGridPreviewVisible
            .sink { [weak self] isVisible in
                self?.updateGridVisibility(isVisible: isVisible)
            }
            .store(in: &cancellables)
        
        // Listen for screen changes
        appState.$activeScreens
            .sink { [weak self] _ in
                self?.handleScreenChange()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Grid Visibility Management
    
    private func updateGridVisibility(isVisible: Bool) {
        for (screenId, window) in windows {
            guard let screen = NSScreen.fromIdString(str: screenId) else { continue }
            
            window.setIsVisible(isVisible)
            if isVisible {
                window.setFrame(screen.frame, display: true)
            }
        }
    }
    
    private func handleScreenChange() {
        // Update windows for new screen configuration
        let currentScreenIds = Set(windows.keys)
        let newScreenIds = Set(appState.getActiveScreenIds())
        
        // Remove windows for disconnected screens
        for screenId in currentScreenIds {
            if !newScreenIds.contains(screenId) {
                windows.removeValue(forKey: screenId)
                gridViews.removeValue(forKey: screenId)
            }
        }
        
        // Add windows for new screens
        for screen in appState.activeScreens {
            let screenId = screen.getIdString()
            if !currentScreenIds.contains(screenId) {
                let window = NSWindow(
                    contentRect: screen.frame,
                    styleMask: [.fullSizeContentView, .resizable],
                    backing: .buffered,
                    defer: false
                )
                
                window.backgroundColor = NSColor(settingsStore.accentColour)
                window.collectionBehavior = .canJoinAllSpaces
                
                let gridView = GridViewRefactored(settingsStore: settingsStore, appState: appState, screen: screen)
                window.contentView = NSHostingView(rootView: gridView)
                
                windows[screenId] = window
                gridViews[screenId] = gridView
                
                if appState.isGridPreviewVisible {
                    window.setIsVisible(true)
                }
            }
        }
    }
    
    // MARK: - Window Movement (Refactored)
    
    /// Moves a window by one grid cell in the specified direction using proper coordinate conversion
    func move(window: WindyWindow, direction: Direction) throws {
        let screen = try window.getScreen()
        let screenId = screen.getIdString()
        let gridSettings = settingsStore.getGridSettings(for: screenId)
        
        // Get current window position and size
        var point = try window.getTopLeftPoint()
        let windowFrame = try window.getFrame()
        
        // Use proper coordinate conversion
        let screenFrameCG = CoordinateConverter.getScreenVisibleFrameCG(for: screen)
        let cellWidth = screenFrameCG.width / CGFloat(gridSettings.columns)
        let cellHeight = screenFrameCG.height / CGFloat(gridSettings.rows)
        
        // Convert window position to CoreGraphics coordinates for calculations
        let windowPointCG = CoordinateConverter.windowTopLeftAppKitToCG(point, on: screen)
        var newPointCG = windowPointCG
        
        // Move window by one grid cell in the specified direction
        switch direction {
        case .Left:
            newPointCG.x -= cellWidth
        case .Right:
            newPointCG.x += cellWidth
        case .Up:
            newPointCG.y -= cellHeight
        case .Down:
            newPointCG.y += cellHeight
        }
        
        // Clamp window position to screen bounds
        newPointCG.x = newPointCG.x.clamp(to: screenFrameCG.minX...(screenFrameCG.maxX - windowFrame.width))
        newPointCG.y = newPointCG.y.clamp(to: screenFrameCG.minY...(screenFrameCG.maxY - windowFrame.height))
        
        // Convert back to AppKit coordinates
        let newPoint = CoordinateConverter.windowTopLeftCGToAppKit(newPointCG, on: screen)
        
        try window.setTopLeftPoint(point: newPoint)
    }
    
    // MARK: - Cross-Screen Window Movement (Refactored)
    
    /// Moves a window to the next screen using robust screen detection
    func moveWindowNextScreen(direction: Direction) throws {
        let window = try WindyWindow.currentWindow()
        let currentScreen = try window.getScreen()
        
        // Convert Direction to ScreenDirection
        let screenDirection = convertDirection(direction)
        
        // Use ScreenManager for robust screen detection
        guard let nextScreen = ScreenManager.findNextScreen(from: currentScreen, in: screenDirection) else {
            // No screen in that direction, do nothing
            return
        }
        
        // Get the next screen's frame in CoreGraphics coordinates
        let nextScreenFrameCG = CoordinateConverter.getScreenVisibleFrameCG(for: nextScreen)
        
        // Convert the origin to AppKit coordinates for window positioning
        let nextScreenOrigin = CoordinateConverter.coreGraphicsToAppKit(point: nextScreenFrameCG.origin, on: nextScreen)
        
        try window.setTopLeftPoint(point: nextScreenOrigin)
    }
    
    // MARK: - Window Resizing (Refactored)
    
    /// Resizes a window based on grid layout and direction using proper coordinate conversion
    func resize(window: WindyWindow, direction: Direction) throws {
        let screen = try window.getScreen()
        let screenId = screen.getIdString()
        let gridSettings = settingsStore.getGridSettings(for: screenId)
        
        // Get current window position and size
        var point = try window.getTopLeftPoint()
        var size = try window.getSize()
        
        // Use proper coordinate conversion
        let screenFrameCG = CoordinateConverter.getScreenVisibleFrameCG(for: screen)
        let cellWidth = screenFrameCG.width / CGFloat(gridSettings.columns)
        let cellHeight = screenFrameCG.height / CGFloat(gridSettings.rows)
        
        // Convert window position to CoreGraphics coordinates for calculations
        let windowPointCG = CoordinateConverter.windowTopLeftAppKitToCG(point, on: screen)
        var newPointCG = windowPointCG
        var newSize = size
        
        // Resize window based on direction and current size
        switch direction {
        case .Left:
            newSize.width += cellWidth * (newSize.width <= cellWidth ? CGFloat(gridSettings.columns - 1) : -1.0)
            
        case .Right:
            newSize.width += cellWidth * (newSize.width <= cellWidth ? CGFloat(gridSettings.columns - 1) : -1.0)
            newPointCG.x = screenFrameCG.maxX - newSize.width
            
        case .Up:
            newSize.height += cellHeight * (newSize.height <= cellHeight ? CGFloat(gridSettings.rows - 1) : -1.0)
            
        case .Down:
            newSize.height += cellHeight * (newSize.height <= cellHeight ? CGFloat(gridSettings.rows - 1) : -1.0)
            newPointCG.y = screenFrameCG.maxY - newSize.height
        }
        
        // Clamp window size to screen bounds
        newSize.width = newSize.width.clamp(to: cellWidth...screenFrameCG.width)
        newSize.height = newSize.height.clamp(to: cellHeight...screenFrameCG.height)
        
        // Clamp window position to screen bounds
        newPointCG.x = newPointCG.x.clamp(to: screenFrameCG.minX...(screenFrameCG.maxX - newSize.width))
        newPointCG.y = newPointCG.y.clamp(to: screenFrameCG.minY...(screenFrameCG.maxY - newSize.height))
        
        // Convert back to AppKit coordinates
        let newPoint = CoordinateConverter.windowTopLeftCGToAppKit(newPointCG, on: screen)
        
        // Set the window position and size
        try window.setTopLeftPoint(point: newPoint)
        try window.setFrameSize(size: newSize)
    }
    
    // MARK: - Window Movement Handler (Refactored)
    
    /// Main handler for window movement using proper collision detection
    func handleWindowMovement(direction: Direction) {
        do {
            let window = try WindyWindow.currentWindow()
            let windowFrame = try window.getFrame()
            let screen = try window.getScreen()
            
            // Use proper coordinate conversion for collision detection
            let screenFrameCG = CoordinateConverter.getScreenVisibleFrameCG(for: screen)
            let windowFrameCG = CoordinateConverter.appKitToCoreGraphics(rect: windowFrame, on: screen)
            
            // Check if window can move in the direction
            let canMove = !windowFrameCG.collisionsInside(rect: screenFrameCG).contains(direction)
            
            // If window can move in the direction, move it; otherwise resize it
            if canMove || windowFrameCG.collisionsInside(rect: screenFrameCG).isEmpty {
                try move(window: window, direction: direction)
            } else {
                try resize(window: window, direction: direction)
            }
        } catch {
            debugPrint("Window movement error: \(error)")
        }
    }
    
    // MARK: - Cross-Screen Movement Handler (Refactored)
    
    /// Handler for moving windows between screens using robust screen detection
    func handleWindowScreenMovement(direction: Direction) {
        do {
            try moveWindowNextScreen(direction: direction)
        } catch {
            debugPrint("Cross-screen movement error: \(error)")
        }
    }
    
    // MARK: - Event Registration (Refactored)
    
    /// Registers keyboard shortcuts for window management
    func registerEvents() {
        // Register keyboard shortcuts for window movement within screen
        KeyboardShortcuts.onKeyDown(for: .moveWindowLeft) { [weak self] in
            self?.handleWindowMovement(direction: .Left)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowRight) { [weak self] in
            self?.handleWindowMovement(direction: .Right)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowUp) { [weak self] in
            self?.handleWindowMovement(direction: .Up)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowDown) { [weak self] in
            self?.handleWindowMovement(direction: .Down)
        }
        
        // Register keyboard shortcuts for window movement between screens
        KeyboardShortcuts.onKeyDown(for: .moveWindowScreenLeft) { [weak self] in
            self?.handleWindowScreenMovement(direction: .Left)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowScreenRight) { [weak self] in
            self?.handleWindowScreenMovement(direction: .Right)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowScreenUp) { [weak self] in
            self?.handleWindowScreenMovement(direction: .Up)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowScreenDown) { [weak self] in
            self?.handleWindowScreenMovement(direction: .Down)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Convert Direction enum to ScreenDirection enum
    private func convertDirection(_ direction: Direction) -> ScreenDirection {
        switch direction {
        case .Left: return .left
        case .Right: return .right
        case .Up: return .up
        case .Down: return .down
        }
    }
} 