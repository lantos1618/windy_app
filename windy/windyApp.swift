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
//
//
// TODO
// [x] get current window
// [x] global hot key
// [ ] mouse click and drag
// [ ] debug/test nsscreen.main.Frame
// [x] Make collision system
// [ ] Get current window in Screen
//  - [ ] make window have screen offset
// [ ] Make wrap around behaviour
// [ ] unwrap all ! add try/catch conditions
// [x] icon, dark & light modes


// how determin if window is being dragged
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



struct MenuPopover: View {
    var body: some View {
        List {
            Button("Quit") {
                NSApplication.shared.terminate(self)
            }.padding()
        }
    }
}

// Application Logic
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    // the status button in the apple menu
    private var statusItem: NSStatusItem!
    private var statusBarButton: NSStatusBarButton!
    private var popover: NSPopover!
    private var windyManager = WindyManager()
    private var privilegeManager = PrivilegeManager()
    private var initialLeftClickWindowOrigin: CGRect?
    private var snapWindow: NSWindow?
//    private var initialWindow = WindyWindow
    
    func hideMainWindow() {
        // hide the main window on launch
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
    }
    

    
    func registerGlobalEvents() {
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) { event in
            self.windyManager.globalKeyEventHandler(with: event)
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseDown) {event in
            guard let window = self.windyManager.currentWindow() else {
                print("failed to get window")
                return
            }
            let point = window.getPoint()
            let size = window.getSize()
            let initialLeftClickWindowOrigin = CGRect(x: point.x, y: point.y, width: size.width, height:  size.height)
            self.initialLeftClickWindowOrigin = initialLeftClickWindowOrigin

        }
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseDragged) {event in
            guard self.initialLeftClickWindowOrigin != nil else {
                print("noInitialWindowSet")
                return
            }
            guard let window = self.windyManager.currentWindow() else {
                print("failed to get window")
                return
            }
            let point = window.getPoint()
            let size = window.getSize()
            let currentLeftClickWindowOrigin = CGRect(x: point.x, y: point.y, width: size.width, height:  size.height)

            
            if (self.initialLeftClickWindowOrigin != currentLeftClickWindowOrigin ) {
                print("windowMoved:", currentLeftClickWindowOrigin)
                let mousePos = event.locationInWindow
                let screen = window.getScreen()
                if (mousePos.x < screen.frame.width * 0.10) {
                    if self.snapWindow != nil {
                        if (self.snapWindow?.isVisible == false) {
                            self.snapWindow?.setIsVisible(true)
                        }
                    } else {
                        self.snapWindow = NSWindow(
                            contentRect: NSRect(x: 0, y: 0, width: screen.frame.width/2, height: screen.frame.height),
                            styleMask: [.fullSizeContentView],
                            backing: .buffered,
                            defer: false
                        )
//                        self.snapWindow?.titleVisibility = .hidden
//                        self.snapWindow?.toolbar?.isVisible = false
                        self.snapWindow?.backgroundColor = NSColor(calibratedRed: 0.3, green: 0.4, blue: 1, alpha: 0.2)
                        
                    }
                } else {
                    if self.snapWindow != nil {
                        if (self.snapWindow?.isVisible == true) {
                            self.snapWindow?.setIsVisible(false)
                        }
                    }
                }
            }
        }
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseUp) {
            event in
            guard self.initialLeftClickWindowOrigin != nil else {
                print("noInitialWindowSet")
                return
            }
            guard let window = self.windyManager.currentWindow() else {
                print("failed to get window")
                return
            }
            let point = window.getPoint()
            let size = window.getSize()
            let currentLeftClickWindowOrigin = CGRect(x: point.x, y: point.y, width: size.width, height:  size.height)

            if (self.initialLeftClickWindowOrigin != currentLeftClickWindowOrigin ) {
                let mousePos = event.locationInWindow
                let screen = window.getScreen()
                if (mousePos.x < screen.frame.width * 0.10) {
                    let rec = NSRect(x: 0, y: 0, width: screen.frame.width/2, height: screen.frame.height)
                    window.setSize(size: CGSize(
                        width: rec.width, height: rec.height
                    ))
                    window.setPoint(point: CGPoint(
                        x: rec.minX, y: rec.minY
                    ))
                    if self.snapWindow != nil {
                        if (self.snapWindow?.isVisible == true) {
                            self.snapWindow?.setIsVisible(false)
                        }
                    }
                }
            }
            
        }
    }
    
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        hideMainWindow()
        
        // put the windy icon in the mac toolbar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarButton = statusItem.button!
        statusBarButton.image = NSImage(imageLiteralResourceName : "StatusBarIcon")
        statusBarButton.image!.size = NSSize ( width: 32 , height: 32 )
        statusBarButton.action = #selector(togglePopover)
        
        // open the MenuPopover when user clicks the status bar icon
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuPopover())
        
        
        // open a request permissions
        var accessRequestModalWindow: NSWindow
        accessRequestModalWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 380),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        accessRequestModalWindow.contentView = NSHostingView(
            rootView: AccessRequestModal(
                accessWindow: accessRequestModalWindow,
                closeCallBack: registerGlobalEvents
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
