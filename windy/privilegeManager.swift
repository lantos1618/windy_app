//
//  checkPrivilege.swift
//  windy
//
//  Created by Lyndon Leong on 09/01/2023.
//

import Foundation
import AppKit
import SwiftUI
import LaunchAtLogin

struct AccessRequestModal: View {
    var accessWindow        : NSWindow
    var closeCallBack       : () -> ()
    var privilegeManager    = PrivilegeManager()

    @State var accessTimer  : Timer?
    @State var firstClick   = true

    var body: some View {
        VStack {
            Text("Windy Requires Accessibility permissions for the following functionality").padding()
            List {
                Text("\u{2022} Move and resize windows")
                Text("\u{2022} Use Global HotKeys")
            }.padding()
            
            LaunchAtLogin.Toggle()
            HStack {
                Button("Open Accessibility Permissions") {
                    _ = self.checkPrivilegeHandle(timer: nil, prompt: true)
                }
                Button("Quit") {
                    NSApplication.shared.terminate(self)
                }
            }.padding()
        }.padding().onAppear() {
            if (checkPrivilegeHandle(timer: nil, prompt: false) != true) {
                let accessibilityURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                NSWorkspace.shared.open(URL(string: accessibilityURL)!)
                self.accessTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                    _ = checkPrivilegeHandle(timer: timer, prompt: false)
                 }
            }
        }
        
    }
    func checkPrivilegeHandle(timer: Timer?, prompt: Bool) -> Bool {
        if (self.privilegeManager.checkPrivilege(prompt: prompt)) {
            // we got permission
            // start the windy Manager key event Listener
            debugPrint("permission granted!")
            timer?.invalidate()
            self.accessWindow.close()
            self.closeCallBack()
            return true
        }
        return false
    }
}

class PrivilegeManager {
    private var accessRequestModalWindow: NSWindow?
    
    init() {
        setupAccessRequestWindow()
    }
    
    private func setupAccessRequestWindow() {
        accessRequestModalWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 380),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        accessRequestModalWindow?.isReleasedWhenClosed = false
    }
    
    func requestPrivileges() {
        guard let window = accessRequestModalWindow else { return }
        
        window.contentView = NSHostingView(
            rootView: AccessRequestModal(
                accessWindow: window,
                closeCallBack: { [weak self] in
                    self?.accessRequestModalWindow?.close()
                }
            )
        )
        
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    func checkPrivilege(prompt: Bool) -> Bool {
        let options     = NSDictionary(
            object: prompt ? kCFBooleanTrue! : kCFBooleanFalse!, forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString) as CFDictionary
         let trusted    = AXIsProcessTrustedWithOptions(options)
        
        if (trusted) {
            debugPrint("Trusted!")
            return true
        } else {
            debugPrint("Not trusted")
            return false
        }
    }

}
