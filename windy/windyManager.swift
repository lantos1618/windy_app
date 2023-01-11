//
//  windyManager.swift
//  windy
//
//  Created by Lyndon Leong on 09/01/2023.
//

import Foundation


enum Collision {
    case Left, Right, Top, Bottom, None
}

class WindyManager {
    var collumns = 2.0
    var rows = 3.0
    func currentWindow()  -> WindyWindow? {
        // get the most frontMostApp
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            // throw here?
            return nil
        }
        let windyWindow = WindyWindow(app: frontApp)
        return windyWindow
    }
    
    func infoAllWindows() {
        // get all available windows window
        guard let frontMostApp = NSWorkspace.shared.frontmostApplication else {
            // throw here
            return
        }
        let frontMostAppPID = frontMostApp.processIdentifier
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
        
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        guard let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]] else {
            // throw here
            return
        }
        
        // check if PID is the same as the window PID
        for windowInfo in windowInfoList {
            guard let windowPID = windowInfo[kCGWindowOwnerPID as String] as? UInt32 else {
                // throw here?
                break
            }
            if windowPID == frontMostAppPID {
                // do something with the window...
                print(windowInfo)
            }
        }
    }
    
    func checkCollision(window: WindyWindow ) -> [Collision] {
        // if pointX < 0 + some error
        // if pointY < 0 + some error
        // if pointX + width > screenWidth - some error
        // if pointY + height > screenHeight - some error
        // else just move

        let point = window.getPoint()
        let size = window.getSize()
        let screen = window.getScreen()
        var collisions: [Collision] = []
        let errorWidth = screen.frame.width * 0.10
        let errorHeight = screen.frame.height * 0.10
        
        // check if the window is already left most position
        let leftMost = screen.frame.origin.x + errorWidth
        if ( point.x < leftMost) {
            print("Colission! left")
            collisions.append(.Left)
        }
        
        // check if the window is already right most position
        let rightMost = screen.frame.origin.x + screen.frame.width - errorWidth
        if ( point.x + size.width > rightMost) {
            print("Colission! right")
            collisions.append(.Right)
        }
        
        // check if the window is already top most position
        let topMost =  -screen.frame.origin.y + errorHeight
        if ( point.y < topMost) {
            print("Colission! top")
            collisions.append(.Top)
        }
        
        // check if the window is already bottom most position
        let bottomMost = -screen.frame.origin.y + screen.frame.height - errorHeight
        if ( point.y + size.height > bottomMost) {
            print("Colission! bottom")
            collisions.append(.Bottom)
        }
        return collisions
    }
    
    func calculateNextSizeX(window: WindyWindow) -> CGFloat {
        // we want to avoid having a state for each of the windows so we can make it go
        // big -> normal -> small -> big
        let screen = window.getScreen()
        let minWidth = screen.frame.width / collumns
        let currentWindowSize = window.getSize()
        let error = minWidth * 0.1
        
        if (currentWindowSize.width < minWidth + error) {
            return screen.frame.origin.x + screen.frame.width
        }
        return screen.frame.origin.x + currentWindowSize.width - minWidth
    }
    
    func calculateNextSizeY(window: WindyWindow) -> CGFloat {
        // we want to avoid having a state for each of the windows so we can make it go
        // big -> normal -> small -> big
        let screen = window.getScreen()
        let minHeight = screen.frame.height / rows
        let currentWindowSize = window.getSize()
        let error = minHeight * 0.1

        if (currentWindowSize.height < minHeight + error) {
            return  -screen.frame.origin.y + screen.frame.height
        }
        return -screen.frame.origin.y +  currentWindowSize.height - minHeight
    }
    
    func globalKeyEventHandler(with event: NSEvent) {
        
        if (event.modifierFlags.contains([.option, .control])) {
            guard let specialKey = event.specialKey else { return }
            // pos
            // size
            guard let window = currentWindow() else { return }
            let screen = window.getScreen()
            var size = window.getSize()
            var point = window.getPoint()
            
//            infoAllWindows()
//            window.getAttrNames()
            
            // https://developer.apple.com/documentation/appkit/nsscreen/1388360-devicedescription
            // maybe useful
            //In addition to the display device constants described in NSWindow, you can also retrieve the CGDirectDisplayID value associated with the screen from this dictionary. To access this value, specify the Objective-C string @"NSScreenNumber" as the key when requesting the item from the dictionary. The value associated with this key is an NSNumber object containing the display ID value. This string is only valid when used as a key for the dictionary returned by this method.
            
//            print("screen:", NSScreen.main?.deviceDescription ,":", NSScreen.main?.frame)
            print("screen_origin:",  NSScreen.main?.frame.origin as Any)
            print("screen_size:",  NSScreen.main?.frame.size as Any)
            print("----")
            print("window_origin:", window.getPoint())
            print("window_size:", window.getSize())
            
            // if we collide then we want to cycle the sizes
            
            switch specialKey {
            case .leftArrow:
                // if collide set the window to left most
                if (checkCollision(window: window).contains(.Left)) {
                    size.width = calculateNextSizeX(window: window)
                    point.x = screen.frame.origin.x + 0
                } else {
                    point.x = screen.frame.origin.x + point.x - size.width
                }
            case .rightArrow:
                // if collide set the window to right most
                if (checkCollision(window: window).contains(.Right)) {
                    size.width = calculateNextSizeX(window: window)
                    point.x = screen.frame.origin.x + screen.frame.width - size.width
                } else {
                    point.x = screen.frame.origin.x + point.x + size.width

                }
            case .upArrow:
                // if collide set the window to up most
                if (checkCollision(window: window).contains(.Top)) {
                    size.height = calculateNextSizeY(window: window)
                    point.y = -screen.frame.origin.y + 0
                } else {
                    point.y = -screen.frame.origin.y + point.y - size.height
                }
            case .downArrow:
                // if collide set the window to bottom most
                if (checkCollision(window: window).contains(.Bottom)) {
                    size.height = calculateNextSizeY(window: window)
                    point.y = -screen.frame.origin.y + screen.frame.height - size.height
                } else {
                    point.y = -screen.frame.origin.y + point.y + size.height
                }
            default:
                break
            }
            window.setSize(size: size)
            window.setPoint(point: point)
        }
    }
}
