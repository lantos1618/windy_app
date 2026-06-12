//
//  snapWindow.swift
//  test
//
//  Created by Lyndon Leong on 22/01/2023.
// TODO FIX SNAP WINDOW NOT SHOWING

import Foundation
import Combine
import SwiftUI

// MARK: - Snap Grid Message View
/// Displays instructions for canceling window snapping
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

// MARK: - Snap Window Manager
/// Manages window snapping functionality using mouse drag events
class SnapWindowManager {
    var windyData               : WindyData
    var snapWindow              : NSWindow?
    var currentMovingWindow     : WindyWindow?
    var initialWindyWindowPos   = NSPoint(x: 0, y: 0)
    var windowIsMoving          = false
    var shouldSnap              = true
    var accentColorListener     : AnyCancellable?
    private var eventMonitors   : [Any] = []
    
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

    deinit {
        unregisterEvents()
    }
    
    /// Creates or returns the snap window for visual feedback
    func createSnapWindow() -> Bool {
        if (snapWindow == nil) {
            snapWindow      = NSWindow(
                contentRect     : NSRect(x: 0, y: 0, width: 500, height: 500),
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
    
    /// Calculates the snap rectangle based on mouse position and screen edges
    /// Uses collision detection to determine which screen edge the mouse is near
    func calculateSnapRect(mousePos: NSPoint) throws -> NSRect? {
        guard let screen = ScreenGeometryService.screen(containingAppKitPoint: mousePos) else {
            throw WindyWindowError.NSError(message: "could not get screen at point")
        }
        let screenFrame = ScreenGeometryService.appKitVisibleFrame(for: screen)
        
        // Check if mouse is inside screen bounds (with 1px tolerance)
        let inSideScreen = NSPointInRect(mousePos, screenFrame.insetBy(dx: -1, dy: -1))
        
        // Check if mouse is in the "gutter" area near screen edges (100px from edges)
        // This determines which edge the window should snap to
        let insideGutter = mousePos.collisionsInside(rect: (screenFrame.insetBy(dx: 100, dy: 100)))
        
        // Hide snap window if mouse is outside screen or not in gutter area
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
        
        // Calculate snap rectangle based on which screen edge is detected
        var t_point     = screenFrame.origin
        var t_size      = screenFrame.size
        let columns     = 2.0  // MAGIC NUMBER: Fixed 2x2 grid for snapping
        let rows        = 2.0  // MAGIC NUMBER: Fixed 2x2 grid for snapping
        let minWidth    = screenFrame.width / columns
        let minHeight   = screenFrame.height / rows
        
        // Determine snap position based on which screen edge the mouse is near
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
    
    /// Updates the snap window position based on current mouse position
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
    
    /// Displays the snap window at the specified frame
    func drawSnapWindow(frame: NSRect) {
        if (snapWindow == nil) {
            debugPrint("error: no snapWindow")
            return
        }
        snapWindow?.setFrame(frame, display: true)
        snapWindow?.setIsVisible(true)
        snapWindow?.orderFrontRegardless()
    }
    
    // MARK: - Mouse Event Handlers
    
    /// Handles mouse down events to start window tracking
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
    
    /// Handles mouse drag events to update snap window position
    func globalLeftMouseDragHandler(event: NSEvent)  {
        do {
            guard let tempCurrentMovingWindow = self.currentMovingWindow else {
                print ("error: Failed to get the current moving window")
                return
            }
            let t_windyWindowPos = try tempCurrentMovingWindow.getTopLeftPoint()
            
            // Check if window is actually being moved (position changed from initial)
            if (t_windyWindowPos != initialWindyWindowPos) {
                windowIsMoving = true
            }
            
            // Update snap window if window is being moved
            if (windowIsMoving) {
                try self.snapMouse(mousePos: NSEvent.mouseLocation)
            }
        } catch {
            debugPrint("error \(error)")
        }
    }
    
    /// Handles mouse up events to finalize window snapping
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
                
                // Move the window to the snap position using coordinate system conversion
                try tempCurrentMovingWindow.setFrameBottomLeft(frame:  self.snapWindow!.frame)
                self.snapWindow?.setIsVisible(false)
            }
            self.windowIsMoving = false
        } catch {
            debugPrint("error \(error)")
        }
    }
    
    /// Handles ESC key down to cancel snapping
    func globalEscKeyDownHandler(event: NSEvent)  {
        if (!createSnapWindow()) {
            debugPrint("error: failed to get/create snap window")
            return
        }
        // MAGIC NUMBER: ESC key code is 53
        if (event.keyCode != 53) {
            return
        }
        self.snapWindow?.setIsVisible(false)
        shouldSnap = false
    }
    
    /// Handles ESC key up to re-enable snapping
    func globalEscKeyUpHandler(event: NSEvent)  {
        // MAGIC NUMBER: ESC key code is 53
        if (event.keyCode != 53) {
            return
        }
        shouldSnap = true
    }
    
    /// Handles mouse movement to hide snap window when not dragging
    func globalMouseMoved(event: NSEvent) {
        if(windowIsMoving) {
            return
        }
        self.snapWindow?.setIsVisible(false)
    }
    
    // MARK: - Event Registration
    /// Registers global mouse and keyboard event handlers for snapping functionality
    func registerEvents() {
        guard eventMonitors.isEmpty else {
            return
        }

        // Register mouse event handlers for window dragging and snapping
        addGlobalMonitor(matching: .leftMouseDown,     handler: self.globalLeftMouseDownHandler)
        addGlobalMonitor(matching: .leftMouseDragged,  handler: self.globalLeftMouseDragHandler)
        addGlobalMonitor(matching: .leftMouseUp,       handler: self.globalLeftMouseUpHandler)
        
        // Register keyboard event handlers for ESC key (snap cancellation)
        addGlobalMonitor(matching: .keyDown,           handler: self.globalEscKeyDownHandler)
        addGlobalMonitor(matching: .keyUp,             handler: self.globalEscKeyUpHandler)
        
        // Register mouse movement handler to hide snap window when not dragging
        addGlobalMonitor(matching: .mouseMoved,        handler: self.globalMouseMoved)
    }

    func unregisterEvents() {
        for monitor in eventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        eventMonitors.removeAll()
    }

    private func addGlobalMonitor(matching mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) {
        guard let monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler) else {
            return
        }

        eventMonitors.append(monitor)
    }
}
