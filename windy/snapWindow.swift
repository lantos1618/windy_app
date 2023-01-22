//
//  snapWindow.swift
//  test
//
//  Created by Lyndon Leong on 22/01/2023.
//

import Foundation

class SnapWindow {
    var window: NSWindow
    init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500 , height: 500),
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 0.4)
        window.setIsVisible(false)
    }
    
    func snapMouse(point: NSPoint) {
        let screen = point.getScreen()
        // went out side of window don't draw anything
        let inSideScreen = NSPointInRect(point, screen!.frame)
        if !inSideScreen  {
            return
        }
        let insideGutter = point.collisionsInside(rect: (screen?.frame.insetBy(dx: 50, dy: 50))!)
        if insideGutter.isEmpty {
            return
        }
        
        var t_point = screen!.frame.origin
        var t_size = screen!.frame.size
        
        let columns = 2.0
        let rows = 2.0
        
        let minWidth = screen!.frame.width / columns
        let minHeight = screen!.frame.height / rows
        
        if insideGutter.contains(.Left) {
            t_size.width = minWidth
            t_point.x = screen!.frame.minX
        }
        if insideGutter.contains(.Right) {
            t_size.width = minWidth
            t_point.x = screen!.frame.maxX - t_size.width
        }
        if insideGutter.contains(.Up) {
            t_size.height = minHeight
            t_point.y = screen!.frame.minY
        }
        if insideGutter.contains(.Down) {
            t_size.height = minHeight
            t_point.y = screen!.frame.maxY - t_size.height
        }
        window.setFrame(point: t_point, size: t_size)
        window.setIsVisible(true)
        window.orderFrontRegardless()

    }
}
