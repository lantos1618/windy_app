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
    
    convenience init?(pid: pid_t) {
        let AXApp = AXUIElementCreateApplication(pid)
        var winPtr:  CFTypeRef?
        let axErr = AXUIElementCopyAttributeValue(AXApp, kAXMainWindowAttribute as CFString, &winPtr)
        if axErr != .success{
            print("error: Failed to get main window attribute")
        }
        // FIX ME: BUG!
        self.init(ele: winPtr as! AXUIElement)
    }
    
    convenience init?(app: NSRunningApplication) {
        self.init(pid: app.processIdentifier)
    }
    
    convenience init?(point: CGPoint) {
        var winPtr: AXUIElement?
        let systemWide = AXUIElementCreateSystemWide()
        
        let axErr = AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &winPtr)
        if axErr != .success {
            print("failed to get window at point, error:", axErr)
        }
        self.init(ele: winPtr!)
    }
    
    func getPoint() -> CGPoint {
        // gets the top left point of the window relative to the top left point of the screen
        var oldPointCFT:  CFTypeRef?
        if AXUIElementCopyAttributeValue(self.AXWindow, kAXPositionAttribute as CFString, &oldPointCFT) != .success {
            print("error: Failed to get window point attribute")
        }
        var currentPoint = CGPoint()
        if AXValueGetValue(oldPointCFT as! AXValue, AXValueType(rawValue: kAXValueCGPointType)!, &currentPoint) != true {
            print("error: failed to parse window CGSize")
        }
        
        return currentPoint
    }
    
    func getNSPoint() -> CGPoint {
        // gets the bottom left of window relative to the top left point of the screen
        var point = self.getPoint().flip()
        point.y -= self.getSize().height
        return point
    }
    
    func getFrame() -> NSRect {
        return NSRect(origin: self.getPoint(), size: self.getSize())
    }
    
    func getSize() -> CGSize {
        var oldSizeCFT:  CFTypeRef?
        if AXUIElementCopyAttributeValue(self.AXWindow, kAXSizeAttribute as CFString, &oldSizeCFT) != .success {
            print("error: Failed to get main window size attribute")
        }
        var currentSize = CGSize()
        if AXValueGetValue(oldSizeCFT as! AXValue, AXValueType(rawValue: kAXValueCGSizeType)!, &currentSize) != true {
            print("error: failed to parse main window CGSize")
        }
        return currentSize
    }
    
    func getAttrNames() -> [String] {
        var attrNames: CFArray?
        if AXUIElementCopyAttributeNames(AXWindow, &attrNames) != .success {
            print("could not get AXUIElementAttributeNames")
        }
        return attrNames as! [String]
    }
    
    func getScreen() -> NSScreen? {
        // https://developer.apple.com/documentation/appkit/nsscreen/1388371-main
        // Returns the screen object containing the window with the keyboard focus.
        let screen = NSScreen.main!
        return screen
    }
    
    func setFrameSize(size: CGSize) {
        var newSize = size
        let CFsize = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!,&newSize)!;
        if AXUIElementSetAttributeValue(AXWindow, kAXSizeAttribute as CFString, CFsize) != .success {
            print("error: failed to set window size")
        }
    }
    
    func setTopLeftPoint(point: CGPoint) {
        var newPoint = point
        let position = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!,&newPoint)!;
        let axErr = AXUIElementSetAttributeValue(AXWindow, kAXPositionAttribute as CFString, position)
        if axErr != .success {
            print("error: failed to set window point, ", axErr)
        }
    }
    
    func setFrameOrigin(point: CGPoint) {
        // sets the bottom left point of window relative
        var tpointFlip = point.flip()
        tpointFlip.y -= self.getSize().height
        setTopLeftPoint(point: tpointFlip)
    }
    
    func setFrame(frame: NSRect) {
        // the point is being set from the wrong side so it trys to grow into nothing.
        // we need to adjust for the target height then move back
        var t_point = frame.origin
        t_point.y += frame.height
        self.setFrameOrigin(point: t_point)
        self.setFrameSize(size: frame.size)
        self.setFrameOrigin(point: frame.origin)
    }
    
    func getWindowId() -> CGWindowID {
        var winId = CGWindowID(0)
        let axErr = _AXUIElementGetWindow(self.AXWindow, &winId)
        if axErr != .success {
            print("error: failed to get windowID, ", axErr)
        }
        return winId
    }
}
