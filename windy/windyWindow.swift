//
//  windyWindow.swift
//  windy
//
//  Created by Lyndon Leong on 03/01/2023.
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
        if AXUIElementCopyAttributeValue(AXApp, kAXMainWindowAttribute as CFString, &winPtr) != .success{
            print("error: Failed to get main window attribute")
        }
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
        var oldPointCFT:  CFTypeRef?
        if AXUIElementCopyAttributeValue(self.AXWindow, kAXPositionAttribute as CFString, &oldPointCFT) != .success {
            print("error: Failed to get main window size attribute")
        }
        var currentPoint = CGPoint()
        if AXValueGetValue(oldPointCFT as! AXValue, AXValueType(rawValue: kAXValueCGPointType)!, &currentPoint) != true {
            print("error: failed to parse main window CGSize")
        }
        return currentPoint
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
    func getScreen() -> NSScreen {
        // https://developer.apple.com/documentation/appkit/nsscreen/1388371-main
        // Returns the screen object containing the window with the keyboard focus.
        let screen = NSScreen.main!
//        return CGSize(width: screen.width, height: screen.height)
        return screen
    }
    
    func setSize(size: CGSize) {
        var newSize = size
        let CFsize = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!,&newSize)!;
        if AXUIElementSetAttributeValue(AXWindow, kAXSizeAttribute as CFString, CFsize) != .success {
            print("error: failed to set window size")
        }
    }
    
    func setPoint(point: CGPoint) {
        var newPoint = point
        let position = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!,&newPoint)!;
        if AXUIElementSetAttributeValue(AXWindow, kAXPositionAttribute as CFString, position) != .success {
            print("error: failed to set window point")
        }
    }
    func getWindowId() -> CGWindowID {
        var winId = CGWindowID(0)
        let axErr = _AXUIElementGetWindow(self.AXWindow, &winId)
        if axErr != .success {
            print("error: failed to get windowID")
        }
        return winId
    }
}


