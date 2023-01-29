//
//  gridManager.swift
//  windy
//
//  Created by Lyndon Leong on 26/01/2023.
//

import Foundation
import SwiftUI

struct GridView: View {
    @State var rects: [[NSRect]]
    
    var body: some View {
        Path {
            path in
            for row in 0..<rects.count {
                for col in 0..<rects[row].count {
                    path.addRect(rects[row][col].insetBy(dx: 10, dy: 10))
                }
            }
        }
    }
}

func createRects(rows: Double, columns: Double, screen: NSScreen) -> [[NSRect]] {
    var rects: [[NSRect]] = []
    let minWidth =  screen.frame.width / CGFloat(columns)
    let minHeight = screen.frame.height / CGFloat(rows)
    for row in 0..<Int(rows) {
        rects.append([])
        for col in 0..<Int(columns) {
            let rect = NSRect(
                origin: NSPoint(
                    x:  Int(minWidth) * row,
                    y:  Int(minHeight) * col
                ),
                size: NSSize(
                    width: Int(minWidth),
                    height: Int(minHeight)
                )
            )
            rects[row].append(rect)
        }
    }
    return rects
}

// this should be split into its own data class
class GridManager: ObservableObject {
    var window: NSWindow
    var gridView: GridView
    var windyData: WindyData
    
    init(windyData: WindyData) {
        self.windyData = windyData
        window = NSWindow(
            contentRect: NSScreen.main!.frame,
            styleMask: [.fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 0.2)
        //        gridView = GridView(gridManagerData: self.gridManagerData
        gridView = GridView(rects: [])
        gridView.rects = createRects(rows: self.windyData.rows, columns: self.windyData.columns, screen: NSScreen.main!)
        
        window.contentView = NSHostingView(rootView: gridView)
        window.collectionBehavior = .canJoinAllSpaces // allow window to be shown on all virtual desktops (spaces)
        window.setIsVisible(self.windyData.isShown)
    }
    func moveWindow(window: WindyWindow, direction: Direction) throws {
        // check to see center of window is coliding with rects
        let screen = try window.getScreen()
        let windowRect = try  window.getFrame()
        let rects = createRects(rows: self.windyData.rows, columns: self.windyData.columns, screen: screen)
        
        // find the center rect
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
            let screen = NSScreen.main!
            var point = try window.getNSPoint()
            var size = try window.getSize()
            let columns = 2.0
            let rows = 2.0
            let minWidth = screen.frame.maxX / columns
            let minHeight = screen.frame.maxY / rows

            switch direction {
            case .Left:
                size.width += minWidth * (size.width <= minWidth ? columns : -1.0)
            case .Right:
                size.width += minWidth * (size.width <= minWidth ? columns : -1.0)
                point.x -= size.width
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
                guard let direction = event.direction else { return }
                let window = try WindyWindow.currentWindow()!
                let windowFrame =   try window.getFrame()
                let screenFrame = try window.getScreen().frame
                let windowCollisions = windowFrame.collisionsInside(rect: screenFrame)
                // if there are no window collisions we can move the window in the direction
                let canMove = !windowCollisions.contains(direction)
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
