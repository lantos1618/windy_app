//
//  gridManager.swift
//  windy
//
//  Created by Lyndon Leong on 26/01/2023.
//

import Foundation
import SwiftUI
import Combine
import KeyboardShortcuts

// MARK: - Grid Visualization
struct GridView: View {
    // This needs to be redrawn every time
    // activeDisplayWindow is Changed
    // display rows/cols are updated
    @ObservedObject var windyData: WindyData;
    var screen: NSScreen
    
    var body: some View {
        let rects       = windyData.rectsDict[screen.getIdString()] ?? []
        
        let path        = Path {
            path in

            for col in 0..<rects.count {
                for row in 0..<rects[col].count {
                    path.addRect(rects[col][row].insetBy(dx: 5, dy: 5))
                }
            }
        }
        ZStack {
            path.fill(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.8))
            path.strokedPath(StrokeStyle(lineWidth: 1.0))
        }
    }
}

// MARK: - Grid Manager
class GridManager: ObservableObject {
    var windows                 : [String: NSWindow] = [:]
    var gridViews                : [String: GridView] = [:]
    var windyData               : WindyData
    var isShownListener         : AnyCancellable?
    var accentColorListener     : AnyCancellable?
    var activeScreenListener    : AnyCancellable?
   
    init(windyData: WindyData) {
        self.windyData = windyData
        
        // Initialize grid windows for each screen
        for screen in NSScreen.screens {
            let screenId = screen.getIdString()
            windows[screenId] = NSWindow(
                contentRect : ScreenGeometryService.appKitFrame(for: screen),
                styleMask   : [.fullSizeContentView, .resizable],
                backing     : .buffered,
                defer       : false
            )
            
            windows[screenId]?.backgroundColor      = NSColor(windyData.accentColour)
            gridViews[screenId] = GridView(windyData: windyData, screen: screen)
            //        set default preview rects
            windows[screenId]?.contentView          = NSHostingView(rootView: gridViews[screenId])
            windows[screenId]?.collectionBehavior   = .canJoinAllSpaces                     // allow window to be shown on all virtual desktops (spaces)
        }
            
        // Listen for accent color changes
        accentColorListener         = windyData.$accentColour.sink { accentColor in
            for key in self.windows.keys {
                self.windows[key]?.backgroundColor = NSColor(accentColor)
            }
        }
        
        // Listen for grid visibility changes
        isShownListener             = windyData.$isShown.sink { isShown in
            for key in self.windows.keys {
                guard let screen = NSScreen.fromIdString(str: key) else {
                    continue
                }
                self.windows[key]?.setIsVisible(isShown)
                self.windows[key]?.setFrame(ScreenGeometryService.appKitFrame(for: screen), display: true)
            }
        }
        
        // Listen for active screen changes
        activeScreenListener        = windyData.$activeSettingScreen.sink { screenId in
            for key in self.windows.keys {
                guard let screen = NSScreen.fromIdString(str: key) else {
                    continue
                }
                self.windows[key]?.setFrame(ScreenGeometryService.appKitFrame(for: screen), display: true)
            }
        }
    }

    // MARK: - Window Movement
    /// Moves a window by one grid cell in the specified direction
    /// Uses accessibility-space screen frames for AX window positioning.
    func move(window: WindyWindow, direction: Direction) throws {
        do {
            let screen      = try window.getScreen()
            let windowFrame = try window.getFrame()
            let screenFrame = ScreenGeometryService.accessibilityVisibleFrame(for: screen)
            let settings = GridLayoutSettings(
                point: windyData.displaySettings[screen.getIdString()] ?? NSPoint(x: 2.0, y: 2.0)
            )
            let newFrame = WindowLayoutEngine.movedFrame(
                windowFrame: windowFrame,
                screenFrame: screenFrame,
                settings: settings,
                direction: direction
            )
            
            do {
                try window.setTopLeftPoint(point: newFrame.origin)
            } catch {
                debugPrint("error \(error)")
            }
        }
    }
    
    // MARK: - Cross-Screen Window Movement
    /// Moves a window to the next screen in the specified direction
    func moveWindowNextScreen(direction: Direction) throws {
        let window              = try WindyWindow.currentWindow()
        let currentScreen       = try window.getScreen()

        guard let nextScreen = ScreenNavigator.nextScreen(from: currentScreen, direction: direction) else {
            return
        }

        try window.setTopLeftPoint(point: ScreenGeometryService.accessibilityVisibleFrame(for: nextScreen).origin)
    }
    
    // MARK: - Window Resizing
    /// Resizes a window based on grid layout and direction
    /// Contains workarounds for coordinate system conversion issues
    func resize(window: WindyWindow, direction: Direction) throws {
        do {
            let screen          = try window.getScreen()
            let windowFrame     = try window.getFrame()
            let screenFrame     = ScreenGeometryService.accessibilityVisibleFrame(for: screen)
            let settings = GridLayoutSettings(
                point: windyData.displaySettings[screen.getIdString()] ?? NSPoint(x: 2.0, y: 2.0)
            )
            let newFrame = WindowLayoutEngine.resizedFrame(
                windowFrame: windowFrame,
                screenFrame: screenFrame,
                settings: settings,
                direction: direction
            )

            // Set the window position and size
            try window.setTopLeftPoint(point: newFrame.origin)
            try window.setFrameSize(size: newFrame.size)
        } catch {
            debugPrint("error \(error)")
        }
    }
    
    // MARK: - Window Movement Handler
    /// Main handler for window movement - decides whether to move or resize
    /// Uses collision detection to determine appropriate action
    func handleWindowMovement(direction: Direction) {
        do {
                let window              = try WindyWindow.currentWindow()
                let windowFrame         = try window.getFrame()
                let screen              = try window.getScreen()
                
                // Convert screen coordinates to Quartz coordinate system for collision detection
                let screenFrame         = ScreenGeometryService.accessibilityVisibleFrame(for: screen)

            if WindowLayoutEngine.shouldResize(windowFrame: windowFrame, screenFrame: screenFrame, direction: direction) {
                try self.resize(window: window, direction: direction)
            } else {
                    try self.move(window: window, direction: direction)
                }
        } catch {
            debugPrint("error: \(error)")
        }
    }
   
    // MARK: - Cross-Screen Movement Handler
    /// Handler for moving windows between screens
    func handleWindowScreenMovement(direction: Direction) {
        do {
            try moveWindowNextScreen(direction: direction)
        }
        catch {
            debugPrint("error: \(error)")
        }
    }
    
    // MARK: - Event Registration
    /// Registers keyboard shortcuts for window management
    func registerEvents() {
        // Register keyboard shortcuts for window movement within screen
        KeyboardShortcuts.onKeyDown(for: .moveWindowLeft) { [self] in
            handleWindowMovement(direction: Direction.Left)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowRight) { [self] in
            handleWindowMovement(direction: Direction.Right)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowUp) { [self] in
            handleWindowMovement(direction: Direction.Up)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowDown) { [self] in
            handleWindowMovement(direction: Direction.Down)
        }
       
        // Register keyboard shortcuts for window movement between screens
        KeyboardShortcuts.onKeyDown(for: .moveWindowScreenLeft) { [self] in
            handleWindowScreenMovement(direction: Direction.Left)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowScreenRight) { [self] in
            handleWindowScreenMovement(direction: Direction.Right)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowScreenUp) { [self] in
            handleWindowScreenMovement(direction: Direction.Up)
        }
        KeyboardShortcuts.onKeyDown(for: .moveWindowScreenDown) { [self] in
            handleWindowScreenMovement(direction: Direction.Down)
        }
    }
}
