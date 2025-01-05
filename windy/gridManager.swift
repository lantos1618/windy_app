//
//  gridManager.swift
//  windy
//
//  Created by Lyndon Leong on 26/01/2023.
//

import Foundation
import SwiftUI
import Combine
import KeyboardShortcuts



struct ScreensManager {
    
}

struct GridView: View {
    // this needs to be redrawn every time
    // activeDisplayWindow is Changed
    // display rows/cols are updated
    @ObservedObject var windyData: WindyData;
    var screen: NSScreen
    
    var body: some View {
        let rects       = windyData.rectsDict[screen.getIdString()] ?? []
        
        let path        = Path {
//            path in
//            var rects = [NSRect]()
//
//            for screen in NSScreen.screens {
//                var frame = screen.getQuartsSafeFrame()
//
//                frame.origin.x = frame.origin.x / 3
//                frame.origin.y = frame.origin.y / 3
//                frame.size.width = frame.size.width / 3
//                frame.size.height  = frame.size.height / 3
//                rects.append(frame)
//            }
//            for rect in rects {
//                path.addRect(rect)
//            }
        
        
            path in

            for col in 0..<rects.count {
                for row in 0..<rects[col].count {
                    path.addRect(rects[col][row].insetBy(dx: 5, dy: 5))
                }
            }
        }
        ZStack {
            path.fill(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.8))
            path.strokedPath(StrokeStyle(lineWidth: 1.0))
        }
    }
}


// this should be split into its own data class
class GridManager: ObservableObject {
    private var appState: AppState
    private var windowManager: WindowManager
    
    init(appState: AppState) {
        self.appState = appState
        self.windowManager = WindowManager(appState: appState)
    }
    
    func registerEvents() {
        // Register keyboard shortcuts
        KeyboardShortcuts.onKeyDown(for: .moveWindowLeft) { [weak self] in
            self?.handleWindowMove(direction: .Left)
        }
        
        KeyboardShortcuts.onKeyDown(for: .moveWindowRight) { [weak self] in
            self?.handleWindowMove(direction: .Right)
        }
        
        KeyboardShortcuts.onKeyDown(for: .moveWindowUp) { [weak self] in
            self?.handleWindowMove(direction: .Up)
        }
        
        KeyboardShortcuts.onKeyDown(for: .moveWindowDown) { [weak self] in
            self?.handleWindowMove(direction: .Down)
        }
    }
    
    private func handleWindowMove(direction: Direction) {
        do {
            let window = try WindyWindow.currentWindow()
            try windowManager.move(window: window, direction: direction)
        } catch {
            debugPrint("Error handling window move: ", error)
        }
    }
}
