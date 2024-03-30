//
//  snapWindow.swift
//  test
//
//  Created by Lyndon Leong on 22/01/2023.
// TODO FIX SNAP WINDOW NOT SHOWING

import Foundation
import Combine
import SwiftUI



struct SnapGridMessageView: View {
    var body: some View {
        VStack {
            Spacer() // Pushes content to the center vertically
            HStack {
                Text("Hold ESC")
                Image(systemName: "escape")
                Text("and release window cancel snapping")
            }
            .padding() // Adds some padding around the HStack
            .background() // Example background color
            .cornerRadius(10)
            Spacer() // Pushes content to the center vertically
        }
    }
}


class SnapWindowManager {
    var windyData               : WindyData
    var snapWindow              : NSWindow?
    var currentMovingWindow     : WindyWindow?
    var initialWindyWindowPos   = NSPoint(x: 0, y: 0)
    var windowIsMoving          = false
    var shouldSnap              = true
    var accentColorListener     : AnyCancellable?
    
    init(windyData: WindyData) {
        self.windyData  = windyData
        snapWindow      = NSWindow(
            contentRect     : NSRect(x: 0, y: 0, width: 500 , height: 500),
            styleMask       : [.fullSizeContentView],
            backing         : .buffered,
            defer           : false
        )
        

        let hostingView = NSHostingView(rootView: SnapGridMessageView().frame(maxWidth: .infinity, maxHeight: .infinity))
        hostingView.autoresizingMask = [.width, .height]
        snapWindow?.contentView = hostingView
        snapWindow?.backgroundColor      = NSColor(windyData.accentColour)
        snapWindow?.collectionBehavior   = .canJoinAllSpaces // allow snap window to be shown on all virtual desktops (spaces)
        snapWindow?.setIsVisible(false)
        snapWindow?.isReleasedWhenClosed = false
        accentColorListener = windyData.$accentColour.sink {_ in
            self.snapWindow?.backgroundColor      = NSColor(windyData.accentColour)
        }
    }
    
    func createSnapWindow() -> Bool {
        if (snapWindow == nil) {
            snapWindow      = NSWindow(
                contentRect     : NSRect(x: 0, y: 0, width: 500 , height: 500),
                styleMask       : [.fullSizeContentView],
                backing         : .buffered,
                defer           : false
            )
            snapWindow?.backgroundColor      = NSColor(windyData.accentColour)
            snapWindow?.collectionBehavior   = .canJoinAllSpaces // allow snap window to be shown on all virtual desktops (spaces)
            snapWindow?.isReleasedWhenClosed = false
            snapWindow?.setIsVisible(false)
        }
        return true
    }
    
    func calculateSnapRect(mousePos: NSPoint) throws -> NSRect? {
        guard let screen = mousePos.getScreen() else {
            throw WindyWindowError.NSError(message: "could not get screen at point")
        }
        // went out side of window don't draw anything
        let inSideScreen = NSPointInRect(mousePos, screen.frame.insetBy(dx: -1, dy: -1))
        let insideGutter = mousePos.collisionsInside(rect: (screen.frame.insetBy(dx: 100, dy: 100)))
        
        if !inSideScreen  {
            snapWindow?.setIsVisible(false)
            return nil
        }
        if insideGutter.isEmpty {
            snapWindow?.setIsVisible(false)
            return nil
        }
        if !shouldSnap {
            snapWindow?.setIsVisible(false)
            return nil
        }
        
        var t_point     = screen.frame.origin
        var t_size      = screen.frame.size
        let columns     = 2.0
        let rows        = 2.0
        let screenFrame = screen.frame
//      let screenFrame = screen.getQuartsSafeFrame()
        let minWidth    = screenFrame.width / columns
        let minHeight   = screenFrame.height / rows
        
        
        if insideGutter.contains(.Left) {
            t_size.width    = minWidth
            t_point.x       = screenFrame.minX
        }
        if insideGutter.contains(.Right) {
            t_size.width    = minWidth
            t_point.x       = screenFrame.maxX - t_size.width
        }
        
        if insideGutter.contains(.Up) {
            t_size.height   = minHeight
            t_point.y       = screenFrame.maxY - t_size.height
            
        }
        if insideGutter.contains(.Down) {
            t_size.height   = minHeight
            t_point.y       = screenFrame.minY
        }
        
        let tFrame      = NSRect(origin: t_point, size: t_size)
        return tFrame
    }
    
