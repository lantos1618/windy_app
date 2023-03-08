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



struct ScreensManager {
    
}

struct GridView: View {
    // this needs to be redrawn every time
    // activeDisplayWindow is Changed
    // display rows/cols are updated
    @ObservedObject var windyData: WindyData;
    var screen: NSScreen
    
    var body: some View {
        let rects       = windyData.rectsDict[screen.getIdString()] ?? []
        
        let path        = Path {
//            path in
//            var rects = [NSRect]()
//
//            for screen in NSScreen.screens {
//                var frame = screen.getQuartsSafeFrame()
//
//                frame.origin.x = frame.origin.x / 3
//                frame.origin.y = frame.origin.y / 3
//                frame.size.width = frame.size.width / 3
//                frame.size.height  = frame.size.height / 3
//                rects.append(frame)
//            }
//            for rect in rects {
//                path.addRect(rect)
//            }
        
        
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


// this should be split into its own data class
class GridManager: ObservableObject {
    var windows                 : [String: NSWindow] = [:]
    var gridViews                : [String: GridView] = [:]
    var windyData               : WindyData
    var isShownListener         : AnyCancellable?
    var accentColorListener     : AnyCancellable?
    var activeScreenListener    : AnyCancellable?
   
    
    init(windyData: WindyData) {
        self.windyData = windyData
        
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
            
        
        accentColorListener         = windyData.$accentColour.sink { accentColor in
            for key in self.windows.keys {
                self.windows[key]?.backgroundColor = NSColor(accentColor)
            }
        }
        isShownListener             = windyData.$isShown.sink { isShown in
            print("windows", self.windows.keys)
            for key in self.windows.keys {
                let screen = NSScreen.fromIdString(str: key) ?? NSScreen.main!
                self.windows[key]?.setIsVisible(isShown)
                self.windows[key]?.setFrame(screen.frame, display: true)
            }
        }
        activeScreenListener        = windyData.$activeSettingScreen.sink { screenId in
            for key in self.windows.keys {
                self.windows[key]?.setFrame((NSScreen.fromIdString(str: key) ?? NSScreen.main!).frame, display: true)

            }
        }
    }

    
    func move(window: WindyWindow, direction: Direction) throws {
        do {
            debugPrint("moving: ", direction)
            let screen      = try window.getScreen()
            var point       = try window.getTopLeftPoint()
            let windowFrame = try window.getFrame()
            let screenFrame = screen.getQuartsSafeFrame()
            
            let settings    = windyData.displaySettings[screen.getIdString()] ?? NSPoint(x: 2.0, y: 2.0)
            let columns     = settings.x
            let rows        = settings.y
            let minWidth    = round(screenFrame.width / columns)
            let minHeight   = round(screenFrame.height / rows)
            
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
            
            point.x = round(point.x.clamp(to: screenFrame.minX...(screenFrame.maxX-windowFrame.width)))
            point.y = round(point.y.clamp(to: screenFrame.minY...(screenFrame.maxY-windowFrame.height)))
            
            do {
                try window.setTopLeftPoint(point: point)
            } catch {
                debugPrint("error \(error)")
            }
        }
    }
    
    func moveWindowNextScreen(direction: Direction) throws {
        // this is messy but should be fine
        let window              = try WindyWindow.currentWindow()
        let currentScreen       = try window.getScreen()
        let screens             = NSScreen.screens
        let tScreens            = screens.filter({ screen in screen.getIdString() != currentScreen.getIdString()})
        let tCurrQPoint         = currentScreen.getQuartsSafeFrame().centerPoint()
        let max_check           = 10_000
        
        // calculate the next screen
        debugPrint("moving window to next screen", direction)
        switch direction {
            case .Left:
            // I need a raycast but I'll just cheat it...
            for screen in tScreens {
                var i = 10;
                while i < max_check {
                    let screenQFrame = screen.getQuartsSafeFrame()
                    var testCurrQPoint = tCurrQPoint
                    testCurrQPoint.x -= CGFloat(i)
//                    debugPrint("contains \(screen.getIdString())", testCurrQPoint, screenQFrame, screenQFrame.contains(testCurrQPoint))
                    if (screenQFrame.contains(testCurrQPoint)) {
                        try window.setTopLeftPoint(point: screenQFrame.origin)
                        return

                    }
                    i += 100
                }
            }
            case .Right:
            for screen in screens.filter({ screen in screen.getIdString() != currentScreen.getIdString()}) {
                var i = 10;
                while i < max_check {
                    let screenQFrame = screen.getQuartsSafeFrame()
                    var testCurrQPoint = tCurrQPoint
                    testCurrQPoint.x += CGFloat(i)
//                    debugPrint("contains \(screen.getIdString())", testCurrQPoint, screenQFrame, screenQFrame.contains(testCurrQPoint))
                    if (screenQFrame.contains(testCurrQPoint)) {
                        try window.setTopLeftPoint(point: screenQFrame.origin)
                        return

                    }
                    i += 100
                }
            }
            case .Up:
            for screen in tScreens {
                var i = 10;
                while i < max_check {
                    let screenQFrame = screen.getQuartsSafeFrame()
                    var testCurrQPoint = tCurrQPoint
                    testCurrQPoint.y -= CGFloat(i)
//                    debugPrint("contains \(screen.getIdString())", testCurrQPoint, screenQFrame, screenQFrame.contains(testCurrQPoint))
                    if (screenQFrame.contains(testCurrQPoint)) {
                        try window.setTopLeftPoint(point: screenQFrame.origin)
                        return

                    }
                    i += 100
                }
            }
            case .Down:
            for screen in tScreens {
                var i = 10;
                while i < max_check {
                    let screenQFrame = screen.getQuartsSafeFrame()
                    var testCurrQPoint = tCurrQPoint
                    testCurrQPoint.y += CGFloat(i)
//                    debugPrint("contains \(screen.getIdString())", testCurrQPoint, screenQFrame, screenQFrame.contains(testCurrQPoint))
                    if (screenQFrame.contains(testCurrQPoint)) {
                        try window.setTopLeftPoint(point: screenQFrame.origin)
                        return

                    }
                    i += 100
                }
            }
        }
        
       
    }
    
    func resize(window: WindyWindow, direction: Direction) throws {
        do {
            debugPrint("resizing: ", direction)
            let screen          = try window.getScreen()
            var point           = try window.getTopLeftPoint()
            var size            = try window.getSize()
            let settings        = windyData.displaySettings[screen.getIdString()] ?? NSPoint(x: 2.0, y: 2.0)
            let columns         = settings.x
            let rows            = settings.y
            let screenFrame     = screen.getQuartsSafeFrame()
            let minWidth        = round(screenFrame.width / columns)
            let minHeight       = round(screenFrame.height / rows)
            let errorX          = minWidth * 0.30  // this is caused by the quarts safeFrame. workaround.
            let errorY          = minHeight * 0.30  // this is caused by the quarts safeFrame. workaround.

            // convert screen to quarts
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
            
            size.width  = round(size.width.clamp(to: minWidth...screenFrame.width))
            size.height = round(size.height.clamp(to: minHeight...screenFrame.height))

            debugPrint("point, size", point, size)
            point.x     = round(point.x.clamp(to: (screenFrame.minX)...(screenFrame.maxX - size.width)))
            point.y     = round(point.y.clamp(to: (screenFrame.minY)...(screenFrame.maxY - size.height)))
            
            debugPrint("point, size", point, size)

            // set the window pos and size
            
            try window.setTopLeftPoint(point: point)
            // workaround
            if (direction == .Down) {
                var tSize = size
                tSize.width  -= errorX
                tSize.height -= errorY
                try window.setFrameSize(size: tSize)
            }
            try window.setFrameSize(size: size)
            

            debugPrint("final", try window.getFrame())
            // todo? set the window pos based on the final achieved size?
            
        } catch {
            debugPrint("error \(error)")
        }
    }
    
    func handleWindowMovement(direction: Direction) {
        do {
                let window              = try WindyWindow.currentWindow()
                let windowFrame         = try window.getFrame()
                let screen              = try window.getScreen()
                let screenFrame         = screen.getQuartsSafeFrame()
                
                let windowCollisions    = windowFrame.collisionsInside(rect: screenFrame)
                let canMove             = !windowCollisions.contains(direction)
                debugPrint("windowCollisions", windowCollisions)
                debugPrint("can move", canMove)

                if canMove || windowCollisions.isEmpty {
                    try self.move(window: window, direction: direction)
                    return
                }
                try self.resize(window: window, direction: direction)
        } catch {
            debugPrint("error: \(error)")
        }
    }
   
    func handleWindowScreenMovement(direction: Direction) {
        do {
            try moveWindowNextScreen(direction: direction)
        }
        catch {
            debugPrint("error: \(error)")
        }
    }
    
//    func globalKeyEventHandler(event: NSEvent) {
//        if (event.modifierFlags.contains([.option, .control])) {
//            guard let direction     = event.direction else { return }
//            handleMovement(direction: direction)
//        }
//    }
    

    func registerEvents() {
//        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: self.globalKeyEventHandler)
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
