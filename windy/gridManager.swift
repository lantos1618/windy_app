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
    @ObservedObject var windyData: WindyData
    
    var body: some View {
        let path = Path {
            path in
            for col in 0..<windyData.rects.count {
                for row in 0..<windyData.rects[col].count {
                    path.addRect(windyData.rects[col][row].insetBy(dx: 10, dy: 10))
                    print("col: \(col) row: \(row)", windyData.rects[col][row].insetBy(dx: 10, dy: 10))
                }
            }
        }
        path.fill(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.8))
    }
}

func createRects(columns: Double, rows: Double, screen: NSScreen) -> [[NSRect]] {
    print (columns, rows)
    var rects       : [[NSRect]] = []
    let minWidth    = (screen.frame.width / CGFloat(columns))
    let minHeight   = (screen.frame.height / CGFloat(rows))
    print (screen.frame.width, screen.frame.height)
    for col in 0..<Int(columns) {
        rects.append([])
        for row in 0..<Int(rows) {
            let rect = NSRect(
                origin: NSPoint(
                    x   : Int(minWidth) * col,
                    y   : Int(minHeight) * row
                ),
                size: NSSize(
                    width   : Int(minWidth),
                    height  : Int(minHeight)
                )
            )
            rects[col].append(rect)
        }
    }
    return rects
}

// this should be split into its own data class
class GridManager: ObservableObject {
    var window              : NSWindow
    var gridView            : GridView
    var windyData           : WindyData
    var isShownListener     : AnyCancellable?
    var accentColorListener : AnyCancellable?
    var rectsListener       : AnyCancellable?
    
    
    
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
        
        window.contentView          = NSHostingView(rootView: gridView)
        window.collectionBehavior   = .canJoinAllSpaces                     // allow window to be shown on all virtual desktops (spaces)
        
        
        accentColorListener         = windyData.$accentColour.sink { accentColor in
            self.window.backgroundColor = NSColor(accentColor)
        }
        isShownListener             = windyData.$isShown.sink { isShown in
            self.window.setIsVisible(isShown)
            self.window.setFrame(NSScreen.main!.frame, display: true)
            self.windyData.rects = createRects(
                columns : Double(windyData.displaySettings[windyData.activeSettingScreen]?.x ?? CGFloat(2.0)),
                rows    : Double(windyData.displaySettings[windyData.activeSettingScreen]?.y ?? CGFloat(2.0)),
                screen  : NSScreen.main!
            )
        }
        //        rectsListener               = windyData.$rects.sink { rects in
        //            self.windyData.rects = createRects(
        //                rows    : Double(windyData.displaySettings[NSScreen.main!.getIdString()]?.x ?? CGFloat(2.0)),
        //                columns : Double(windyData.displaySettings[NSScreen.main!.getIdString()]?.y ?? CGFloat(2.0)),
        //                screen  : NSScreen.main!
        //            )
        //        }
    }
    
    func moveWindow(window: WindyWindow, direction: Direction) throws {
        // check to see centre of window is colliding with rects
        let screen      = try window.getScreen()
        let windowRect  = try  window.getFrame()
        let rects       = createRects(
            columns : windyData.displaySettings[screen.getIdString()]!.x,
            rows    : windyData.displaySettings[screen.getIdString()]!.y,
            screen  : screen
        )
        
        // find the centre rect
        var rowIndex = 0
        var colIndex = 0
        for row in 0..<rects.count {
            for col in 0..<rects[row].count {
                if NSPointInRect(windowRect.centerPoint(), rects[row][col]) {
                    rowIndex = row
                    colIndex = col
                    break
                }
            }
        }
        //        switch direction {
        //        case .Left:
        //
        //            window.setFrame(frame: )
        //            break
        //        case .Right:
        //            break
        //        case .Up:
        //            break
        //        case .Down:
        //            break
        //        }
    }
    func resizeWindow(window: WindyWindow, direction: Direction) throws {
        
    }
    
    
    func move(window: WindyWindow, direction: Direction) throws {
        do {
            let screen = NSScreen.main!
            var point = try window.getNSPoint()
            let columns = 2.0
            let rows = 2.0
            let minWidth = screen.frame.maxX / columns
            let minHeight = screen.frame.maxY / rows
            
            switch direction {
            case .Left:
                point.x -= minWidth
            case .Right:
                point.x += minWidth
            case .Up:
                point.y += minHeight
            case .Down:
                point.y -= minHeight
            }
            
            var screenSize = screen.frame.size
            let windowSize = try window.getSize()
            screenSize.width -= windowSize.width
            point = point.clamp(NSRect(origin: screen.frame.origin, size: screenSize))
            try window.setFrameOrigin(origin: point)
        } catch {
            print("error \(error)")
        }
    }
    
    func resize(window: WindyWindow, direction: Direction) throws {
        do {
            let screen      = NSScreen.main!
            var point       = try window.getNSPoint()
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
                //                point.y -= size.height
                
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
                // if there are no window collisions we can move the window in the direction
                let canMove             = !windowCollisions.contains(direction)
                print("windowCollisions", windowCollisions)
                print("can move", canMove)
                
                if canMove || windowCollisions.isEmpty {
                    //                    try self.moveWindow(window: window, direction: direction)
                    try self.move(window: window, direction: direction)
                    return
                }
                //                try self.resizeWindow(window: window, direction: direction)
                try self.resize(window: window, direction: direction)
            }
        } catch {
            print("error: \(error)")
        }
    }
    
    
    func registerEvents() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: self.globalKeyEventHandler)
    }
}
