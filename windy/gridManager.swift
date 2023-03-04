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
            path in
            for col in 0..<rects.count {
                for row in 0..<rects[col].count {
                    path.addRect(rects[col][row].insetBy(dx: 10, dy: 10))
                }
            }
        }
        path.fill(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.8))
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
    
    func moveWindow(window: WindyWindow, direction: Direction) throws {
        // TODO
        // determine the closest size
        // if can move      -> move to next rect
        // if can not move  -> resize and then put to last or first index
    }
    
    func resizeWindow(window: WindyWindow, direction: Direction) throws {
        // TODO
    }
   
    
    func move(window: WindyWindow, direction: Direction) throws {
        do {
            let screen      = NSScreen.main!
            var point       = try window.getTopLeftPoint()
            
            let settings    = windyData.displaySettings[screen.getIdString()] ?? NSPoint(x: 2.0, y: 2.0)
            let columns     = settings.x
            let rows        = settings.y
            let minWidth    = screen.frame.maxX / columns
            let minHeight   = screen.frame.maxY / rows
            
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
            
            // we have the new target point we should now move it
            
            point.x = point.x.clamp(to: screen.frame.minX...(screen.frame.maxX-minWidth))
            point.y = point.y.clamp(to: screen.frame.minY...(screen.frame.maxY))
            
            do {
                try window.setTopLeftPoint(point: point)
            } catch {
                print("error \(error)")
            }
        }
    }
    
    func resize(window: WindyWindow, direction: Direction) throws {
        do {
            let screen      = NSScreen.main!
            var point       = try window.getBottomLeftPoint()
            var size        = try window.getSize()
            let columns     = 2.0
            let rows        = 2.0
            let minWidth    = screen.frame.maxX / columns
            let minHeight   = screen.frame.maxY / rows

            switch direction {
            case .Left:
                size.width  += minWidth * (size.width <= minWidth ? columns : -1.0)
            case .Right:
                size.width  += minWidth * (size.width <= minWidth ? columns : -1.0)
                point.x     -= size.width
            case .Up:
                size.height += minHeight * (size.height <= minHeight ? rows : -1.0)
            case .Down:
                size.height += minHeight * (size.height <= minHeight ? rows : -1.0)
            }
            let frame = NSRect(origin: point, size: size)
            try window.setFrame(frame: frame)
        } catch {
            print("error \(error)")
        }
    }
    
    func globalKeyEventHandler(event: NSEvent) {
        do {
            if (event.modifierFlags.contains([.option, .control])) {
                guard let direction     = event.direction else { return }
                let window              = try WindyWindow.currentWindow()
                let windowFrame         = try window.getFrame()
                let screenFrame         = try window.getScreen().frame
                let windowCollisions    = windowFrame.collisionsInside(rect: screenFrame)
                let canMove             = !windowCollisions.contains(direction)
                print("move direction", direction)
                print("windowCollisions", windowCollisions)
                print("can move", canMove)
                
                if canMove || windowCollisions.isEmpty {
//                    try self.moveWindow(window: window, direction: direction)
                    try self.move(window: window, direction: direction)
                    return
                }
//                try self.resizeWindow(window: window, direction: direction)
//                try self.resize(window: window, direction: direction)
            }
        } catch {
            print("error: \(error)")
        }
    }
    

    func registerEvents() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: self.globalKeyEventHandler)
    }
}
