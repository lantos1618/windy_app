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
        let maxWidth = screen.frame.maxX / columns
        let maxHeight = screen.frame.maxY / rows
        
        switch direction {
        case .Left:
            point.x -= maxWidth
        case .Right:
            point.x += maxWidth
        case .Up:
            point.y += maxHeight
        case .Down:
            point.y -= maxHeight
        }
        
        var screenSize = screen.frame.size
        var windowSize = window.getSize()
        screenSize.width -= windowSize.width
        point = point.clamp(NSRect(origin: screen.frame.origin, size: screenSize))
        window.setFrameOrigin(point: point)
    }

    func resize(window: WindyWindow) {
        
    }
    func globalKeyEventHandler(event: NSEvent) {
        if (event.modifierFlags.contains([.option, .control])) {
            guard let direction = event.direction else { return }
            let window = currentWindow()!
            let windowFrame =  window.getFrame()
            let screenFrame = window.getScreen()!.frame
            let windowCollisions = windowFrame.collisionsInside(rect: screenFrame)
            // if there are no window collisions we can move the window in the direction
            let canMoveArr = windowCollisions.map { collision in collision != direction }
            let canMove = canMoveArr.reduce(false) {(x, y) in x || y}
            print("windowCollisions", windowCollisions)
            print("canMoveArr", canMoveArr)
            print("can move", canMove)
            if canMove || windowCollisions.isEmpty {
                move(window: window, direction: direction)
                return
            }
            //        resize(window: window, direction)
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
