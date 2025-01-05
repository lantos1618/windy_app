//
//  snapWindow.swift
//  test
//
//  Created by Lyndon Leong on 22/01/2023.
// TODO FIX SNAP WINDOW NOT SHOWING

import Foundation
import Combine
import SwiftUI



struct SnapGridMessageView: View {
    var body: some View {
        VStack {
            Spacer() // Pushes content to the center vertically
            HStack {
                Text("Hold ESC")
                Image(systemName: "escape")
                Text("and release window cancel snapping")
            }
            .padding() // Adds some padding around the HStack
            .background() // Example background color
            .cornerRadius(10)
            Spacer() // Pushes content to the center vertically
        }
    }
}


class SnapWindowManager {
    var appState: AppState
    var snapWindow: NSWindow?
    var currentMovingWindow: WindyWindow?
    var initialWindyWindowPos = NSPoint(x: 0, y: 0)
    var windowIsMoving = false
    var shouldSnap = true
    var accentColorListener: AnyCancellable?
    
    init(appState: AppState) {
        self.appState = appState
        snapWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        let hostingView = NSHostingView(rootView: SnapGridMessageView().frame(maxWidth: .infinity, maxHeight: .infinity))
        hostingView.autoresizingMask = [.width, .height]
        snapWindow?.contentView = hostingView
        snapWindow?.backgroundColor = NSColor(appState.accentColour)
        snapWindow?.collectionBehavior = .canJoinAllSpaces
        snapWindow?.setIsVisible(false)
        
        setupListeners()
    }
    
    private func setupListeners() {
        accentColorListener = appState.$accentColour.sink { [weak self] color in
            self?.snapWindow?.backgroundColor = NSColor(color)
        }
    }
    
    func registerEvents() {
        // Add your event registration code here
    }
}
