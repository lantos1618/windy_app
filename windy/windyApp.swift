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


class WindyManager {
    
    
    func currentWindow()  -> WindyWindow {
        // get the most frontMostApp
        let frontApp = NSWorkspace.shared.frontmostApplication!
        var windyWindow = WindyWindow(app: frontApp)!
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
    func globalKeyEventHandler(with event: NSEvent) {
        print("KeyDown:",event.characters!, " SpecialKey:", event.specialKey, " modifiers:", event.modifierFlags.intersection(.deviceIndependentFlagsMask))
        if (event.modifierFlags.contains([.option, .control]) != true) {
            
            return
        }
        if (event.specialKey == .leftArrow) {
            var window = currentWindow()
            var size = window.getSize()
            size.width = size.width / 2
            window.setSize(size: size)
        }
        if (event.specialKey == .rightArrow) {
            var window = currentWindow()
            var size = window.getSize()
            size.width = size.width * 2
            window.setSize(size: size)
        }
        if (event.specialKey == .upArrow) {
            var window = currentWindow()
            var size = window.getSize()
            size.height = size.height / 2
            window.setSize(size: size)
        }
        if (event.specialKey == .downArrow) {
            var window = currentWindow()
            var size = window.getSize()
            size.height = size.height * 2
            window.setSize(size: size)
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