    func snapMouse(mousePos: NSPoint) throws {
        if (!createSnapWindow()) {
            debugPrint("error: failed to get/create snap window")
            return
        }
        guard let tFrame = try calculateSnapRect(mousePos: mousePos) else {
            return
        }
        drawSnapWindow(frame: tFrame)
        return
    }
    
    func drawSnapWindow(frame: NSRect) {
        if (snapWindow == nil) {
            debugPrint("error: no snapWindow")
            return
        }
        snapWindow?.setFrame(frame, display: true)
        snapWindow?.setIsVisible(true)
        snapWindow?.orderFrontRegardless()
    }
    
    func globalLeftMouseDownHandler(event: NSEvent)  {
        do {
            currentMovingWindow                 = try WindyWindow.currentWindow()
            guard let tempCurrentMovingWindow   = currentMovingWindow else {
                print ("error: Failed to get the current moving window")
                return
            }
            initialWindyWindowPos               = try tempCurrentMovingWindow.getTopLeftPoint()
        } catch {
            print("\(error)")
        }
    }
    
    func globalLeftMouseDragHandler(event: NSEvent)  {
        do {
            guard let tempCurrentMovingWindow = self.currentMovingWindow else {
                print ("error: Failed to get the current moving window")
                return
            }
            let t_windyWindowPos = try tempCurrentMovingWindow.getTopLeftPoint()
            // check to see if a window is being moved if not cancel
            if (t_windyWindowPos != initialWindyWindowPos) {
                windowIsMoving = true
            }
            if (windowIsMoving) {
                try self.snapMouse(mousePos: NSEvent.mouseLocation)
            }
        } catch {
            debugPrint("error \(error)")
        }
    }
    
    func globalLeftMouseUpHandler(event: NSEvent)  {
        if (!createSnapWindow()) {
            debugPrint("error: failed to get/create snap window")
            return
        }
        do {
            if( self.snapWindow!.isVisible) {
                guard let tempCurrentMovingWindow = currentMovingWindow else {
                    print ("error: Failed to get the current moving window")
                    return
                }
                try tempCurrentMovingWindow.setFrameBottomLeft(frame:  self.snapWindow!.frame)
                self.snapWindow?.setIsVisible(false)
            }
            self.windowIsMoving = false
        } catch {
            debugPrint("error \(error)")
        }
        
        
    }
    func globalEscKeyDownHandler(event: NSEvent)  {
        if (!createSnapWindow()) {
            debugPrint("error: failed to get/create snap window")
            return
        }
        if (event.keyCode != 53) {
            return
        }
        self.snapWindow?.setIsVisible(false)
        shouldSnap = false
    }
    func globalEscKeyUpHandler(event: NSEvent)  {
        if (event.keyCode != 53) {
            return
        }
        shouldSnap = true
    }
    
    func globalMouseMoved(event: NSEvent) {
        if(windowIsMoving) {
            return
        }
        self.snapWindow?.setIsVisible(false)
    }
    
    func registerEvents() {
        // snapping window
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown,     handler: self.globalLeftMouseDownHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged,  handler: self.globalLeftMouseDragHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp,       handler: self.globalLeftMouseUpHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown,           handler: self.globalEscKeyDownHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .keyUp,             handler: self.globalEscKeyUpHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved,        handler: self.globalMouseMoved)

    }
}
