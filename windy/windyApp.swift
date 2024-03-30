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
        WindowGroup {
            // disabled here and in the AppDelegate
          // if false {}
        }
    }
}

class ResizingPopover: NSPopover {
    override var contentViewController: NSViewController? {
        didSet {
            guard let contentViewController = contentViewController else { return }
            // Compute the new size based on the content's size
            let newSize = contentViewController.view.fittingSize
            // Then apply this new size to the popover
            self.contentSize = newSize
        }
    }
}


// Application Logic
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    // the status button in the apple menu
    private var statusItem          : NSStatusItem!
    private var statusBarButton     : NSStatusBarButton!
    private var popover             : NSPopover!
    
    
    // windy data is here as I am using it like a state Store.
    // Any application data that is required across the application
    // should be stored here
    private var windyData           : WindyData!
    private var windyManager        : WindyManager!
    // I have put these here as they need to exist before the Application logic, If this becomes unusable I should move it to windyManager.
    
    private var privilegeManager    : PrivilegeManager!
//    private var licenseManager      : LicenseManager!
    

    func hideMainWindow() {
        // hide the main window on launch
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
    }
    
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        hideMainWindow()
       
        // this has to be here to init window...
        windyData           = WindyData()
        windyManager        = WindyManager(windyData: windyData)
        privilegeManager    = PrivilegeManager()
//        licenseManager      = LicenseManager(windyData: windyData)
        

        // put the windy icon in the mac toolbar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarButton             = statusItem.button!
        statusBarButton.image       = NSImage(imageLiteralResourceName : "StatusBarIcon")
        statusBarButton.image!.size = NSSize ( width: 32 , height: 32 )
        statusBarButton.action      = #selector(togglePopover)
        
//        licenseManager.startHeartbeat()


        // open the MenuPopover when user clicks the status bar icon
        popover = ResizingPopover()

//        popover                         = NSPopover()
//        popover.contentSize             = NSSize(width: 400, height: 1000)
//        popover.behavior                = NSPopover.Behavior.transient;
        
        popover.contentViewController   = NSHostingController(
            rootView: MenuPopover(
                windyData: self.windyData
//                openLicenseWindowFunc: licenseManager.displayLicenseForm
            )
        )
        // add listener to close the rectangle preview
        NotificationCenter.default.addObserver(forName: NSPopover.willCloseNotification, object: popover, queue: OperationQueue.main) {_ in
            self.windyData.isShown = false
        }

        // open a request permissions modal
        var accessRequestModalWindow    : NSWindow
        accessRequestModalWindow        = NSWindow(
            contentRect : NSRect(x: 0, y: 0, width: 400, height: 380),
            styleMask   : [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing     : .buffered,
            defer       : false
        )
        accessRequestModalWindow.contentView = NSHostingView(
            rootView: AccessRequestModal(
                accessWindow    : accessRequestModalWindow,
                closeCallBack   : self.windyManager.registerGlobalEvents
            )
        )
        accessRequestModalWindow.center()
        accessRequestModalWindow.isReleasedWhenClosed = false
        accessRequestModalWindow.makeKeyAndOrderFront(nil)
        


    }
    
    @objc func togglePopover() {
        guard let button = statusItem.button else {
            return
        }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // fixes popover bug not closing after focus lost
            NSApplication.shared.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
}
