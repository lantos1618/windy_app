//
//  windyWindow.swift
//  test
//
//  Created by Lyndon Leong on 22/01/2023.
//

import Foundation

// MARK: - Windy Window Class
/// Wrapper class for managing windows using the Accessibility framework
/// Provides a clean interface for window positioning, sizing, and manipulation
class WindyWindow {
    var AXWindow: AXUIElement
    
    init(ele: AXUIElement) {
        AXWindow = ele
    }
    
    /// Creates a WindyWindow from a process ID by getting the main window
    convenience init(pid: pid_t) throws {
        let AXApp   = AXUIElementCreateApplication(pid)
        var winPtr  :  CFTypeRef?
        let axErr   = AXUIElementCopyAttributeValue(AXApp, kAXMainWindowAttribute as CFString, &winPtr)
        
        if axErr != .success{
            throw WindyWindowError.AXValueError(message: "Failed to get main window \(axErr)")
        }
        self.init(ele: winPtr as! AXUIElement)
    }
    
    /// Creates a WindyWindow from a running application
    convenience init(app: NSRunningApplication) throws {
        try self.init(pid: app.processIdentifier)
    }
    
    /// Creates a WindyWindow from a screen point by finding the window at that location
    convenience init(point: CGPoint) throws {
        var winPtr      : AXUIElement?
        let systemWide  = AXUIElementCreateSystemWide()
        let axErr       = AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &winPtr)
        
        if axErr != .success {
            throw WindyWindowError.AXValueError(message: "Failed to get window at point, error: \(axErr)")
        }
        self.init(ele: winPtr!)
    }
    
    // MARK: - Window Position and Size
    
    /// Gets the top-left point of the window relative to the screen
    /// Returns coordinates in the Accessibility framework's coordinate system
    func getTopLeftPoint() throws -> CGPoint {
        var oldPointCFT :  CFTypeRef?
        let axErr       = AXUIElementCopyAttributeValue(self.AXWindow, kAXPositionAttribute as CFString, &oldPointCFT)
        
        if axErr != .success {
            throw WindyWindowError.AXValueError(message: "Failed to get window point attribute \(axErr)")
        }
        
        var currentPoint = CGPoint()
        if AXValueGetValue(oldPointCFT as! AXValue, AXValueType(rawValue: kAXValueCGPointType)!, &currentPoint) != true {
            throw WindyWindowError.AXValueError(message: "Failed to parse window CGPoint")
        }
        
        return currentPoint
    }
    
    /// Gets the bottom-left point of the window relative to the screen
    /// This is useful for coordinate system conversions
    func getBottomLeftPoint() throws -> CGPoint {
        var point   = try self.getTopLeftPoint()
        point.y     += try self.getSize().height
        
        // TODO: Re-evaluate coordinate system conversion
        // This flip operation was commented out - investigate if it's needed
//        point       = point.flip()
        return point
    }
    
    /// Gets the complete window frame (position + size)
    func getFrame() throws -> NSRect {
        return NSRect(origin: try self.getTopLeftPoint(), size: try self.getSize())
    }
    
    /// Gets the window size
    func getSize() throws -> CGSize {
        var oldSizeCFT  :  CFTypeRef?
        let axErr       = AXUIElementCopyAttributeValue(self.AXWindow, kAXSizeAttribute as CFString, &oldSizeCFT)
        
        if axErr != .success {
            throw WindyWindowError.AXValueError(message: "Failed to get window size attribute \(axErr)")
        }
        
        var currentSize = CGSize()
        if AXValueGetValue(oldSizeCFT as! AXValue, AXValueType(rawValue: kAXValueCGSizeType)!, &currentSize) != true {
            throw WindyWindowError.AXValueError(message: "Failed to parse window CGSize")
        }
        return currentSize
    }
    
    /// Gets all available attribute names for this window
    /// Useful for debugging and discovering available properties
    func getAttrNames() throws -> [String] {
        var attrNames   : CFArray?
        let axErr       =  AXUIElementCopyAttributeNames(AXWindow, &attrNames)
        
        if axErr != .success {
            throw WindyWindowError.AXValueError(message: "Failed to get AXUIElementAttributeNames")
        }
        return attrNames as! [String]
    }
    
    /// Gets the screen that contains this window
    /// Determines the correct screen based on window position
    func getScreen() throws -> NSScreen {
        let rect = try self.getFrame()
        let windowCenter = NSPoint(x: rect.midX, y: rect.midY)
        
        // Find the screen that contains the window's center point
        for screen in NSScreen.screens {
            if screen.frame.contains(windowCenter) {
                return screen
            }
        }
        
        // Fallback to main screen if no screen contains the window
        // This can happen if the window is positioned outside all screens
        guard let mainScreen = NSScreen.main else {
            throw WindyWindowError.NSError(message: "Failed to get any screen")
        }
        return mainScreen
    }
    
    // MARK: - Window Manipulation
    
    /// Sets the window size while maintaining current position
    func setFrameSize(size: CGSize) throws {
        var newSize     = size
        let cfSize      = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!,&newSize)!;
        let axErr       = AXUIElementSetAttributeValue(AXWindow, kAXSizeAttribute as CFString, cfSize)
        
        if axErr != .success {
            throw WindyWindowError.AXValueError(message: "Failed to set window size \(axErr)")
        }
    }
    
    /// Sets the window's top-left position
    /// Uses the Accessibility framework's coordinate system
    func setTopLeftPoint(point: CGPoint) throws {
        var newPoint    = point
        let position    = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!,&newPoint)!;
        let axErr       = AXUIElementSetAttributeValue(AXWindow, kAXPositionAttribute as CFString, position)
        
        if axErr != .success {
            throw WindyWindowError.AXValueError(message: "Failed to set window point, \(axErr)")
        }
    }
    
    /// Sets the window frame using bottom-left positioning
    /// This involves coordinate system conversion from bottom-left to top-left
    func setFrameBottomLeft(frame: NSRect) throws {
        var tPoint = frame.origin
        
        // Convert from bottom-left to top-left coordinate system
        tPoint = tPoint.flip()
        tPoint.y -= frame.height
        
        try self.setTopLeftPoint(point: tPoint)
        try self.setFrameSize(size: frame.size)
    }
    
    // MARK: - Static Methods
    
    /// Gets the currently active window (frontmost application's main window)
    static func currentWindow() throws -> WindyWindow {
        // Get the most frontmost application
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            throw WindyWindowError.NSError(message: "failed to get frontmost app")
        }
        return try WindyWindow(app: frontApp)
    }
}
