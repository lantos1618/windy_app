//
//  windyManager.swift
//  windy
//
//  Created by Lyndon Leong on 09/01/2023.
//

import Foundation




class WindyData: ObservableObject {
    @Published var windyColumns = UserDefaults.standard.double(forKey: "windyColumns") {
        didSet {
            UserDefaults.standard.set(self.windyColumns, forKey: "windyColumns")
        }
    }
    @Published var windyRows = UserDefaults.standard.double(forKey: "windyRows") {
        didSet {
            UserDefaults.standard.set(self.windyRows, forKey: "windyRows")
        }
    }
}

enum Collision {
    case Left, Right, Top, Bottom, None
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

class WindyManager {
    var windyData = WindyData()
    private var initialLeftClickWindowOrigin: CGRect?
    private var snapWindow: NSWindow?
    
    func currentWindow()  -> WindyWindow? {
        // get the most frontMostApp
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            // throw here?
            return nil
        }
        let windyWindow = WindyWindow(app: frontApp)
        return windyWindow
    }
    
    
    // currentRect, maxRect, divPoint, actionRect -> nextRect
    //    where action: CGRect(mapped point:1,-1, 0 = left, right, 0; width: 2, -2, 1, 0= grow, shrink, nothing, collapse)
    
    
    func nextRect(currentRect: CGRect, offset: CGPoint, maxRect: CGRect, divVec: CGPoint, action: Collision) -> CGRect {
        var result = CGRect(x: 0, y: 0, width: 100, height: 100)
        var tempRect = currentRect
        // correct for offest
        // if pos is max in dir:
        //   if size < minWidth:
        //     setTo Max
        //   else:
        //     setNext Min
        // else:
        //   move dir
        // add offset
                
        tempRect.origin.x -= offset.x
        tempRect.origin.y -=  offset.y
        
        
        var minWidth = maxRect.width / divVec.x
        var minRow = maxRect.width / divVec.y
        // TODO
        
        return result
    }
    
    func calculateNextSizeX(window: WindyWindow) -> CGFloat {
        // we want to avoid having a state for each of the windows so we can make it go
        // big -> normal -> small -> big
        let screen = window.getScreen()
        let minWidth = screen.frame.width / self.windyData.windyColumns
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
        let minHeight = screen.frame.height / self.windyData.windyRows
        let currentWindowSize = window.getSize()
        let error = minHeight * 0.1

        if (currentWindowSize.height < minHeight + error) {
            return  -screen.frame.origin.y + screen.frame.height
        }
        return -screen.frame.origin.y +  currentWindowSize.height - minHeight
    }
    
    func globaLeftMouseDownHandler() {
        guard let window = self.currentWindow() else {
            print("failed to get window")
            return
        }
        let point = window.getPoint()
        let size = window.getSize()
        let initialLeftClickWindowOrigin = CGRect(x: point.x, y: point.y, width: size.width, height:  size.height)
        self.initialLeftClickWindowOrigin = initialLeftClickWindowOrigin
    }
    
    func globaLeftMouseDragHandler(with event: NSEvent) {
        guard self.initialLeftClickWindowOrigin != nil else {
            print("noInitialWindowSet")
            return
        }
        guard let window = self.currentWindow() else {
            print("failed to get window")
            return
        }
        let point = window.getPoint()
        let size = window.getSize()
        let currentLeftClickWindowOrigin = CGRect(x: point.x, y: point.y, width: size.width, height:  size.height)


        if (self.initialLeftClickWindowOrigin != currentLeftClickWindowOrigin ) {
            print("windowMoved:", currentLeftClickWindowOrigin)
            let mousePos = event.locationInWindow
            let screen = window.getScreen()
            
            if (mousePos.x < screen.frame.width * 0.10) {
                if self.snapWindow != nil {
                    if (self.snapWindow?.isVisible == false) {
                        self.snapWindow?.setIsVisible(true)
                    }
                } else {
                    self.snapWindow = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: screen.frame.width/2, height: screen.frame.height),
                        styleMask: [.fullSizeContentView],
                        backing: .buffered,
                        defer: false
                    )
//                        self.snapWindow?.titleVisibility = .hidden
//                        self.snapWindow?.toolbar?.isVisible = false
                    self.snapWindow?.backgroundColor = NSColor(calibratedRed: 0.3, green: 0.4, blue: 1, alpha: 0.2)
                    
                }
            } else {
                if self.snapWindow != nil {
                    if (self.snapWindow?.isVisible == true) {
                        self.snapWindow?.setIsVisible(false)
                    }
                }
            }
            
