//
//  Constants.swift
//  windy
//
//  Created by Lyndon Leong on 27/01/2023.
//

import Foundation
import AppKit

// MARK: - Windy Constants
/// Centralized constants for the Windy app to eliminate magic numbers
struct WindyConstants {
    
    // MARK: - Grid Constants
    struct Grid {
        /// Default number of columns for new grid layouts
        static let defaultColumns = 2
        
        /// Default number of rows for new grid layouts
        static let defaultRows = 2
        
        /// Maximum number of columns allowed
        static let maxColumns = 6
        
        /// Maximum number of rows allowed
        static let maxRows = 6
        
        /// Minimum number of columns allowed
        static let minColumns = 1
        
        /// Minimum number of rows allowed
        static let minRows = 1
        
        /// Valid range for grid columns
        static let columnRange = minColumns...maxColumns
        
        /// Valid range for grid rows
        static let rowRange = minRows...maxRows
    }
    
    // MARK: - Snapping Constants
    struct Snapping {
        /// Distance from screen edge (in pixels) to trigger snap detection
        static let gutterSize: CGFloat = 100.0
        
        /// Fixed grid columns for snapping (legacy value)
        static let fixedGridColumns = 2.0
        
        /// Fixed grid rows for snapping (legacy value)
        static let fixedGridRows = 2.0
        
        /// Minimum distance for snap detection
        static let minSnapDistance: CGFloat = 50.0
        
        /// Animation duration for snap transitions
        static let snapAnimationDuration: TimeInterval = 0.2
    }
    
    // MARK: - Key Codes
    struct KeyCodes {
        /// Escape key code
        static let escape: UInt16 = 53
        
        /// Space key code
        static let space: UInt16 = 49
        
        /// Return/Enter key code
        static let returnKey: UInt16 = 36
        
        /// Tab key code
        static let tab: UInt16 = 48
    }
    
    // MARK: - Screen Detection Constants
    struct ScreenDetection {
        /// Maximum distance for raycast detection (in pixels)
        static let raycastMaxDistance = 10_000
        
        /// Step size for raycast detection (in pixels)
        static let raycastStep: CGFloat = 100.0
        
        /// Minimum distance between screens to consider them separate
        static let minScreenDistance: CGFloat = 50.0
        
        /// Threshold for screen overlap detection
        static let overlapThreshold: CGFloat = 10.0
    }
    
    // MARK: - Window Management Constants
    struct Window {
        /// Minimum window width (in pixels)
        static let minWidth: CGFloat = 100.0
        
        /// Minimum window height (in pixels)
        static let minHeight: CGFloat = 100.0
        
        /// Default window animation duration
        static let animationDuration: TimeInterval = 0.3
        
        /// Window resize animation curve
        static let animationCurve: NSAnimation.Curve = .easeInOut
    }
    
    // MARK: - UI Constants
    struct UI {
        /// Default accent color opacity
        static let defaultAccentOpacity: Double = 0.2
        
        /// Default accent color red component
        static let defaultAccentRed: Double = 0.4
        
        /// Default accent color green component
        static let defaultAccentGreen: Double = 0.4
        
        /// Default accent color blue component
        static let defaultAccentBlue: Double = 0.4
        
        /// Menu popover width
        static let menuPopoverWidth: CGFloat = 300.0
        
        /// Menu popover height
        static let menuPopoverHeight: CGFloat = 400.0
        
        /// Grid preview opacity
        static let gridPreviewOpacity: Double = 0.8
        
        /// Status bar icon size
        static let statusBarIconSize: CGFloat = 18.0
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        /// Key for storing grid settings per screen
        static let gridSettingsPerScreen = "gridSettingsPerScreen"
        
        /// Key for storing accent color
        static let accentColour = "accentColour"
        
        /// Key for storing display settings (legacy)
        static let displaySettings = "displaySettings"
        
        /// Key for storing default settings flag
        static let defaultsSet = "defaultsSet"
        
        /// Key for storing launch at login preference
        static let launchAtLogin = "launchAtLogin"
    }
    
    // MARK: - Notification Names
    struct Notifications {
        /// Screen parameters changed notification
        static let screenParametersChanged = NSApplication.didChangeScreenParametersNotification
        
        /// Window focus changed notification
        static let windowFocusChanged = NSWindow.didBecomeKeyNotification
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        /// Generic error message for window operations
        static let windowOperationFailed = "Failed to perform window operation"
        
        /// Error message for screen detection failures
        static let screenDetectionFailed = "Failed to detect screen"
        
        /// Error message for settings save failures
        static let settingsSaveFailed = "Failed to save settings"
        
        /// Error message for settings load failures
        static let settingsLoadFailed = "Failed to load settings"
    }
    
    // MARK: - Debug Constants
    struct Debug {
        /// Enable debug logging
        static let enableLogging = false
        
        /// Enable coordinate conversion logging
        static let logCoordinateConversions = false
        
        /// Enable screen detection logging
        static let logScreenDetection = false
    }
} 