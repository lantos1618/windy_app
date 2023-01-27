//
//  gridManager.swift
//  windy
//
//  Created by Lyndon Leong on 26/01/2023.
//

import Foundation
import SwiftUI

//class GridManagerData: ObservableObject {
//    @Published var columns = 2.0 {
//        didSet {
//            print(columns)
//            UserDefaults.standard.set(self.columns, forKey: "columns")
//        }
//    }
//    @Published var rows = 2.0  {
//        didSet {
//            UserDefaults.standard.set(self.rows, forKey: "rows")
//        }
//    }
//    @Published var isShown = false
//    @Published var point =  NSPoint(x: 0, y: 0)
//    @Published var rects: [NSRect] = []
//    init(){
//        if UserDefaults.standard.bool(forKey: "defaultsSet") == false {
//            UserDefaults.standard.set(2.0, forKey: "rows")
//            UserDefaults.standard.set(2.0, forKey: "columns")
//            UserDefaults.standard.set(true, forKey: "defaultsSet")
//        }
//        self.rows = UserDefaults.standard.double(forKey: "rows")
//        self.columns = UserDefaults.standard.double(forKey: "columns")
//
//        self.rects = createRects()
//    }
//
//    func createRects() -> [NSRect] {
//        var rects: [NSRect] = []
//        let minWidth =  NSScreen.main!.frame.width / CGFloat(columns)
//        let minHeight =  NSScreen.main!.frame.height / CGFloat(rows)
//        for row in 0..<Int(rows) {
//            for col in 0..<Int(columns) {
//                let rect = NSRect(
//                    origin: NSPoint(
//                        x:  Int(minWidth) * row,
//                        y:  Int(minHeight) * col
//                    ),
//                    size: NSSize(
//                        width: Int(minWidth),
//                        height: Int(minHeight)
//                    )
//                )
//                rects.append(rect)
//            }
//        }
//        return rects
//    }
//}

struct GridView: View {
    @State var rects: [NSRect]
    
    
    var body: some View {
        Path {
            path in
            for rect in rects {
                path.addRect(rect.insetBy(dx: 10, dy: 10))
            }
        }
    }
}


func createRects(rows: Double, columns: Double) -> [NSRect] {
    var rects: [NSRect] = []
    let minWidth =  NSScreen.main!.frame.width / CGFloat(columns)
    let minHeight =  NSScreen.main!.frame.height / CGFloat(rows)
    for row in 0..<Int(rows) {
        for col in 0..<Int(columns) {
            let rect = NSRect(
                origin: NSPoint(
                    x:  Int(minWidth) * row,
                    y:  Int(minHeight) * col
                ),
                size: NSSize(
                    width: Int(minWidth),
                    height: Int(minHeight)
                )
            )
            rects.append(rect)
        }
    }
    return rects
}


class GridManager: ObservableObject {
    //    var gridManagerData = GridManagerData()
    var window: NSWindow
    var gridView: GridView
    @Published var columns = 2.0 {
        didSet {
            UserDefaults.standard.set(self.columns, forKey: "columns")
            gridView.rects = createRects(rows: self.rows, columns: self.columns)
        }
    }
    @Published var rows = 2.0  {
        didSet {
            self.rows = self.rows.clamp(to: 1...10)
            UserDefaults.standard.set(self.rows, forKey: "rows")
            gridView.rects = createRects(rows: self.rows, columns: self.columns)
        }
    }
    @Published var isShown = false {
        didSet {
            window.setIsVisible(self.isShown)
        }
    }
    @Published var point =  NSPoint(x: 0, y: 0)
    @Published var rects: [NSRect] = []
    
    @Published var accentColour =
    Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2) {
        didSet {
            window.backgroundColor = NSColor(self.accentColour)
            UserDefaults.standard.setColor(self.accentColour, forKey: "accentColour")
        }
    }
    
    init() {
        if UserDefaults.standard.bool(forKey: "defaultsSet") == false {
            UserDefaults.standard.set(2.0, forKey: "rows")
            UserDefaults.standard.set(2.0, forKey: "columns")
            
            let defaultAccentColour = Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2)
            UserDefaults.standard.setColor(defaultAccentColour, forKey: "accentColour")
            UserDefaults.standard.set(true, forKey: "defaultsSet")
        }
        
        self.rows = UserDefaults.standard.double(forKey: "rows")
        self.columns = UserDefaults.standard.double(forKey: "columns")
        self.accentColour =  UserDefaults.standard.color(forKey: "accentColour")
        
        window = NSWindow(
            contentRect: NSScreen.main!.frame,
            styleMask: [.fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 0.2)
        //        gridView = GridView(gridManagerData: self.gridManagerData
        gridView = GridView(rects: [])
        gridView.rects = createRects(rows: self.rows, columns: self.columns)
        
        window.contentView = NSHostingView(rootView: gridView)
        window.collectionBehavior = .canJoinAllSpaces // allow window to be shown on all virtual desktops (spaces)
        window.setIsVisible(self.isShown)
        
    }
}
