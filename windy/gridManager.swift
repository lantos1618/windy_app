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

func gridResizeLengths(totalLength: CGFloat, divisions: CGFloat) -> [CGFloat] {
    guard totalLength.isFinite, totalLength > 0, divisions.isFinite, divisions >= 1 else {
        return []
    }

    let divisionCount = max(1, Int(divisions.rounded()))
    let halfLength = totalLength / 2
    let tolerance = max(1.0, totalLength * 0.001)
    var lengths = (1...divisionCount).map { index in
        totalLength * CGFloat(index) / CGFloat(divisionCount)
    }

    if !lengths.contains(where: { abs($0 - halfLength) <= tolerance }) {
        lengths.append(halfLength)
    }

    return lengths.sorted()
}

func nextGridResizeLength(currentLength: CGFloat, totalLength: CGFloat, divisions: CGFloat) -> CGFloat {
    let lengths = gridResizeLengths(totalLength: totalLength, divisions: divisions)
    guard let smallest = lengths.first, let largest = lengths.last else {
        return currentLength
    }

    let tolerance = max(1.0, totalLength * 0.01)
    if currentLength <= smallest + tolerance {
        return largest
    }

    for length in lengths.reversed() where length < currentLength - tolerance {
        return length
    }

    return largest
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
            let minResizeWidth  = gridResizeLengths(totalLength: screenFrame.width, divisions: columns).first ?? minWidth
            let minResizeHeight = gridResizeLengths(totalLength: screenFrame.height, divisions: rows).first ?? minHeight

            // Resize window based on direction and current size
            switch direction {
            case .Left:
                size.width = nextGridResizeLength(currentLength: size.width, totalLength: screenFrame.width, divisions: columns)
            case .Right:
                size.width = nextGridResizeLength(currentLength: size.width, totalLength: screenFrame.width, divisions: columns)
                point.x = screenFrame.maxX - size.width
            case .Up:
                size.height = nextGridResizeLength(currentLength: size.height, totalLength: screenFrame.height, divisions: rows)
            case .Down:
                size.height = nextGridResizeLength(currentLength: size.height, totalLength: screenFrame.height, divisions: rows)
                point.y = screenFrame.maxY - size.height
            }
            
            // Clamp window size to screen bounds
            size.width  = round(size.width.clamp(to: minResizeWidth...screenFrame.width))
            size.height = round(size.height.clamp(to: minResizeHeight...screenFrame.height))
            
            // Clamp window position to screen bounds, accounting for window size
            point.x     = round(point.x.clamp(to: (screenFrame.minX)...(screenFrame.maxX - size.width)))
            point.y     = round(point.y.clamp(to: (screenFrame.minY)...(screenFrame.maxY - size.height)))

            // Set the window position and size
            try window.setTopLeftPoint(point: point)
            try window.setFrameSize(size: size)
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
