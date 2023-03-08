//
//  gridManager.swift
//  windy
//
//  Created by Lyndon Leong on 26/01/2023.
//

import Foundation
import SwiftUI
import Combine


struct GridView: View {
    // this needs to be redrawn every time
    // activeDisplayWindow is Changed
    // display rows/cols are updated
    @ObservedObject var windyData: WindyData;

    
    var body: some View {
        let rects       = windyData.previewRects
        
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
    var window                  : NSWindow
    var gridView                : GridView
    var windyData               : WindyData
    var isShownListener         : AnyCancellable?
    var accentColorListener     : AnyCancellable?
    var activeScreenListener    : AnyCancellable?
   
    
    init(windyData: WindyData) {
        self.windyData = windyData
        window = NSWindow(
            contentRect : NSScreen.main!.frame,
            styleMask   : [.fullSizeContentView, .resizable],
            backing     : .buffered,
            defer       : false
        )
        
        window.backgroundColor      = NSColor(windyData.accentColour)
        gridView                    = GridView(windyData: windyData)
        //        set default preview rects
        windyData.previewRects      = windyData.rectsDict[windyData.activeSettingScreen] ?? []
        window.contentView          = NSHostingView(rootView: gridView)
        window.collectionBehavior   = .canJoinAllSpaces                     // allow window to be shown on all virtual desktops (spaces)
        
        accentColorListener         = windyData.$accentColour.sink { accentColor in
            self.window.backgroundColor = NSColor(accentColor)
        }
        isShownListener             = windyData.$isShown.sink { isShown in
            let screen = NSScreen.fromIdString(str: windyData.activeSettingScreen) ?? NSScreen.main!
            self.window.setIsVisible(isShown)
            self.window.setFrame(screen.frame, display: true)
        }
        activeScreenListener        = windyData.$activeSettingScreen.sink { screenId in
            self.window.setFrame( (NSScreen.fromIdString(str: screenId) ?? NSScreen.main!).frame, display: true)
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
            
            
            debugPrint("point", point)
            do {
                try window.setTopLeftPoint(point: point)
            } catch {
                debugPrint("error \(error)")
            }
        }
    }
    
    func resize(window: WindyWindow, direction: Direction) throws {
        do {
            debugPrint("resizing: ", direction)
            let screen      = try window.getScreen()
            var point       = try window.getTopLeftPoint()
            var size        = try window.getSize()
            let settings    = windyData.displaySettings[screen.getIdString()] ?? NSPoint(x: 2.0, y: 2.0)
            let columns     = settings.x
            let rows        = settings.y
            let screenFrame = screen.getQuartsSafeFrame()
            let minWidth    = round(screenFrame.width / columns)
            let minHeight   = round(screenFrame.height / rows)
            let errorX       = minWidth * 0.30  // this is caused by the quarts safeFrame. workaround.
            let errorY       = minHeight * 0.30  // this is caused by the quarts safeFrame. workaround.

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
                size.height += minHeight * (size.height <= (minHeight + errorY) ? rows - 1.0 : -1.0)
                point.y     = screenFrame.maxY - (size.height)

            }
            
            size.width  = round(size.width.clamp(to: minWidth...screenFrame.width))
            size.height = round(size.height.clamp(to: minHeight...screenFrame.height))

            point.x     = round(point.x.clamp(to: (screenFrame.minX)...(screenFrame.maxX - size.width)))
            point.y     = round(point.y.clamp(to: (screenFrame.minY)...(screenFrame.maxY - size.height)))
            
            
            // set the window pos and size
            try window.setTopLeftPoint(point: point)
            try window.setFrameSize(size: size)
            // todo? set the window pos based on the final achieved size?
            
            
            
            
        } catch {
            debugPrint("error \(error)")
        }
    }
    
    func globalKeyEventHandler(event: NSEvent) {
        do {
            if (event.modifierFlags.contains([.option, .control])) {
                guard let direction     = event.direction else { return }
                let window              = try WindyWindow.currentWindow()
                let windowFrame         = try window.getFrame()
                let screen              = try window.getScreen()
                var screenFrame         = screen.getQuartsSafeFrame()
                
                let windowCollisions    = windowFrame.collisionsInside(rect: screenFrame)
                let canMove             = !windowCollisions.contains(direction)
                debugPrint("windowCollisions", windowCollisions)
                debugPrint("can move", canMove)
//
//                try window.setTopLeftPoint(point: screenFrame.origin)
//                try window.setFrameSize(size: screenFrame.size)
                
                if canMove || windowCollisions.isEmpty {
                    try self.move(window: window, direction: direction)
                    return
                }
                try self.resize(window: window, direction: direction)
            }
        } catch {
            debugPrint("error: \(error)")
        }
    }
    

    func registerEvents() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: self.globalKeyEventHandler)
    }
}
