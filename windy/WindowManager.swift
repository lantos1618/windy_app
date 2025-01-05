import Foundation
import SwiftUI
import Combine

class WindowManager: ObservableObject {
    private var windows: [String: NSWindow] = [:]
    private var appState: AppState
    private var isShownListener: AnyCancellable?
    private var accentColorListener: AnyCancellable?
    private var activeScreenListener: AnyCancellable?
    
    init(appState: AppState) {
        self.appState = appState
        setupScreens()
        setupListeners()
    }
    
    func move(window: WindyWindow, direction: Direction) throws {
        do {
            debugPrint("moving: ", direction)
            let screen = try window.getScreen()
            var point = try window.getTopLeftPoint()
            let screenFrame = screen.getQuartsSafeFrame()
            
            let settings = appState.displaySettings[screen.getIdString()] ?? NSPoint(x: 2.0, y: 2.0)
            let columns = settings.x
            let rows = settings.y
            let minWidth = round(screenFrame.width / columns)
            let minHeight = round(screenFrame.height / rows)
            
            switch direction {
            case .Left:
                point.x -= minWidth
            case .Right:
                point.x += minWidth
            case .Up:
                point.y -= minHeight
            case .Down:
                point.y += minHeight
            }
            
            // Update window position
            try window.setTopLeftPoint(point: point)
            
            // Show preview if needed
            if !appState.isShown {
                appState.isShown = true
                if let timeout = appState.isShownTimeout {
                    timeout.invalidate()
                }
                appState.isShownTimeout = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                    self?.appState.isShown = false
                }
            }
        } catch {
            debugPrint("Error moving window: ", error)
        }
    }
    
    private func setupScreens() {
        for screen in NSScreen.screens {
            let screenId = screen.getIdString()
            windows[screenId] = createWindow(for: screen)
        }
    }
    
    private func createWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: NSScreen.main!.frame,
            styleMask: [.fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = NSColor(appState.accentColour)
        window.collectionBehavior = .canJoinAllSpaces
        window.level = .floating
        
        return window
    }
    
    private func setupListeners() {
        accentColorListener = appState.$accentColour.sink { [weak self] accentColor in
            self?.updateWindowColors(to: accentColor)
        }
        
        isShownListener = appState.$isShown.sink { [weak self] isShown in
            self?.updateWindowVisibility(to: isShown)
        }
        
        activeScreenListener = appState.$activeSettingScreen.sink { [weak self] _ in
            self?.updateWindowFrames()
        }
    }
    
    private func updateWindowColors(to color: Color) {
        windows.values.forEach { window in
            window.backgroundColor = NSColor(color)
        }
    }
    
    private func updateWindowVisibility(to isShown: Bool) {
        windows.forEach { screenId, window in
            let screen = NSScreen.fromIdString(str: screenId) ?? NSScreen.main!
            window.setIsVisible(isShown)
            window.setFrame(screen.frame, display: true)
        }
    }
    
    private func updateWindowFrames() {
        windows.forEach { screenId, window in
            let screen = NSScreen.fromIdString(str: screenId) ?? NSScreen.main!
            window.setFrame(screen.frame, display: true)
        }
    }
} 
