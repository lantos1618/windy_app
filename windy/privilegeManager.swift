//
//  checkPrivilege.swift
//  windy
//
//  Created by Lyndon Leong on 09/01/2023.
//

//import Foundation
import SwiftUI

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
            HStack {
                Button("Open Accessibility Permissions") {
//                    let accessibilityURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
//                    NSWorkspace.shared.open(URL(string: accessibilityURL)!)
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
            print("permission granted!")
            timer?.invalidate()
            self.accessWindow.close()
            self.closeCallBack()
            return true
        }
        return false
    }
}

class PrivilegeManager {
    func checkPrivilege(prompt: Bool) -> Bool {
        let options     = NSDictionary(
            object: prompt ? kCFBooleanTrue! : kCFBooleanFalse!, forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString) as CFDictionary
         let trusted    = AXIsProcessTrustedWithOptions(options)
        
        if (trusted) {
            print("Trusted!")
            return true
        } else {
            print("Not trusted")
            return false
        }
    }

}
