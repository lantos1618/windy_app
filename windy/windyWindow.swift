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
        var AXApp = AXUIElementCreateApplication(pid)
        var winPtr:  CFTypeRef?
        if AXUIElementCopyAttributeValue(AXApp, kAXMainWindowAttribute as CFString, &winPtr) != .success{
            print("error: Failed to get main window attribute")
        }
        self.init(ele: winPtr as! AXUIElement)
    }
    convenience init?(app: NSRunningApplication) {
        self.init(pid: app.processIdentifier)
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
    func setSize(size: CGSize) {
        var newSize = size
        var CFsize = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!,&newSize)!;
        if AXUIElementSetAttributeValue(AXWindow, kAXSizeAttribute as CFString, CFsize) != .success {
            print("error: failed to set window size")
        }
    }
    func setPoint(point: CGPoint) {
        var newPoint = point
        var position = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!,&newPoint)!;
        if AXUIElementSetAttributeValue(AXWindow, kAXPositionAttribute as CFString, position) != .success {
            print("error: failed to set window point")
        }
    }
}


