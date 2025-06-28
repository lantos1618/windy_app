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

// MARK: - Screen Management
struct ScreensManager {
    // TODO: Implement screen management functionality
    // This could handle multi-monitor setups more robustly
}

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
// This should be split into its own data class
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
            windows[screen.getIdString()] = NSWindow(
                contentRect : NSScreen.main!.frame,
                styleMask   : [.fullSizeContentView, .resizable],
                backing     : .buffered,
                defer       : false
            )
            
            windows[screen.getIdString()]!.backgroundColor      = NSColor(windyData.accentColour)
            gridViews[screen.getIdString()] = GridView(windyData: windyData, screen: screen)
            //        set default preview rects
            windows[screen.getIdString()]?.contentView          = NSHostingView(rootView: gridViews[screen.getIdString()])
            windows[screen.getIdString()]?.collectionBehavior   = .canJoinAllSpaces                     // allow window to be shown on all virtual desktops (spaces)
        }
            
        // Listen for accent color changes
        accentColorListener         = windyData.$accentColour.sink { accentColor in
            for key in self.windows.keys {
                self.windows[key]?.backgroundColor = NSColor(accentColor)
            }
        }
        
        // Listen for grid visibility changes
        isShownListener             = windyData.$isShown.sink { isShown in
            print("windows", self.windows.keys)
            for key in self.windows.keys {
                let screen = NSScreen.fromIdString(str: key) ?? NSScreen.main!
                self.windows[key]?.setIsVisible(isShown)
                self.windows[key]?.setFrame(screen.frame, display: true)
            }
        }
        
        // Listen for active screen changes
        activeScreenListener        = windyData.$activeSettingScreen.sink { screenId in
            for key in self.windows.keys {
                self.windows[key]?.setFrame((NSScreen.fromIdString(str: key) ?? NSScreen.main!).frame, display: true)
            }
        }
    }

    // MARK: - Window Movement
    /// Moves a window by one grid cell in the specified direction
    /// Uses coordinate system conversions from getQuartsSafeFrame()
    func move(window: WindyWindow, direction: Direction) throws {
        do {
            debugPrint("moving: ", direction)
            let screen      = try window.getScreen()
            var point       = try window.getTopLeftPoint()
            let windowFrame = try window.getFrame()
            
            // Convert screen coordinates to Quartz coordinate system for accurate positioning
            let screenFrame = screen.getQuartsSafeFrame()
            
            let settings    = windyData.displaySettings[screen.getIdString()] ?? NSPoint(x: 2.0, y: 2.0)
            let columns     = settings.x
            let rows        = settings.y
            let minWidth    = round(screenFrame.width / columns)
            let minHeight   = round(screenFrame.height / rows)
            
            // Move window by one grid cell in the specified direction
            switch direction {
            case .Left:
                point.x -= minWidth
            case .Right:
                point.x += minWidth
            case .Up:
                point.y -= minHeight
            case .Down:
                point.y += minHeight
            }
            
            // Clamp window position to screen bounds, accounting for window size
            point.x = round(point.x.clamp(to: screenFrame.minX...(screenFrame.maxX-windowFrame.width)))
            point.y = round(point.y.clamp(to: screenFrame.minY...(screenFrame.maxY-windowFrame.height)))
            
            do {
                try window.setTopLeftPoint(point: point)
            } catch {
                debugPrint("error \(error)")
            }
        }
    }
    
    // MARK: - Cross-Screen Window Movement
    /// Moves a window to the next screen in the specified direction
    /// Uses raycasting-like algorithm to find the next screen
    func moveWindowNextScreen(direction: Direction) throws {
        // This is messy but should be fine
        let window              = try WindyWindow.currentWindow()
        let currentScreen       = try window.getScreen()
        let screens             = NSScreen.screens
        let tScreens            = screens.filter({ screen in screen.getIdString() != currentScreen.getIdString()})
        let tCurrQPoint         = currentScreen.getQuartsSafeFrame().centerPoint()
        
        // MAGIC NUMBER: Maximum distance to check for next screen
        // This is a workaround for not having proper screen adjacency detection
        // TODO: Replace with proper screen adjacency detection
        let max_check           = 10_000
        
        // Calculate the next screen using raycasting-like approach
        debugPrint("moving window to next screen", direction)
        switch direction {
            case .Left:
            // I need a raycast but I'll just cheat it...
            for screen in tScreens {
                var i = 10; // MAGIC NUMBER: Starting offset for raycast
                while i < max_check {
                    let screenQFrame = screen.getQuartsSafeFrame()
                    var testCurrQPoint = tCurrQPoint
                    testCurrQPoint.x -= CGFloat(i)
                    if (screenQFrame.contains(testCurrQPoint)) {
                        try window.setTopLeftPoint(point: screenQFrame.origin)
                        return
                    }
                    i += 100 // MAGIC NUMBER: Raycast step size
                }
            }
            case .Right:
            for screen in screens.filter({ screen in screen.getIdString() != currentScreen.getIdString()}) {
                var i = 10; // MAGIC NUMBER: Starting offset for raycast
                while i < max_check {
                    let screenQFrame = screen.getQuartsSafeFrame()
                    var testCurrQPoint = tCurrQPoint
                    testCurrQPoint.x += CGFloat(i)
                    if (screenQFrame.contains(testCurrQPoint)) {
                        try window.setTopLeftPoint(point: screenQFrame.origin)
                        return
                    }
                    i += 100 // MAGIC NUMBER: Raycast step size
                }
            }
            case .Up:
            for screen in tScreens {
                var i = 10; // MAGIC NUMBER: Starting offset for raycast
                while i < max_check {
                    let screenQFrame = screen.getQuartsSafeFrame()
                    var testCurrQPoint = tCurrQPoint
                    testCurrQPoint.y -= CGFloat(i)
                    if (screenQFrame.contains(testCurrQPoint)) {
                        try window.setTopLeftPoint(point: screenQFrame.origin)
                        return
                    }
                    i += 100 // MAGIC NUMBER: Raycast step size
                }
            }
            case .Down:
            for screen in tScreens {
                var i = 10; // MAGIC NUMBER: Starting offset for raycast
                while i < max_check {
                    let screenQFrame = screen.getQuartsSafeFrame()
                    var testCurrQPoint = tCurrQPoint
                    testCurrQPoint.y += CGFloat(i)
                    if (screenQFrame.contains(testCurrQPoint)) {
                        try window.setTopLeftPoint(point: screenQFrame.origin)
                        return
                    }
                    i += 100 // MAGIC NUMBER: Raycast step size
                }
            }
        }
    }
    
    // MARK: - Window Resizing
    /// Resizes a window based on grid layout and direction
    /// Contains workarounds for coordinate system conversion issues
    func resize(window: WindyWindow, direction: Direction) throws {
        do {
            debugPrint("resizing: ", direction)
            let screen          = try window.getScreen()
            var point           = try window.getTopLeftPoint()
            var size            = try window.getSize()
            let settings        = windyData.displaySettings[screen.getIdString()] ?? NSPoint(x: 2.0, y: 2.0)
            let columns         = settings.x
            let rows            = settings.y
            
            // Convert screen coordinates to Quartz coordinate system
            let screenFrame     = screen.getQuartsSafeFrame()
            let minWidth        = round(screenFrame.width / columns)
            let minHeight       = round(screenFrame.height / rows)
            
            // MAGIC NUMBERS: Error correction factors for coordinate system conversion issues
            // These are workarounds for the getQuartsSafeFrame() coordinate conversion
            // TODO: Investigate why these error factors are needed and eliminate them
            let errorX          = minWidth * 0.30  // 30% error correction for X-axis
            let errorY          = minHeight * 0.30  // 30% error correction for Y-axis

            // Resize window based on direction and current size
            switch direction {
            case .Left:
                size.width  += minWidth * (size.width <= (minWidth + errorX) ? columns - 1.0 : -1.0)
            case .Right:
                size.width  += minWidth * (size.width <= (minWidth + errorX) ? columns - 1.0 : -1.0)
                point.x     = screenFrame.maxX - (size.width)
            case .Up:
                size.height += minHeight * (size.height <= (minHeight + errorY) ? rows - 1.0 : -1.0)
            case .Down:
                debugPrint("point, size", point, size)
                size.height += minHeight * (size.height <= (minHeight + errorY) ? rows - 1.0 : -1.0)
                point.y     = screenFrame.maxY - (size.height)
                debugPrint("max", screenFrame.maxY , (size.height) )
                debugPrint("point, size", point, size)
            }
            
            // Clamp window size to screen bounds
            size.width  = round(size.width.clamp(to: minWidth...screenFrame.width))
            size.height = round(size.height.clamp(to: minHeight...screenFrame.height))

            debugPrint("point, size", point, size)
            
            // Clamp window position to screen bounds, accounting for window size
            point.x     = round(point.x.clamp(to: (screenFrame.minX)...(screenFrame.maxX - size.width)))
            point.y     = round(point.y.clamp(to: (screenFrame.minY)...(screenFrame.maxY - size.height)))
            
            debugPrint("point, size", point, size)

            // Set the window position and size
            try window.setTopLeftPoint(point: point)
            
            // WORKAROUND: Special handling for Down direction due to coordinate system issues
            // This applies error correction factors to compensate for getQuartsSafeFrame() conversion
            if (direction == .Down) {
                var tSize = size
                tSize.width  -= errorX
                tSize.height -= errorY
                try window.setFrameSize(size: tSize)
            }
            try window.setFrameSize(size: size)
            

            debugPrint("final", try window.getFrame())
            // TODO: Set the window position based on the final achieved size?
            
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
                let screenFrame         = screen.getQuartsSafeFrame()
                
                let windowCollisions    = windowFrame.collisionsInside(rect: screenFrame)
                let canMove             = !windowCollisions.contains(direction)
                debugPrint("windowCollisions", windowCollisions)
                debugPrint("can move", canMove)

                // If window can move in the direction, move it; otherwise resize it
                if canMove || windowCollisions.isEmpty {
                    try self.move(window: window, direction: direction)
                    return
                }
                try self.resize(window: window, direction: direction)
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
    
    // TODO: Implement global key event handler
    // This would provide more direct control over window management
//    func globalKeyEventHandler(event: NSEvent) {
//        if (event.modifierFlags.contains([.option, .control])) {
//            guard let direction     = event.direction else { return }
//            handleMovement(direction: direction)
//        }
//    }
    

    // MARK: - Event Registration
    /// Registers keyboard shortcuts for window management
    func registerEvents() {
        // TODO: Implement global key event handler for more direct control
//        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: self.globalKeyEventHandler)
        
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
