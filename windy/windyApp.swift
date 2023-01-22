//
//  windyApp.swift
//  windy
//    global hotkeys
// https://stackoverflow.com/questions/28281653/how-to-listen-to-global-hotkeys-with-swift-in-a-macos-app/40509620#40509620
// https://stackoverflow.com/questions/50990430/moving-windows-programmatically-on-macos-in-swift
//  Created by Lyndon Leong on 30/12/2022.
//  windy is a window manager that moves windows based on snap locations
//  hotKeys;
//    crtl + option + lArrow = move to left
//    crtl + option + lArrow + rArrow = expand
//  same for left + right, up + down
//  behaviour
//  if tap crtl + option + double tap lArrow = expand
//  if window collides on screen wall it cycles 1(max screen), 0.5, 0.33, 0.25
//  if double tap (ctrl + option) == auto tile so that, collumns are auto fit

// change to windows behaviour?
// up collapsed = fullscreen
// left/right arrow = half, small, move to next column + resized, repeat.




//
//
// TODO
// [x] get current window
// [x] global hot key
// [x] mouse click and drag
// [ ] debug/test nsscreen.main.Frame
// [x] Make collision system
// [x] Get current window in Screen
//  - [ ] make window have screen offset
// [x] Make wrap around behaviour
// [ ] unwrap all ! add try/catch conditions
// [x] icon, dark & light modes


// // How determin if window is being dragged
// //
// var initialWindow
// if leftMouseDown:
//  initialWindow = getWindow
// if mouseMove:
//  if initialWindow.origin != getWindow.origin:
//    // window resizing
// if leftMouseUp:
//  if intialWindow.origin != getWindow.orign:
//    // window resizingDone

//import Cocoa
//import AppKit
//import Foundation
//import ApplicationServices
//import Accessibility
import SwiftUI


// SwiftUI Main Window
// we have disabled it
@main
struct windyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            // disabled here and in the AppDelegate
            if false {}
        }
    }
}


// Application Logic
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    // the status button in the apple menu
    private var statusItem: NSStatusItem!
    private var statusBarButton: NSStatusBarButton!
    private var popover: NSPopover!
    
    private var windyManager: WindyManager!
    private var privilegeManager: PrivilegeManager!
 
    func hideMainWindow() {
        // hide the main window on launch
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
    }
    
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        hideMainWindow()
        windyManager = WindyManager()
        privilegeManager = PrivilegeManager()
        
        // put the windy icon in the mac toolbar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarButton = statusItem.button!
        statusBarButton.image = NSImage(imageLiteralResourceName : "StatusBarIcon")
        statusBarButton.image!.size = NSSize ( width: 32 , height: 32 )
        statusBarButton.action = #selector(togglePopover)
        
        // open the MenuPopover when user clicks the status bar icon
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 800)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuPopover())
        
        // open a request permissions modal
        var accessRequestModalWindow: NSWindow
        accessRequestModalWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 380),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        accessRequestModalWindow.contentView = NSHostingView(
            rootView: AccessRequestModal(
                accessWindow: accessRequestModalWindow,
                closeCallBack: self.windyManager.registerGlobalEvents
            )
        )
        accessRequestModalWindow.center()
        accessRequestModalWindow.makeKeyAndOrderFront(nil)

    }
    
    @objc func togglePopover() {
        guard let button = statusItem.button else {
            return
        }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
}
