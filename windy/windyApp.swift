//
//  windyApp.swift
//  windy
//    global hotkeys
// https://stack-overflow.com/questions/28281653/how-to-listen-to-global-hotkeys-with-swift-in-a-macOS-app/40509620#40509620
// https://stack-overflow.com/questions/50990430/moving-windows-programmatically-on-macOS-in-swift
//  Created by Lyndon Leong on 30/12/2022.
//  windy is a window manager that moves windows based on snap locations
//  hotKeys;
//    crtl + option + lArrow = move to left
//    crtl + option + lArrow + rArrow = expand
//  same for left + right, up + down
//  behavior
//  if tap crtl + option + double tap lArrow = expand
//  if window collides on screen wall it cycles 1(max screen), 0.5, 0.33, 0.25
//  if double tap (ctrl + option) == auto tile so that, columns are auto fit

// change to windows behaviour?
// up collapsed = fullscreen
// left/right arrow = half, small, move to next column + resized, repeat.




//
//
// TODO
// [x] get current window
// [x] global hot key
// [x] mouse click and drag
// [x] debug/test nsScreen.main.Frame
// [x] Make collision system
// [x] Get current window in Screen
//  - [x] make window have screen offset
// [x] Make wrap around behaviour
// [x] unwrap all ! add try/catch conditions
// [x] icon, dark & light modes
// [x] check next screen if is available
// [x] re do move mechanic
// [x] create a safeSetFrame()
// [x] add check to on drag snap to see if window is still available if not hide snap


// // How determine if window is being dragged
// //
// var initialWindow
// if leftMouseDown:
//  initialWindow = getWindow
// if mouseMove:
//  if initialWindow.origin != getWindow.origin:
//    // window resizing
// if leftMouseUp:
//  if initialWindow.origin != getWindow.origin:
//    // window resizingDone

//import Cocoa
//import AppKit
//import Foundation
//import ApplicationServices
//import Accessibility
import SwiftUI
import OSLog

// SwiftUI Main Window
// we have disabled it
//
//class LoggerManager {
//    static let shared = LoggerManager()
//    
//    let logger: Logger
//
//    private init() {
//        self.logger = Logger(subsystem: "dev.zug.windy", category: "Windy")
//    }
//
//}

@main
struct windyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class ResizingPopover: NSPopover {
    override var contentViewController: NSViewController? {
        didSet {
            guard let contentViewController = contentViewController else { return }
            let newSize = contentViewController.view.fittingSize
            self.contentSize = newSize
        }
    }
}

// Application Logic
class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    private var statusItem: NSStatusItem!
    private var statusBarButton: NSStatusBarButton!
    private var popover: ResizingPopover!
    
    // MARK: - State Management
    private let appState = AppState()
    private var windyManager: WindyManager!
    private var privilegeManager: PrivilegeManager!
    
    // MARK: - Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusBar()
        setupPopover()
        setupManagers()
        registerEvents()
        
        // Close any existing windows
        NSApp.windows.forEach { $0.close() }
    }
    
    // MARK: - Setup Methods
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarButton = statusItem.button!
        
        if let image = NSImage(named: "MenuBarIcon") {
            image.isTemplate = true
            statusBarButton.image = image
        }
        
        statusBarButton.action = #selector(togglePopover)
        statusBarButton.target = self
    }
    
    private func setupPopover() {
        popover = ResizingPopover()
        popover.behavior = .transient
        
        popover.contentViewController = NSHostingController(
            rootView: MenuPopover(appState: appState)
        )
        
        NotificationCenter.default.addObserver(
            forName: NSPopover.willCloseNotification,
            object: popover,
            queue: OperationQueue.main
        ) { [weak self] _ in
            self?.appState.isShown = false
        }
    }
    
    private func setupManagers() {
        privilegeManager = PrivilegeManager()
        windyManager = WindyManager(appState: appState)
    }
    
    private func registerEvents() {
        privilegeManager.requestPrivileges()
        windyManager.registerGlobalEvents()
    }
    
    // MARK: - Actions
    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
    
    private func closePopover() {
        popover.close()
    }
}
