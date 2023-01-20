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


enum Direction {
    case Left, Right, Up, Down
}
enum Collision {
    case Left, Right, Top, Bottom, None, OutOfBounds
}

func checkCollision(window: WindyWindow) -> [Collision] {
    // if pointX < 0 + some error
    // if pointY < 0 + some error
    // if pointX + width > screenWidth - some error
    // if pointY + height > screenHeight - some error
    // else just move

    let point = window.getPoint()
    let size = window.getSize()
    guard let screen = window.getScreen() else {
        print("error: failed to get screen")
        return []
    }
    var collisions: [Collision] = []
    
    let hotZone = 0.05
    
    // check if the window is already left most position
    let leftMost = screen.frame.origin.x + screen.frame.width * hotZone
    if ( point.x < leftMost) {
        print("Colission! left")
        collisions.append(.Left)
    }
    
    // check if the window is already right most position
    let rightMost = screen.frame.origin.x + screen.frame.width * (1 - hotZone)
    if ( point.x + size.width > rightMost) {
        print("Colission! right")
        collisions.append(.Right)
    }
    
    // check if the window is already top most position
    let topMost =  -screen.frame.origin.y + screen.frame.width * hotZone
    if ( point.y < topMost) {
        print("Colission! top")
        collisions.append(.Top)
    }
    
    // check if the window is already bottom most position
    let bottomMost = -screen.frame.origin.y + screen.frame.height * (1 - hotZone)
    if ( point.y + size.height > bottomMost) {
        print("Colission! bottom")
        collisions.append(.Bottom)
    }
    return collisions
}


func mouseCollision(mousePos: CGPoint, screen: NSScreen) -> [Collision] {
    var collisions: [Collision] = []
    let hotZone = 0.05
    
    // need to make this relative to offset
    let mousePosX = mousePos.x
    let mousePosY = mousePos.y

    if
        mousePosX < 0 ||
        mousePosY < 0 ||
        mousePosX > screen.frame.width ||
        mousePosY > screen.frame.height
    {
        return [.OutOfBounds]
    }

    // check bounds
    if mousePosX < screen.frame.width * hotZone {
        collisions.append(.Left)
    }
    if mousePos.x > screen.frame.width * (1 - hotZone) {
        collisions.append(.Right)
    }
    if mousePos.y > screen.frame.height *  (1 - hotZone) {
        collisions.append(.Top)
    }
    if mousePos.y < screen.frame.height * hotZone {
        collisions.append(.Bottom)
    }
    return collisions
}

class WindyManager {
    var windyData = WindyData()
    
    private var initialLeftClickWindowId: CGWindowID? = nil
    private var initialLeftClickWindowOrigin: CGRect? = nil
    private var snapWindow: NSWindow? = nil
    private var isWindowResizing: Bool = false
    
