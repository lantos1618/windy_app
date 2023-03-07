//
//  windyWindow.swift
//  test
//
//  Created by Lyndon Leong on 22/01/2023.
//

import Foundation


class WindyWindow {
    var AXWindow: AXUIElement
    
    init(ele: AXUIElement) {
        AXWindow = ele
    }
    
    convenience init(pid: pid_t) throws {
        let AXApp   = AXUIElementCreateApplication(pid)
        var winPtr  :  CFTypeRef?
        let axErr   = AXUIElementCopyAttributeValue(AXApp, kAXMainWindowAttribute as CFString, &winPtr)
        
        if axErr != .success{
            throw WindyWindowError.AXValueError(message: "Failed to get main window \(axErr)")
        }
        self.init(ele: winPtr as! AXUIElement)
    }
    
    convenience init(app: NSRunningApplication) throws {
        try self.init(pid: app.processIdentifier)
    }
    
    convenience init(point: CGPoint) throws {
        var winPtr      : AXUIElement?
        let systemWide  = AXUIElementCreateSystemWide()
        let axErr       = AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &winPtr)
        
        if axErr != .success {
            throw WindyWindowError.AXValueError(message: "Failed to get window at point, error: \(axErr)")
        }
        self.init(ele: winPtr!)
    }
    
    func getTopLeftPoint() throws -> CGPoint {
        // gets the top left point of the window relative to the top left point of the screen
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
    
    func getBottomLeftPoint() throws -> CGPoint {
        // gets the bottom left of window relative to the top left point of the screen
        var point   = try self.getTopLeftPoint()
        point.y     += try self.getSize().height
//        point       = point.flip()
        return point
    }
    
    func getFrame() throws -> NSRect {
        return NSRect(origin: try self.getTopLeftPoint(), size: try self.getSize())
    }
    
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
    
    func getAttrNames() throws -> [String] {
        var attrNames   : CFArray?
        let axErr       =  AXUIElementCopyAttributeNames(AXWindow, &attrNames)
        
        if axErr != .success {
            throw WindyWindowError.AXValueError(message: "Failed to get AXUIElementAttributeNames")
        }
        return attrNames as! [String]
    }
    
    func getScreen() throws -> NSScreen {
        // https://developer.apple.com/documentation/appkit/nsscreen/1388371-main
        // Returns the screen object containing the window with the keyboard focus.
//        guard let screen = NSScreen.screens[0] else {
//            throw WindyWindowError.NSError(message: "failed to get the main screen")
//        }
        let screen = NSScreen.main!
        
//        let rect = try self.getFrame()
//        guard let screen = NSPoint(x: rect.midX, y: rect.midX).getScreen() else {
//            throw WindyWindowError.NSError(message: "failed to get the main screen")
//        }
        return screen
    }
    
    func setFrameSize(size: CGSize) throws {
        var newSize     = size
        let cfSize      = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!,&newSize)!;
        let axErr       = AXUIElementSetAttributeValue(AXWindow, kAXSizeAttribute as CFString, cfSize)
        
        if axErr != .success {
            throw WindyWindowError.AXValueError(message: "Failed to set window size \(axErr)")
        }
    }
    
    func setTopLeftPoint(point: CGPoint) throws {
        var newPoint    = point
        let position    = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!,&newPoint)!;
        let axErr       = AXUIElementSetAttributeValue(AXWindow, kAXPositionAttribute as CFString, position)
        
        if axErr != .success {
            throw WindyWindowError.AXValueError(message: "Failed to set window point, \(axErr)")
        }
    }
    func setFrameBottomLeft(frame: NSRect) throws {
        var tPoint = frame.origin
        tPoint = tPoint.flip()
        tPoint.y -= frame.height
        
        try self.setTopLeftPoint(point: tPoint)
        try self.setFrameSize(size: frame.size)
        
    }
    
     static func currentWindow() throws -> WindyWindow {
        // get the most frontMostApp
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            throw WindyWindowError.NSError(message: "failed to get frontmost app")
        }
        return try WindyWindow(app: frontApp)
    }
    
    func getWindowId() throws -> CGWindowID {
        var winId   = CGWindowID(0)
        let axErr   = _AXUIElementGetWindow(self.AXWindow, &winId)
        
        if axErr != .success {
            throw WindyWindowError.AXValueError(message: "Failed to get windowID, \(axErr)")
        }
        return winId
    }
}
