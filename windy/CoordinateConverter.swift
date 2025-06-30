//
//  CoordinateConverter.swift
//  windy
//
//  Created by Lyndon Leong on 27/01/2023.
//

import Foundation
import AppKit
import CoreGraphics

// MARK: - Coordinate Converter
/// Centralized utility for handling coordinate system conversions between AppKit and CoreGraphics
/// 
/// AppKit uses a coordinate system where:
/// - Origin is at bottom-left of screen
/// - Y-axis increases upward
/// 
/// CoreGraphics/Accessibility uses a coordinate system where:
/// - Origin is at top-left of screen  
/// - Y-axis increases downward
struct CoordinateConverter {
    
    // MARK: - Point Conversions
    
    /// Converts a point from AppKit's coordinate system (origin bottom-left)
    /// to the CoreGraphics system (origin top-left) for a given screen.
    /// 
    /// - Parameters:
    ///   - point: The point in AppKit coordinates
    ///   - screen: The screen the point is relative to
    /// - Returns: The point in CoreGraphics coordinates
    static func appKitToCoreGraphics(point: NSPoint, on screen: NSScreen) -> CGPoint {
        let mainScreenHeight = NSScreen.screens[0].frame.height
        return CGPoint(x: point.x, y: mainScreenHeight - point.y)
    }
    
    /// Converts a point from CoreGraphics system (origin top-left)
    /// to AppKit's coordinate system (origin bottom-left) for a given screen.
    /// 
    /// - Parameters:
    ///   - point: The point in CoreGraphics coordinates
    ///   - screen: The screen the point is relative to
    /// - Returns: The point in AppKit coordinates
    static func coreGraphicsToAppKit(point: CGPoint, on screen: NSScreen) -> NSPoint {
        let mainScreenHeight = NSScreen.screens[0].frame.height
        return NSPoint(x: point.x, y: mainScreenHeight - point.y)
    }
    
    // MARK: - Rectangle Conversions
    
    /// Converts a rectangle from AppKit to CoreGraphics coordinate system.
    /// 
    /// - Parameters:
    ///   - rect: The rectangle in AppKit coordinates
    ///   - screen: The screen the rectangle is relative to
    /// - Returns: The rectangle in CoreGraphics coordinates
    static func appKitToCoreGraphics(rect: NSRect, on screen: NSScreen) -> CGRect {
        let topLeftPoint = appKitToCoreGraphics(point: NSPoint(x: rect.minX, y: rect.maxY), on: screen)
        return CGRect(origin: topLeftPoint, size: rect.size)
    }
    
    /// Converts a rectangle from CoreGraphics to AppKit coordinate system.
    /// 
    /// - Parameters:
    ///   - rect: The rectangle in CoreGraphics coordinates
    ///   - screen: The screen the rectangle is relative to
    /// - Returns: The rectangle in AppKit coordinates
    static func coreGraphicsToAppKit(rect: CGRect, on screen: NSScreen) -> NSRect {
        let bottomLeftPoint = coreGraphicsToAppKit(point: CGPoint(x: rect.minX, y: rect.maxY), on: screen)
        return NSRect(origin: bottomLeftPoint, size: rect.size)
    }
    
    // MARK: - Screen Frame Conversions
    
    /// Gets the screen frame in the CoreGraphics coordinate system,
    /// correctly accounting for the menu bar and dock.
    /// 
    /// - Parameter screen: The screen to get the frame for
    /// - Returns: The screen's visible frame in CoreGraphics coordinates
    static func getScreenVisibleFrameCG(for screen: NSScreen) -> CGRect {
        let visibleFrame = screen.visibleFrame
        let mainScreenHeight = NSScreen.screens[0].frame.height
        
        // Convert the visible frame to CoreGraphics coordinates
        let topLeftX = visibleFrame.minX
        let topLeftY = mainScreenHeight - visibleFrame.maxY
        
        return CGRect(
            x: topLeftX,
            y: topLeftY,
            width: visibleFrame.width,
            height: visibleFrame.height
        )
    }
    
    /// Gets the screen frame in the CoreGraphics coordinate system.
    /// This includes the full screen area (including menu bar and dock areas).
    /// 
    /// - Parameter screen: The screen to get the frame for
    /// - Returns: The screen's full frame in CoreGraphics coordinates
    static func getScreenFrameCG(for screen: NSScreen) -> CGRect {
        let frame = screen.frame
        let mainScreenHeight = NSScreen.screens[0].frame.height
        
        // Convert the frame to CoreGraphics coordinates
        let topLeftX = frame.minX
        let topLeftY = mainScreenHeight - frame.maxY
        
        return CGRect(
            x: topLeftX,
            y: topLeftY,
            width: frame.width,
            height: frame.height
        )
    }
    
    // MARK: - Window Position Conversions
    
    /// Converts a window's top-left position from AppKit to CoreGraphics coordinates.
    /// 
    /// - Parameters:
    ///   - topLeftPoint: The top-left point in AppKit coordinates
    ///   - screen: The screen the window is on
    /// - Returns: The top-left point in CoreGraphics coordinates
    static func windowTopLeftAppKitToCG(_ topLeftPoint: NSPoint, on screen: NSScreen) -> CGPoint {
        return appKitToCoreGraphics(point: topLeftPoint, on: screen)
    }
    
    /// Converts a window's top-left position from CoreGraphics to AppKit coordinates.
    /// 
    /// - Parameters:
    ///   - topLeftPoint: The top-left point in CoreGraphics coordinates
    ///   - screen: The screen the window is on
    /// - Returns: The top-left point in AppKit coordinates
    static func windowTopLeftCGToAppKit(_ topLeftPoint: CGPoint, on screen: NSScreen) -> NSPoint {
        return coreGraphicsToAppKit(point: topLeftPoint, on: screen)
    }
    
    // MARK: - Utility Methods
    
    /// Checks if a point is within a screen's visible frame in CoreGraphics coordinates.
    /// 
    /// - Parameters:
    ///   - point: The point to check (in CoreGraphics coordinates)
    ///   - screen: The screen to check against
    /// - Returns: True if the point is within the screen's visible frame
    static func isPointInScreenVisibleFrame(_ point: CGPoint, screen: NSScreen) -> Bool {
        let visibleFrameCG = getScreenVisibleFrameCG(for: screen)
        return visibleFrameCG.contains(point)
    }
    
    /// Gets the center point of a screen's visible frame in CoreGraphics coordinates.
    /// 
    /// - Parameter screen: The screen to get the center for
    /// - Returns: The center point in CoreGraphics coordinates
    static func getScreenVisibleFrameCenterCG(for screen: NSScreen) -> CGPoint {
        let visibleFrameCG = getScreenVisibleFrameCG(for: screen)
        return CGPoint(
            x: visibleFrameCG.midX,
            y: visibleFrameCG.midY
        )
    }
    
    /// Calculates the distance between two points in CoreGraphics coordinates.
    /// 
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: The Euclidean distance between the points
    static func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
} 