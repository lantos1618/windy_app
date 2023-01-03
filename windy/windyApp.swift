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


import Cocoa
import AppKit
import SwiftUI
import Foundation
import ApplicationServices
import Accessibility



struct ContentView: View {
    var body: some View {
        List {
            Button("Quit") {
                NSApplication.shared.terminate(self)
            }.padding()
        }
    }
}

@main
struct windyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            if false {}
        }
    }
}

enum Collision {
    case Left, Right, Top, Bottom, None
}

class WindyManager {
    var collumns = 4.0
    var rows = 3.0
    func currentWindow()  -> WindyWindow {
        // get the most frontMostApp
        let frontApp = NSWorkspace.shared.frontmostApplication!
        let windyWindow = WindyWindow(app: frontApp)!
        return windyWindow
    }
    func infoAllWindows() {
//       // get all available windows windows
//       let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
//
//       let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
//       let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]]
//
//       // check if PID is the same as the window PID
//       for windowInfo in windowInfoList! {
//           let windowPID = windowInfo[kCGWindowOwnerPID as String] as! UInt32
//           if windowPID == frontMostAppPID {
//               // do something with the window...
//               print(windowInfo)
//
//               let windowNumber =  windowInfo[kCGWindowNumber as String]
    }
    
    func checkCollision(window: WindyWindow ) -> [Collision] {
        // if pointX < 0 + some error
        // if pointY < 0 + some error
        // if pointX + width > screenWidth - some error
        // if pointY + height > screenHeight - some error
        // else just move

        let point = window.getPoint()
        let size = window.getSize()
        let screenSize = NSScreen.main
        var collisions: [Collision] = []
        
        if ( point.x < 0 + (screenSize?.frame.maxX)! * 0.10 ) {
            print("Colission! left")
            collisions.append(.Left)
        }
        if ( point.y < 0 + (screenSize?.frame.maxY)! * 0.10 ) {
            print("Colission! top")
            collisions.append(.Top)
        }
        if ( point.x + size.width > ( screenSize?.frame.width)! - ( screenSize?.frame.maxX)! * 0.10) {
            print("Colission! right")
            collisions.append(.Right)
        }
        if ( point.y + size.height > ( screenSize?.frame.height)! - ( screenSize?.frame.maxY)! * 0.10) {
            print("Colission! bottom")
            collisions.append(.Bottom)
        }
        return collisions
    }
    
    func calculateNextSizeX(window: WindyWindow) -> CGFloat {
        // we want to avoid having a state for each of the windows so we can make it go
        // big -> normal -> small -> big
        let screenSize = (NSScreen.main?.frame)!
        let minWidth = screenSize.maxX / collumns
        let currentWindowSize = window.getSize()
        if (currentWindowSize.width < minWidth) {
            return screenSize.maxX
        }
        return currentWindowSize.width - minWidth
    }
    
    func calculateNextSizeY(window: WindyWindow) -> CGFloat {
        // we want to avoid having a state for each of the windows so we can make it go
        // big -> normal -> small -> big
        let screenSize = (NSScreen.main?.frame)!
        let minHeight = screenSize.maxY / rows
        let currentWindowSize = window.getSize()
        if (currentWindowSize.height < minHeight) {
            return screenSize.maxY
        }
        return currentWindowSize.height - minHeight
    }
    
    func globalKeyEventHandler(with event: NSEvent) {

        if (event.modifierFlags.contains([.option, .control])) {
            // pos
            // size
            let window = currentWindow()
            var size = window.getSize()
            var point = window.getPoint()
            
       
            // if we collide then we want to cycle the sizes
            switch event.specialKey! {
            case .leftArrow:
                // if collide set the window to left most
                if (checkCollision(window: window).contains(.Left)) {
                    size.width = calculateNextSizeX(window: window)
                    point.x = 0
                } else {
                    point.x = point.x - size.width
                }
            case .rightArrow:
                // if collide set the window to right most
                if (checkCollision(window: window).contains(.Right)) {
                    size.width = calculateNextSizeX(window: window)
                    point.x = (NSScreen.main?.frame.maxX)! - size.width
                } else {
                    point.x = point.x + size.width

                }
            case .upArrow:
                // if collide set the window to up most
                if (checkCollision(window: window).contains(.Top)) {
                    size.width = calculateNextSizeY(window: window)
                    point.y = 0
                } else {
                    point.y = point.y - size.height
                }
            case .downArrow:
                // if collide set the window to bottom most
                if (checkCollision(window: window).contains(.Bottom)) {
                    size.height = calculateNextSizeY(window: window)
                    point.y = (NSScreen.main?.frame.maxY)! - size.height
                } else {
                    point.y = point.y + size.height
                }
            default:
                break
            }
            window.setSize(size: size)
            window.setPoint(point: point)
        }
    }
}

//@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    // the status button in the apple menu
    private var statusItem: NSStatusItem!
    private var statusBarButton: NSStatusBarButton!
    private var popover: NSPopover!
    private var windyManager = WindyManager()

    
    func checkPrivilege(prompt: Bool) -> Bool {
        let options = NSDictionary(
            object: prompt ? kCFBooleanTrue! : kCFBooleanFalse!, forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString) as CFDictionary
        // this needs sandbox turned off :/
         let trusted = AXIsProcessTrustedWithOptions(options)
        
        if (trusted) {
            print("Trusted!")
            // register windy window manager
            NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) { event in
                self.windyManager.globalKeyEventHandler(with: event)
            }
            return true
        } else {
            print("Not trusted")
            return false
        }
    }
    
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        
        // hide the main window on launch
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        statusBarButton = statusItem.button!
        statusBarButton.image = NSImage(imageLiteralResourceName : "StatusBarIcon")
        statusBarButton.image!.size = NSSize ( width: 18 , height: 18 )
        statusBarButton.action = #selector(togglePopover)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())

        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if (self.checkPrivilege(prompt: true)) {
                // we got permission
                timer.invalidate()
            }
        }
        

    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
}
