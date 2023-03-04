//
//  snapWindow.swift
//  test
//
//  Created by Lyndon Leong on 22/01/2023.
//

import Foundation

class SnapManager {
    var snapWindow: NSWindow

    
    var currentMovingWindow: WindyWindow!
    var initialWindyWindowPos = NSPoint(x: 0, y: 0)
    var windowIsMoving = false
    var shouldSnap = true
    
    init(windyData: WindyData) {
        snapWindow = NSWindow(
            contentRect     : NSRect(x: 0, y: 0, width: 500 , height: 500),
            styleMask       : [.fullSizeContentView],
            backing         : .buffered,
            defer           : false
        )
        snapWindow.backgroundColor      = NSColor(windyData.accentColour)
        snapWindow.collectionBehavior   = .canJoinAllSpaces // allow snap window to be shown on all virtual desktops (spaces)
        snapWindow.setIsVisible(false)
    }
    
    func snapMouse(point: NSPoint) throws {
        guard let screen = point.getScreen() else {
            throw WindyWindowError.NSError(message: "could not get screen at point")
        }
        // went out side of window don't draw anything
        let inSideScreen = NSPointInRect(point, screen.frame.insetBy(dx: -1, dy: -1))
        let insideGutter = point.collisionsInside(rect: (screen.frame.insetBy(dx: 100, dy: 100)))
        if !inSideScreen  {
            snapWindow.setIsVisible(false)
            return
        }
        if insideGutter.isEmpty {
            snapWindow.setIsVisible(false)
            return
        }
        if !shouldSnap {
            snapWindow.setIsVisible(false)
            return
        }
        
        var t_point = screen.frame.origin
        var t_size = screen.frame.size
        
        let columns = 2.0
        let rows = 2.0
        
        let minWidth = screen.frame.width / columns
        let minHeight = screen.frame.height / rows
        
        
        if insideGutter.contains(.Left) {
            t_size.width    = minWidth
            t_point.x       = screen.frame.minX
        }
        if insideGutter.contains(.Right) {
            t_size.width    = minWidth
            t_point.x       = screen.frame.maxX - t_size.width
        }
        
        if insideGutter.contains(.Up) {
            t_size.height   = minHeight
            t_point.y       = screen.frame.maxY - t_size.height
         
        }
        if insideGutter.contains(.Down) {
            t_size.height   = minHeight
            t_point.y       = screen.frame.minY
        }
        
        let tFrame = NSRect(origin: t_point, size: t_size)
       

        snapWindow.setFrame(tFrame, display: true)
        snapWindow.setIsVisible(true)
        snapWindow.orderFrontRegardless()

    }
    
    func globalLeftMouseDownHandler(event: NSEvent)  {
        do {
            currentMovingWindow     = try WindyWindow.currentWindow()
            initialWindyWindowPos   = try currentMovingWindow.getTopLeftPoint()
        } catch {
            print("\(error)")
        }
    }
    
    func globalLeftMouseDragHandler(event: NSEvent)  {
        do {
            let t_windyWindowPos = try currentMovingWindow.getTopLeftPoint()
            // check to see if a window is being moved if not cancel
            if (t_windyWindowPos != initialWindyWindowPos) {
                windowIsMoving = true
            }
            if (windowIsMoving) {
                try self.snapMouse(point: NSEvent.mouseLocation)
            }
        } catch {
            print("error \(error)")
        }
    }
    
    func globalLeftMouseUpHandler(event: NSEvent)  {
        do {
            if( self.snapWindow.isVisible) {
                try self.currentMovingWindow.setFrame(frame:  self.snapWindow.frame)
                self.snapWindow.setIsVisible(false)
            }
            self.windowIsMoving = false
        } catch {
            print("error \(error)")
        }
        
      
    }
    func globalEscKeyDownHandler(event: NSEvent)  {
        if (event.keyCode != 53) {
            return
        }
        self.snapWindow.setIsVisible(false)
        shouldSnap = false
    }
    func globalEscKeyUpHandler(event: NSEvent)  {
        if (event.keyCode != 53) {
            return
        }
        shouldSnap = true
    }
    
    
    func registerEvents() {
        // snapping window
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown,     handler: self.globalLeftMouseDownHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged,  handler: self.globalLeftMouseDragHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp,       handler: self.globalLeftMouseUpHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown,           handler: self.globalEscKeyDownHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .keyUp,             handler: self.globalEscKeyUpHandler)
    }
}