    func currentWindow()  -> WindyWindow? {
        // get the most frontMostApp
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            // throw here?
            return nil
        }
        let windyWindow = WindyWindow(app: frontApp)
        return windyWindow
    }

    func drawSnapWindow(rect: NSRect) {
        if self.snapWindow == nil {
            self.snapWindow = NSWindow(
                contentRect: rect,
                styleMask: [.fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            self.snapWindow?.backgroundColor = NSColor(calibratedRed: 0.3, green: 0.4, blue: 1, alpha: 0.2)
            return
        }
        self.snapWindow?.setFrame(rect, display: true, animate: true)
        self.snapWindow?.setIsVisible(true)
    }

    func hideSnapWindow() {
        if self.snapWindow == nil {
            return
        }
        self.snapWindow?.setIsVisible(false)
    }

    func cleanUpSnapWindow() {
        self.hideSnapWindow()
        self.initialLeftClickWindowOrigin = nil
        self.initialLeftClickWindowId = nil
        self.isWindowResizing = false
    }

    func globaLeftMouseDownHandler(with event: NSEvent) {
        guard let window = self.currentWindow() else {
            print("error: failed to get window")
            return
        }
        let point = window.getPoint()
        let size = window.getSize()
        self.initialLeftClickWindowOrigin = CGRect(x: point.x, y: point.y, width: size.width, height:  size.height)
        self.initialLeftClickWindowId = window.getWindowId()
    }
    
    func globaLeftMouseDragHandler(with event: NSEvent) {
        guard self.initialLeftClickWindowOrigin != nil else {
            print("error: noInitialWindowSet")
            return
        }
        guard let window = self.currentWindow() else {
            print("error: failed to get window")
            return
        }
        if self.initialLeftClickWindowId != window.getWindowId() {
            print("error: windowId are not the same")
            return
        }

        let point = window.getPoint()
        let size = window.getSize()
        let currentLeftClickWindowOrigin = CGRect(x: point.x, y: point.y, width: size.width, height: size.height)
        
        self.isWindowResizing = self.initialLeftClickWindowOrigin != currentLeftClickWindowOrigin
        
        if (!self.isWindowResizing) {
            return
        }
        
        self.DrawSnapWindow(event: event, window: window)
    }
    
    func DrawSnapWindow(event: NSEvent, window: WindyWindow) {
        let mousePos = event.locationInWindow
        guard let screen = window.getScreen() else {
            print("error: failed to get screen")
            return
        }
        print("screen:", screen.deviceDescription)

        let collission = mouseCollision(mousePos: mousePos, screen:  screen)
        var tRect = NSRect(x: 0, y: 0, width: screen.frame.width, height: screen.frame.height)
        
        if collission.isEmpty {
            self.hideSnapWindow()
            return
        }
        
        if collission.elementsEqual([.OutOfBounds]) {
            // we want to deal with screen move
            return
        }
        if collission.contains(.Left) {
            tRect.size.width /= 2
        }
        if collission.contains(.Right) {
            tRect.origin.x = screen.frame.width/2
            tRect.size.width /= 2
        }
        if collission.contains(.Top) {
            tRect.size.height /= 2
        }
        if collission.contains(.Bottom) {
            tRect.origin.y = screen.frame.height/2
            tRect.size.height /= 2
        }
        // we need to convert to BottomLeft
        var tRectFlip = tRect
        tRectFlip.origin.y = screen.frame.height - tRectFlip.height - tRectFlip.origin.y
        self.drawSnapWindow(rect: tRectFlip)
    }
    
    func globaLeftMouseUpHandler(with event: NSEvent) {
        // guard to check if the window is moving
        if !self.isWindowResizing { return }
        // guard check snapWindow is set
        if self.snapWindow == nil { return }
        // guard to see if the window was drawn
        if !(self.snapWindow?.isVisible ?? false) { return }
        
        guard let window = self.currentWindow() else {
            print("failed to get window")
            return
        }
        
        // get the snap window to move to
        var tOrigin = self.snapWindow?.frame.origin ?? CGPoint(x: 0, y: 0)
        let tSize = self.snapWindow?.frame.size ?? CGSize(width: 100, height: 100)

        guard let screen = window.getScreen() else {
            print("error: failed to get screen")
            return
        }
        tOrigin.y = screen.frame.height - tOrigin.y - tSize.height
        window.setSize(size: tSize)
        window.setPoint(point: tOrigin)
        cleanUpSnapWindow()
    }
    
    func decodeKey(specialKey: NSEvent.SpecialKey) -> Direction? {
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
    func move(window: WindyWindow, direction: Direction) {
        // move window by minWidth
        guard let screen = window.getScreen() else { return }
        let minWidth = screen.frame.width / windyData.windyColumns
        let minHeight = screen.frame.height / windyData.windyRows
        var point = window.getPoint()
                
        switch direction {
        case .Left:
            point.x -= minWidth
            break
        case .Right:
            point.x += minWidth
            break
        case .Up:
            point.y -= minHeight
            break
        case .Down:
            point.y += minHeight
            break
        }
        window.setPoint(point: point)
    }
    func resize(window: WindyWindow, collisions: [Collision]) {
        guard let screen = window.getScreen() else { return }
        let minWidth = screen.frame.width / windyData.windyColumns
        let minHeight = screen.frame.height / windyData.windyRows
        var point = CGPoint(x: 0, y: 0)
        var size = window.getSize()
        
        if collisions.contains(.Left) {
            size.width -= minWidth
        }
        if collisions.contains(.Right) {
            size.width += minWidth
            point.x = screen.frame.width - size.width
        }
        if collisions.contains(.Top) {
            size.height -= minHeight
        }
        if collisions.contains(.Bottom) {
            size.height += minHeight
            point.y = screen.frame.height - size.height
        }
        if size.width < minWidth {
            size.width = screen.frame.width
        }
        if size.height < minHeight {
            size.height = screen.frame.height
        }
        window.setSize(size: size)
        window.setPoint(point: point)
    }
    
    func globalKeyEventHandler(with event: NSEvent) {
        if (event.modifierFlags.contains([.option, .control])) {
            //        if window no colision:
            //            move
            //            return
            //        resize
            guard let specialKey = event.specialKey else { return }
            guard let window = currentWindow() else { return }
            guard let direction = decodeKey(specialKey: specialKey) else { return }
            let colissions = checkCollision(window: window)
            if colissions.isEmpty {
                move(window: window, direction: direction)
                return
            }
            resize(window: window, collisions: colissions)
        }
    }
    func registerGlobalEvents() {
        // keyboard shortcuts
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: self.globalKeyEventHandler)
        // mouse snapping - leftMouse Down
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: self.globaLeftMouseDownHandler)
        // mouse snapping - leftMouse Drag
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged, handler: self.globaLeftMouseDragHandler)
        // mouse snapping - leftMouse Up
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp, handler: self.globaLeftMouseUpHandler)
    }
}
