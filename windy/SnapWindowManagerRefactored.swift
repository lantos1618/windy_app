//
//  SnapWindowManagerRefactored.swift
//  windy
//
//  Created by Lyndon Leong on 27/01/2023.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Snap Grid Message View (Refactored)
/// Displays instructions for canceling window snapping
struct SnapGridMessageViewRefactored: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("Hold ESC")
                Image(systemName: "escape")
                Text("and release window cancel snapping")
            }
            .padding()
            .background()
            .cornerRadius(10)
            Spacer()
        }
    }
}

// MARK: - Snap Window Manager (Refactored)
/// Refactored SnapWindowManager that uses the new utilities to eliminate magic numbers and improve coordinate handling
class SnapWindowManagerRefactored: ObservableObject {
    
    // MARK: - Properties
    private var snapWindow: NSWindow?
    private var currentMovingWindow: WindyWindow?
    private var initialWindyWindowPos = NSPoint(x: 0, y: 0)
    private var windowIsMoving = false
    private var shouldSnap = true
    
    // MARK: - Dependencies
    private var settingsStore: SettingsStore
    private var appState: AppState
    
    // MARK: - Combine Subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(settingsStore: SettingsStore, appState: AppState) {
        self.settingsStore = settingsStore
        self.appState = appState
        
