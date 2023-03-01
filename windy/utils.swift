//
//  utils.swift
//  test
//
//  Created by Lyndon Leong on 22/01/2023.
//

import Foundation
import SwiftUI


enum WindyWindowError: Error {
    case AXValueError(message: String)
    case NSError(message: String)
}


enum Direction {
    case Left, Right, Up, Down
}

extension NSEvent {
    var direction: Direction? {
        get {
            guard let specialKey = self.specialKey else {return nil}
            switch specialKey {
            case .leftArrow:
                return .Left
            case .rightArrow:
                return .Right
            case .upArrow:
                return .Up
            case .downArrow:
                return .Down
            default:
                 return nil
            }
        }
    }
}

extension FloatingPoint {
    func clamp(to range: ClosedRange<Self>) -> Self {
        return max(min(self, range.upperBound), range.lowerBound)
    }
}



extension NSPoint {
    func clamp(_ screen: NSScreen) -> NSPoint {
        return self.clamp(screen.visibleFrame)
    }
    
    func clamp(_ rect: NSRect) -> NSPoint {
        var point = self
        point.x = point.x.clamp(to: 0...rect.width)
        point.y = point.y.clamp(to: 0...rect.height)
        return point
    }
    
    func getScreen() -> NSScreen? {
        let screens = NSScreen.screens
        let screenWithMouse = (screens.first {screen in
            NSPointInRect(self, screen.frame)})
        return screenWithMouse ?? NSScreen.main
    }
    
    func collisionsInside(rect: NSRect) -> [Direction] {
        var result: [Direction] = []
        if self.x <= rect.minX {
            result.append(.Left)
        }
        if self.x >= rect.maxX {
            result.append(.Right)
        }
        if self.y <= rect.minY {
            result.append(.Down)
        }
        if self.y >= rect.maxY {
            result.append(.Up)
        }
        return result
    }
    
    func flip() -> NSPoint {
        return NSPoint(x: x, y: NSScreen.screens[0].frame.maxY - self.y)
    }
}

extension NSRect {
    func collisionsInside(rect: NSRect) -> [Direction] {
        var result: [Direction] = []
        
        if self.minX <= rect.minX {
            result.append(.Left)
        }
        if self.maxX >= rect.maxX {
            result.append(.Right)
        }
        if self.minY <= rect.minY {
            result.append(.Up)
        }
        if self.maxY >= rect.maxY {
            result.append(.Down)
        }
        return result
    }
    func centerPoint() -> NSPoint {
        return NSPoint(x: self.midX, y: midY)
    }
}

extension NSWindow {
//    func setFlipped(_ point: NSPoint, screen: NSScreen) {
//        var tPoint = point
//    }
    func setFrameSize(_ size: CGSize) {
        var frame = self.frame
        frame.size = size
        self.setFrame(frame, display: self.isVisible)
    }
    
    func setFrame(origin: NSPoint, size: NSSize) {
        self.setFrame(NSRect(origin: origin, size: size), display: true)
    }
    
    func collisionsInside(rect: NSRect) -> [Direction] {
        return self.frame.collisionsInside(rect: rect)
    }
}

extension Color {

    /// Explicitly extracted Core Graphics color's
    /// for the purpose of reconstruction and persistence.
    var cgColor_: CGColor {
        NSColor(self).cgColor
    }
}

extension UserDefaults {
    // color
    func set(_ color: Color, forKey key: String) {
        let cgColor = color.cgColor_
        let array = cgColor.components ?? []
        set(array, forKey: key)
    }

    func color(forKey key: String) -> Color {
        guard let array = object(forKey: key) as? [CGFloat] else { return .accentColor }
        let color = CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: array)!
        return Color(color)
    }
    // [String: NSPoint]
    func set(dict: [String: NSPoint], forKey: String) throws {
        let encode = JSONEncoder()
        let data = try encode.encode(dict)
        UserDefaults.standard.set(data, forKey: forKey)
    }
    func getDictPoints(forKey: String) throws -> [String: NSPoint] {
        guard let data = UserDefaults.standard.data(forKey: forKey) else {
            throw WindyWindowError.NSError(message: "key:\(forKey) Not Found")
        }
        let decoder = JSONDecoder()
        return try decoder.decode([String: NSPoint].self, from: data)
        
    }
}

extension NSScreen {
    func getIdString() -> String {
        return "\(self.hash):\(self.localizedName)"
    }
}
