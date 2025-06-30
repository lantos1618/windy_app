//
//  ScreenManager.swift
//  windy
//
//  Created by Lyndon Leong on 27/01/2023.
//

import Foundation
import AppKit

// MARK: - Screen Direction
/// Represents the four cardinal directions for screen navigation
enum ScreenDirection: CaseIterable {
    case left
    case right
    case up
    case down
    
    /// Get the opposite direction
    var opposite: ScreenDirection {
        switch self {
        case .left: return .right
        case .right: return .left
        case .up: return .down
        case .down: return .up
        }
    }
}

// MARK: - Screen Manager
/// Manages screen detection and navigation between screens
struct ScreenManager {
    
    // MARK: - Screen Detection
    
    /// Find the next screen in a given direction from the current screen
    /// 
    /// - Parameters:
    ///   - currentScreen: The screen to start from
    ///   - direction: The direction to search
    /// - Returns: The next screen in that direction, or nil if none found
    static func findNextScreen(from currentScreen: NSScreen, in direction: ScreenDirection) -> NSScreen? {
        let otherScreens = NSScreen.screens.filter { $0 != currentScreen }
        let currentFrame = currentScreen.frame
        
        var bestCandidate: NSScreen? = nil
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for screen in otherScreens {
            let candidateFrame = screen.frame
            
            if isScreenInDirection(candidateFrame, relativeTo: currentFrame, direction: direction) {
                let distance = calculateDistance(from: currentFrame, to: candidateFrame, direction: direction)
                
                if distance < minDistance {
                    minDistance = distance
                    bestCandidate = screen
                }
            }
        }
        
        return bestCandidate
    }
    
    /// Get all screens that are in a given direction from the current screen
    /// 
    /// - Parameters:
    ///   - currentScreen: The screen to start from
    ///   - direction: The direction to search
    /// - Returns: Array of screens in that direction, sorted by distance
    static func getScreensInDirection(from currentScreen: NSScreen, direction: ScreenDirection) -> [NSScreen] {
        let otherScreens = NSScreen.screens.filter { $0 != currentScreen }
        let currentFrame = currentScreen.frame
        
        let screensInDirection = otherScreens.filter { screen in
            isScreenInDirection(screen.frame, relativeTo: currentFrame, direction: direction)
        }
        
        return screensInDirection.sorted { screen1, screen2 in
            let distance1 = calculateDistance(from: currentFrame, to: screen1.frame, direction: direction)
            let distance2 = calculateDistance(from: currentFrame, to: screen2.frame, direction: direction)
            return distance1 < distance2
        }
    }
    
    /// Find the screen that contains a given point
    /// 
    /// - Parameter point: The point to find the screen for (in AppKit coordinates)
    /// - Returns: The screen containing the point, or nil if none found
    static func findScreenContaining(point: NSPoint) -> NSScreen? {
        return NSScreen.screens.first { screen in
            screen.frame.contains(point)
        }
    }
    
    /// Find the screen that contains a given point in CoreGraphics coordinates
    /// 
    /// - Parameter point: The point to find the screen for (in CoreGraphics coordinates)
    /// - Returns: The screen containing the point, or nil if none found
    static func findScreenContaining(point: CGPoint) -> NSScreen? {
        let appKitPoint = CoordinateConverter.coreGraphicsToAppKit(point: point, on: NSScreen.main!)
        return findScreenContaining(point: appKitPoint)
    }
    
    // MARK: - Screen Analysis
    
    /// Check if two screens overlap
    /// 
    /// - Parameters:
    ///   - screen1: First screen
    ///   - screen2: Second screen
    /// - Returns: True if the screens overlap
    static func doScreensOverlap(_ screen1: NSScreen, _ screen2: NSScreen) -> Bool {
        let frame1 = screen1.frame
        let frame2 = screen2.frame
        
        return frame1.intersects(frame2)
    }
    
    /// Get the distance between two screens
    /// 
    /// - Parameters:
    ///   - screen1: First screen
    ///   - screen2: Second screen
    /// - Returns: The minimum distance between the screens
    static func distanceBetween(_ screen1: NSScreen, _ screen2: NSScreen) -> CGFloat {
        let frame1 = screen1.frame
        let frame2 = screen2.frame
        
        // Calculate the minimum distance between the rectangles
        let horizontalDistance = max(0, max(frame1.minX - frame2.maxX, frame2.minX - frame1.maxX))
        let verticalDistance = max(0, max(frame1.minY - frame2.maxY, frame2.minY - frame1.maxY))
        
        return sqrt(horizontalDistance * horizontalDistance + verticalDistance * verticalDistance)
    }
    
    /// Get the screen with the highest resolution
    /// 
    /// - Returns: The screen with the highest resolution, or the main screen if none found
    static func getHighestResolutionScreen() -> NSScreen {
        let screens = NSScreen.screens
        
        guard !screens.isEmpty else {
            return NSScreen.main ?? NSScreen.screens[0]
        }
        
        return screens.max { screen1, screen2 in
            let resolution1 = screen1.frame.width * screen1.frame.height
            let resolution2 = screen2.frame.width * screen2.frame.height
            return resolution1 < resolution2
        } ?? NSScreen.main ?? screens[0]
    }
    
    // MARK: - Private Helper Methods
    
    private static func isScreenInDirection(_ candidateFrame: NSRect, relativeTo currentFrame: NSRect, direction: ScreenDirection) -> Bool {
        switch direction {
        case .left:
            return candidateFrame.maxX <= currentFrame.minX
            
        case .right:
            return candidateFrame.minX >= currentFrame.maxX
            
        case .up:
            return candidateFrame.minY >= currentFrame.maxY
            
        case .down:
            return candidateFrame.maxY <= currentFrame.minY
        }
    }
    
    private static func calculateDistance(from currentFrame: NSRect, to candidateFrame: NSRect, direction: ScreenDirection) -> CGFloat {
        switch direction {
        case .left:
            return currentFrame.minX - candidateFrame.maxX
            
        case .right:
            return candidateFrame.minX - currentFrame.maxX
            
        case .up:
            return candidateFrame.minY - currentFrame.maxY
            
        case .down:
            return currentFrame.minY - candidateFrame.maxY
        }
    }
    
    // MARK: - Legacy Raycast Replacement
    
    /// Replace the old raycast logic with a more robust approach
    /// 
    /// - Parameters:
    ///   - fromPoint: Starting point for the search
    ///   - direction: Direction to search
    ///   - maxDistance: Maximum distance to search
    /// - Returns: The screen found in that direction, or nil if none found
    static func findScreenInDirection(from fromPoint: NSPoint, direction: ScreenDirection, maxDistance: CGFloat = CGFloat(WindyConstants.ScreenDetection.raycastMaxDistance)) -> NSScreen? {
        // First, find which screen contains the starting point
        guard let currentScreen = findScreenContaining(point: fromPoint) else {
            return nil
        }
        
        // Use the robust screen detection method
        return findNextScreen(from: currentScreen, in: direction)
    }
    
    /// Get all screens in a given direction from a point
    /// 
    /// - Parameters:
    ///   - fromPoint: Starting point for the search
    ///   - direction: Direction to search
    /// - Returns: Array of screens in that direction
    static func getAllScreensInDirection(from fromPoint: NSPoint, direction: ScreenDirection) -> [NSScreen] {
        guard let currentScreen = findScreenContaining(point: fromPoint) else {
            return []
        }
        
        return getScreensInDirection(from: currentScreen, direction: direction)
    }
} 