        setupSnapWindow()
        setupSubscriptions()
    }
    
    // MARK: - Setup Methods
    
    private func setupSnapWindow() {
        snapWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: WindyConstants.UI.menuPopoverWidth, height: WindyConstants.UI.menuPopoverHeight),
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        let hostingView = NSHostingView(rootView: SnapGridMessageViewRefactored().frame(maxWidth: .infinity, maxHeight: .infinity))
        hostingView.autoresizingMask = [.width, .height]
        snapWindow?.contentView = hostingView
        snapWindow?.backgroundColor = NSColor(settingsStore.accentColour)
        snapWindow?.collectionBehavior = .canJoinAllSpaces
        snapWindow?.setIsVisible(false)
        snapWindow?.isReleasedWhenClosed = false
    }
    
    private func setupSubscriptions() {
        // Listen for accent color changes
        settingsStore.$accentColour
            .sink { [weak self] accentColor in
                self?.snapWindow?.backgroundColor = NSColor(accentColor)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Snap Window Management
    
    /// Creates or returns the snap window for visual feedback
    func createSnapWindow() -> Bool {
        if snapWindow == nil {
            setupSnapWindow()
        }
        return true
    }
    
    /// Calculates the snap rectangle based on mouse position and screen edges using proper coordinate conversion
    func calculateSnapRect(mousePos: NSPoint) throws -> NSRect? {
        guard let screen = mousePos.getScreen() else {
            throw WindyWindowError.NSError(message: WindyConstants.ErrorMessages.screenDetectionFailed)
        }
        
        // Check if mouse is inside screen bounds (with 1px tolerance)
        let inSideScreen = NSPointInRect(mousePos, screen.frame.insetBy(dx: -1, dy: -1))
        
        // Check if mouse is in the "gutter" area near screen edges using constants
        let insideGutter = mousePos.collisionsInside(rect: screen.frame.insetBy(dx: WindyConstants.Snapping.gutterSize, dy: WindyConstants.Snapping.gutterSize))
        
        // Hide snap window if mouse is outside screen or not in gutter area
        if !inSideScreen || insideGutter.isEmpty || !shouldSnap {
            snapWindow?.setIsVisible(false)
            return nil
        }
        
        // Use proper coordinate conversion for screen frame
        let screenFrameCG = CoordinateConverter.getScreenVisibleFrameCG(for: screen)
        
        // Use constants for grid layout
        let columns = WindyConstants.Snapping.fixedGridColumns
        let rows = WindyConstants.Snapping.fixedGridRows
        
        let minWidth = screenFrameCG.width / columns
        let minHeight = screenFrameCG.height / rows
        
        // Calculate snap position based on which screen edge the mouse is near
        var snapPoint = screenFrameCG.origin
        var snapSize = CGSize(width: minWidth, height: minHeight)
        
        // Determine snap position based on which screen edge the mouse is near
        if insideGutter.contains(.Left) {
            snapSize.width = minWidth
            snapPoint.x = screenFrameCG.minX
        }
        if insideGutter.contains(.Right) {
            snapSize.width = minWidth
            snapPoint.x = screenFrameCG.maxX - snapSize.width
        }
        
        if insideGutter.contains(.Up) {
            snapSize.height = minHeight
            snapPoint.y = screenFrameCG.maxY - snapSize.height
        }
        if insideGutter.contains(.Down) {
            snapSize.height = minHeight
            snapPoint.y = screenFrameCG.minY
        }
        
        // Convert back to AppKit coordinates for window positioning
        let snapRectCG = CGRect(origin: snapPoint, size: snapSize)
        let snapRect = CoordinateConverter.coreGraphicsToAppKit(rect: snapRectCG, on: screen)
        
        return snapRect
    }
    
    /// Updates the snap window position based on current mouse position
    func snapMouse(mousePos: NSPoint) throws {
        if !createSnapWindow() {
            debugPrint("Error: failed to get/create snap window")
            return
        }
        
        guard let snapFrame = try calculateSnapRect(mousePos: mousePos) else {
            return
        }
        
        drawSnapWindow(frame: snapFrame)
    }
    
    /// Displays the snap window at the specified frame
    func drawSnapWindow(frame: NSRect) {
        guard let snapWindow = snapWindow else {
            debugPrint("Error: no snapWindow")
            return
        }
        
        snapWindow.setFrame(frame, display: true)
        snapWindow.setIsVisible(true)
        snapWindow.orderFrontRegardless()
    }
    
    // MARK: - Mouse Event Handlers
    
    /// Handles mouse down events to start window tracking
    func globalLeftMouseDownHandler(event: NSEvent) {
        do {
            currentMovingWindow = try WindyWindow.currentWindow()
            guard let tempCurrentMovingWindow = currentMovingWindow else {
                print("Error: Failed to get the current moving window")
                return
            }
            initialWindyWindowPos = try tempCurrentMovingWindow.getTopLeftPoint()
        } catch {
            print("Mouse down error: \(error)")
        }
    }
    
    /// Handles mouse drag events to update snap window position
    func globalLeftMouseDragHandler(event: NSEvent) {
        do {
            guard let tempCurrentMovingWindow = currentMovingWindow else {
                print("Error: Failed to get the current moving window")
                return
            }
            
            let currentWindowPos = try tempCurrentMovingWindow.getTopLeftPoint()
            
            // Check if window is actually being moved (position changed from initial)
            if currentWindowPos != initialWindyWindowPos {
                windowIsMoving = true
            }
            
            // Update snap window if window is being moved
            if windowIsMoving {
                try snapMouse(mousePos: NSEvent.mouseLocation)
            }
        } catch {
            debugPrint("Mouse drag error: \(error)")
        }
    }
    
    /// Handles mouse up events to finalize window snapping
    func globalLeftMouseUpHandler(event: NSEvent) {
        if !createSnapWindow() {
            debugPrint("Error: failed to get/create snap window")
            return
        }
        
        do {
            if snapWindow?.isVisible == true {
                guard let tempCurrentMovingWindow = currentMovingWindow else {
                    print("Error: Failed to get the current moving window")
                    return
                }
                
                // Move the window to the snap position using proper coordinate conversion
                try tempCurrentMovingWindow.setFrameBottomLeft(frame: snapWindow!.frame)
                snapWindow?.setIsVisible(false)
            }
            windowIsMoving = false
        } catch {
            debugPrint("Mouse up error: \(error)")
        }
    }
    
    /// Handles ESC key down to cancel snapping using constants
    func globalEscKeyDownHandler(event: NSEvent) {
        if !createSnapWindow() {
            debugPrint("Error: failed to get/create snap window")
            return
        }
        
        // Use constants for key codes
        if event.keyCode != WindyConstants.KeyCodes.escape {
            return
        }
        
        snapWindow?.setIsVisible(false)
        shouldSnap = false
    }
    
    /// Handles ESC key up to re-enable snapping using constants
    func globalEscKeyUpHandler(event: NSEvent) {
        // Use constants for key codes
        if event.keyCode != WindyConstants.KeyCodes.escape {
            return
        }
        
        shouldSnap = true
    }
    
    /// Handles mouse movement to hide snap window when not dragging
    func globalMouseMoved(event: NSEvent) {
        if windowIsMoving {
            return
        }
        snapWindow?.setIsVisible(false)
    }
    
    // MARK: - Event Registration
    
    /// Registers global mouse and keyboard event handlers for snapping functionality
    func registerEvents() {
        // Register mouse event handlers for window dragging and snapping
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: globalLeftMouseDownHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged, handler: globalLeftMouseDragHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp, handler: globalLeftMouseUpHandler)
        
        // Register keyboard event handlers for ESC key (snap cancellation)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: globalEscKeyDownHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .keyUp, handler: globalEscKeyUpHandler)
        
        // Register mouse movement handler to hide snap window when not dragging
        NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved, handler: globalMouseMoved)
    }
} 