            if (mousePos.x > screen.frame.width * 0.90) {
                if self.snapWindow != nil {
                    if (self.snapWindow?.isVisible == false) {
                        self.snapWindow?.setIsVisible(true)
                    }
                } else {
                    self.snapWindow = NSWindow(
                        contentRect: NSRect(x: screen.frame.width/2, y: 0, width: screen.frame.width/2, height: screen.frame.height),
                        styleMask: [.fullSizeContentView],
                        backing: .buffered,
                        defer: false
                    )
//                        self.snapWindow?.titleVisibility = .hidden
//                        self.snapWindow?.toolbar?.isVisible = false
                    self.snapWindow?.backgroundColor = NSColor(calibratedRed: 0.3, green: 0.4, blue: 1, alpha: 0.2)
                    
                }
            } else {
                if self.snapWindow != nil {
                    if (self.snapWindow?.isVisible == true) {
                        self.snapWindow?.setIsVisible(false)
                    }
                }
            }
        }
    }
    
    func globaLeftMouseUpHandler(with event: NSEvent) {
        guard self.initialLeftClickWindowOrigin != nil else {
            print("noInitialWindowSet")
            return
        }
        guard let window = self.currentWindow() else {
            print("failed to get window")
            return
        }
        let point = window.getPoint()
        let size = window.getSize()
        let currentLeftClickWindowOrigin = CGRect(x: point.x, y: point.y, width: size.width, height:  size.height)

        if (self.initialLeftClickWindowOrigin != currentLeftClickWindowOrigin ) {
            let mousePos = event.locationInWindow
            let screen = window.getScreen()
            if (mousePos.x < screen.frame.width * 0.10) {
                let rec = NSRect(x: 0, y: 0, width: screen.frame.width/2, height: screen.frame.height)
                window.setSize(size: CGSize(
                    width: rec.width, height: rec.height
                ))
                window.setPoint(point: CGPoint(
                    x: rec.minX, y: rec.minY
                ))
                if self.snapWindow != nil {
                    if (self.snapWindow?.isVisible == true) {
                        self.snapWindow?.setIsVisible(false)
                    }
                }
            }
            
            if (mousePos.x > screen.frame.width * 0.90) {
                let rec = NSRect(x: 0, y: 0, width: screen.frame.width/2, height: screen.frame.height)
                window.setSize(size: CGSize(
                    width: rec.width, height: rec.height
                ))
                window.setPoint(point: CGPoint(
                    x: rec.minX, y: rec.minY
                ))
                if self.snapWindow != nil {
                    if (self.snapWindow?.isVisible == true) {
                        self.snapWindow?.setIsVisible(false)
                    }
                }
            }
        }
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
            
//             https://developer.apple.com/documentation/appkit/nsscreen/1388360-devicedescription
//             maybe useful
//            In addition to the display device constants described in NSWindow, you can also retrieve the CGDirectDisplayID value associated with the screen from this dictionary. To access this value, specify the Objective-C string @"NSScreenNumber" as the key when requesting the item from the dictionary. The value associated with this key is an NSNumber object containing the display ID value. This string is only valid when used as a key for the dictionary returned by this method.
            
//            print("screen:", NSScreen.main?.deviceDescription ,":", NSScreen.main?.frame)
            print("screen_origin:",  NSScreen.main?.frame.origin as Any)
            print("screen_size:",  NSScreen.main?.frame.size as Any)
            print("----")
            print("window_origin:", window.getPoint())
            print("window_size:", window.getSize())
            
//             if we collide then we want to cycle the sizes
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
    func registerGlobalEvents() {
        // keyboard shortcuts
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) { event in
            self.globalKeyEventHandler(with: event)
        }
        // mouse snapping - leftMouse Down
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseDown) {event in
            self.globaLeftMouseDownHandler()
        }
        // mouse snapping - leftMouse Drag
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseDragged) {event in
            self.globaLeftMouseDragHandler(with: event)
        }
        // mouse snapping - leftMouse Up
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseUp) {event in
            self.globaLeftMouseUpHandler(with: event)
        }
    }
}
