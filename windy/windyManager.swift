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
    init() {
        if UserDefaults.standard.bool(forKey: "defaultSet") == false {
            UserDefaults.standard.set(2, forKey: "windyColumns")
            UserDefaults.standard.set(2, forKey: "windyRows")
            UserDefaults.standard.set(true, forKey: "defaultSet")
        }
    }
}

class WindyManager {
    var windyData = WindyData()
    // window snapping
    var windyWindow: WindyWindow!
    var initialWindyWindowPos = NSPoint(x: 0, y: 0)
    var snapWindow = SnapWindow()
    var windowIsMoving = false

    func globalLeftMouseDownHandler(event: NSEvent) {
        windyWindow = currentWindow()
        initialWindyWindowPos = windyWindow.getPoint()
    }
    
    func globalLeftMouseDragHandler(event: NSEvent) {
        let t_windyWindowPos = windyWindow.getPoint()
        // check to see if a window is being moved if not cancel
        if (t_windyWindowPos != initialWindyWindowPos) {
                windowIsMoving = true
        }
        if (windowIsMoving) {
            snapWindow.snapMouse(point: NSEvent.mouseLocation)
        }
    }
    
    func globalLeftMouseUpHandler(event: NSEvent) {
        if(snapWindow.window.isVisible) {
            windyWindow.setFrame(frame: snapWindow.window.frame)
            snapWindow.window.setIsVisible(false)
        }
        windowIsMoving = false
    }
    
    func currentWindow()  -> WindyWindow? {
        // get the most frontMostApp
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        return WindyWindow(app: frontApp)
    }
    func move(window: WindyWindow, direction: Direction) {
        let screen = NSScreen.main!
        var point = window.getNSPoint()
        let columns = 2.0
        let rows = 2.0
        let minWidth = screen.frame.maxX / columns
        let minHeight = screen.frame.maxY / rows
        
        switch direction {
        case .Left:
            point.x -= minWidth
        case .Right:
            point.x += minWidth
        case .Up:
            point.y += minHeight
        case .Down:
            point.y -= minHeight
        }
        
        var screenSize = screen.frame.size
        let windowSize = window.getSize()
        screenSize.width -= windowSize.width
        point = point.clamp(NSRect(origin: screen.frame.origin, size: screenSize))
        window.setFrameOrigin(point: point)
    }

    func resize(window: WindyWindow, direction: Direction) {
        let screen = NSScreen.main!
        let point = window.getNSPoint()
        var size = window.getSize()
        let columns = 2.0
        let rows = 2.0
        let minWidth = screen.frame.maxX / columns
        let minHeight = screen.frame.maxY / rows
        
        
        switch direction {
        case .Left, .Right:
            size.width += minWidth * (size.width <= minWidth ? columns : -1.0)
        case .Up, .Down:
            size.height += minHeight * (size.height <= minHeight ? rows : -1.0)
        }
        print(size)
        
        
        window.setFrame(frame: NSRect(origin: point, size: size))
//        move(window: window, direction: direction)
    }
    func globalKeyEventHandler(event: NSEvent) {
        if (event.modifierFlags.contains([.option, .control])) {
            guard let direction = event.direction else { return }
            let window = currentWindow()!
            let windowFrame =  window.getFrame()
            let screenFrame = window.getScreen()!.frame
            let windowCollisions = windowFrame.collisionsInside(rect: screenFrame)
            // if there are no window collisions we can move the window in the direction
            
            let canMove = !windowCollisions.contains(direction)
            print("windowCollisions", windowCollisions)
            print("can move", canMove)
            
            if canMove || windowCollisions.isEmpty {
                move(window: window, direction: direction)
                return
            }
            resize(window: window, direction: direction)
        }
    }
    
    func registerGlobalEvents() {
        // keyboard shortcuts
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: self.globalKeyEventHandler)
        // snapping window
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: self.globalLeftMouseDownHandler)
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged, handler: self.globalLeftMouseDragHandler)
//        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged, handler: {_ in
//            self.currentWindow()?.setFrameOrigin(point: NSEvent.mouseLocation)
//            print("mouse:", NSEvent.mouseLocation)
//            print("windowMax", (self.currentWindow()?.getFrame().maxX)!, (self.currentWindow()?.getFrame().maxY)!)
//            print("screenMAx", (NSScreen.main!.frame.maxX), (NSScreen.main!.frame.maxY))
//            print("collision", (self.currentWindow()?.getFrame().collisionsInside(rect: NSScreen.main!.frame)))
//        })
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp, handler: self.globalLeftMouseUpHandler)
    }
}
