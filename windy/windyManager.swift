//
//  windyManager.swift
//  windy
//
//  Created by Lyndon Leong on 09/01/2023.
//

import Foundation


class WindyManager {
    // window snapping
    var windyWindow: WindyWindow!
    var initialWindyWindowPos = NSPoint(x: 0, y: 0)
    var snapWindow = SnapWindow()
    var windowIsMoving = false
    
    func globalLeftMouseDownHandler(event: NSEvent)  {
        do {
            windyWindow = try currentWindow()
            initialWindyWindowPos = try windyWindow.getPoint()
        } catch {
            print("\(error)")
        }
    }
    
    func globalLeftMouseDragHandler(event: NSEvent)  {
        do {
            let t_windyWindowPos = try windyWindow.getPoint()
            // check to see if a window is being moved if not cancel
            if (t_windyWindowPos != initialWindyWindowPos) {
                windowIsMoving = true
            }
            if (windowIsMoving) {
                try snapWindow.snapMouse(point: NSEvent.mouseLocation)
            }
        } catch {
            print("error \(error)")
        }
    }
    
    func globalLeftMouseUpHandler(event: NSEvent)  {
        do {
            if(snapWindow.window.isVisible) {
                try windyWindow.setFrame(frame: snapWindow.window.frame)
                snapWindow.window.setIsVisible(false)
            }
            windowIsMoving = false
        } catch {
            print("error \(error)")
        }
    }
    
    func currentWindow() throws -> WindyWindow? {
        // get the most frontMostApp
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            throw WindyWindowError.NSError(message: "failed to get frontmost app")
        }
        return try WindyWindow(app: frontApp)
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
                let window = try currentWindow()!
                let windowFrame =   try window.getFrame()
                let screenFrame = try window.getScreen().frame
                let windowCollisions = windowFrame.collisionsInside(rect: screenFrame)
                // if there are no window collisions we can move the window in the direction
                let canMove = !windowCollisions.contains(direction)
                print("windowCollisions", windowCollisions)
                print("can move", canMove)
                
                if canMove || windowCollisions.isEmpty {
                    try move(window: window, direction: direction)
                    return
                }
                try resize(window: window, direction: direction)
            }
        } catch {
            print("error: \(error)")
        }
    }
    
    func registerGlobalEvents() {
        // keyboard shortcuts
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: self.globalKeyEventHandler)
        // snapping window
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: self.globalLeftMouseDownHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged, handler: self.globalLeftMouseDragHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp, handler: self.globalLeftMouseUpHandler)
        
    }
}
