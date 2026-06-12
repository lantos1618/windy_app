//
//  utils.swift
//  test
//
//  Created by Lyndon Leong on 22/01/2023.
//

import Foundation
import SwiftUI

// MARK: - Error Types
enum WindyWindowError: Error {
    case AXValueError(message: String)
    case NSError(message: String)
}

// MARK: - Direction Enum
enum Direction {
    case Left, Right, Up, Down
}

// MARK: - NSEvent Extensions
extension NSEvent {
    /// Converts NSEvent special keys to Direction enum for window movement
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

// MARK: - FloatingPoint Extensions
extension FloatingPoint {
    /// Clamps a value to a specified range
    func clamp(to range: ClosedRange<Self>) -> Self {
        return max(min(self, range.upperBound), range.lowerBound)
    }
}

// MARK: - NSPoint Extensions
extension NSPoint {
    /// Clamps a point to screen bounds using visibleFrame
    func clamp(_ screen: NSScreen) -> NSPoint {
        return self.clamp(screen.visibleFrame)
    }
    
    /// Clamps a point to rectangle bounds (0 to width/height)
    func clamp(_ rect: NSRect) -> NSPoint {
        var point   = self
        point.x     = point.x.clamp(to: 0...rect.width)
        point.y     = point.y.clamp(to: 0...rect.height)
        return point
    }
    
    /// Finds which screen contains this point, falls back to main screen
    func getScreen() -> NSScreen? {
        ScreenGeometryService.screen(containingAppKitPoint: self)
    }
    
    /// Determines which edges of a rectangle this point collides with
    /// Returns array of Directions where collision occurs
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
    
    /// Legacy vertical mirror helper. New window placement code should use ScreenGeometryService.
    func flip() -> NSPoint {
        ScreenGeometryService.mirroredPointAcrossPrimaryDisplay(self)
    }
}

// MARK: - CGPoint Extensions
extension CGPoint {
    /// Converts CoreGraphics coordinates to AppKit coordinates for a specific display
    /// CoreGraphics origin is top-left, AppKit origin is bottom-left
    func convertedToAppKit(displayID: CGDirectDisplayID) -> CGPoint {
        return .init(
            x: x,
            y: CGDisplayBounds(displayID).height - y
        )
    }

    /// Converts AppKit coordinates to CoreGraphics coordinates for a specific display
    /// AppKit origin is bottom-left, CoreGraphics origin is top-left
    func convertedToCoreGraphics(displayID: CGDirectDisplayID) -> CGPoint {
        return .init(
            x: x,
            y: CGDisplayBounds(displayID).height - y
        )
    }
}

// MARK: - NSRect Extensions
extension NSRect {
    /// Determines which edges of a rectangle this rect collides with
    /// Returns array of Directions where collision occurs
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
    
    /// Returns the center point of this rectangle
    func centerPoint() -> NSPoint {
        return NSPoint(x: self.midX, y: midY)
    }
}

// MARK: - NSWindow Extensions
extension NSWindow {
    // TODO: Implement setFlipped method for coordinate system conversion
    // This would handle AppKit to CoreGraphics coordinate conversion
//    func setFlipped(_ point: NSPoint, screen: NSScreen) {
//        var tPoint = point
//    }
    
    /// Sets the window size while maintaining current position
    func setFrameSize(_ size: CGSize) {
        var frame   = self.frame
        frame.size  = size
        self.setFrame(frame, display: self.isVisible)
    }
    
    /// Sets both position and size of the window
    func setFrame(origin: NSPoint, size: NSSize) {
        self.setFrame(NSRect(origin: origin, size: size), display: true)
    }
    
    /// Determines which edges of a rectangle this window collides with
    func collisionsInside(rect: NSRect) -> [Direction] {
        return self.frame.collisionsInside(rect: rect)
    }
}

// MARK: - Color Extensions
extension Color {
    /// Explicitly extracted Core Graphics color's
    /// for the purpose of reconstruction and persistence.
    var cgColor_: CGColor {
        NSColor(self).cgColor
    }
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    // MARK: Color Persistence
    /// Stores a Color as an array of CGFloat components
    func set(_ color: Color, forKey key: String) {
        let cgColor     = color.cgColor_
        let array       = cgColor.components ?? []
        set(array, forKey: key)
    }

    /// Retrieves a Color from stored CGFloat components
    func color(forKey key: String) -> Color {
        guard let array     = object(forKey: key) as? [CGFloat] else { return .accentColor }
        let color           = CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: array)!
        return Color(color)
    }
    
    // MARK: NSPoint Dictionary Persistence
    /// Stores a dictionary of NSPoints as JSON data
    func set(dict: [String: NSPoint], forKey: String) throws {
        let encode = JSONEncoder()
        let data = try encode.encode(dict)
        UserDefaults.standard.set(data, forKey: forKey)
    }
    
    /// Retrieves a dictionary of NSPoints from stored JSON data
    func getDictPoints(forKey: String) throws -> [String: NSPoint] {
        guard let data  = UserDefaults.standard.data(forKey: forKey) else {
            throw WindyWindowError.NSError(message: "key:\(forKey) Not Found")
        }
        let decoder     = JSONDecoder()
        return try decoder.decode([String: NSPoint].self, from: data)
    }
}

// MARK: - NSScreen Extensions
extension NSScreen {
    /// Creates a unique identifier string for this screen
    /// Format: "display:<CGDirectDisplayID>"
    func getIdString() -> String {
        ScreenGeometryService.id(for: self)
    }
    
    /// Finds a screen by its identifier string
    static func fromIdString(str: String) -> NSScreen? {
        ScreenGeometryService.screen(for: str)
    }
    
    /// Gets the CoreGraphics display ID for this screen
    var displayID: CGDirectDisplayID {
         let key = NSDeviceDescriptionKey(rawValue: "NSScreenNumber")
         if let displayID = deviceDescription[key] as? CGDirectDisplayID {
             return displayID
         }
         if let displayID = deviceDescription[key] as? NSNumber {
             return CGDirectDisplayID(displayID.uint32Value)
         }
         return CGMainDisplayID()
     }
    
    /// Compatibility wrapper for the visible screen frame in accessibility coordinates.
    func getQuartsSafeFrame() -> NSRect {
        ScreenGeometryService.accessibilityVisibleFrame(for: self)
    }
}

// MARK: - Grid Creation Functions
/// Creates a 2D array of rectangles representing a grid layout
/// Used for window snapping and grid visualization
/// 
/// @param columns: Number of columns in the grid
/// @param rows: Number of rows in the grid  
/// @param screen: The screen to create the grid for
/// @return: 2D array of NSRect representing grid cells
func createRects(columns: Double, rows: Double, screen: NSScreen) -> [[NSRect]] {
    guard columns > 0, rows > 0 else {
        return []
    }

    return WindowLayoutEngine.gridRects(
        columns: Int(columns),
        rows: Int(rows),
        in: NSRect(origin: .zero, size: screen.frame.size)
    )
}

// MARK: - Mouse Control Functions
/// Moves the mouse cursor to a specific point using CoreGraphics events
/// Used for programmatic mouse control
func moveMouseTo(point: CGPoint) {
    CGEvent(
        mouseEventSource    : nil,
        mouseType           : CGEventType.mouseMoved,
        mouseCursorPosition : point,
        mouseButton         : CGMouseButton.left
    )?.post(tap: CGEventTapLocation.cghidEventTap)
}
