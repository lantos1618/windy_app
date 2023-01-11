//
//  checkPrivilege.swift
//  windy
//
//  Created by Lyndon Leong on 09/01/2023.
//

//import Foundation
import SwiftUI

struct AccessRequestModal: View {
    var accessWindow: NSWindow?
    var closeCallBack: () -> ()
    @State var accessTimer: Timer?
    @State var firstClick = true
    var body: some View {
        VStack {
            Text("Windy Requires Accesibilty permissions for the following functionality").padding()
            List {
                Text("\u{2022} Move and resize windows")
                Text("\u{2022} Use Global HotKeys")
            }.padding()
            HStack {
                Button("Open Accessability Permissions") {
                    let accessibilityURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                    NSWorkspace.shared.open(URL(string: accessibilityURL)!)
                    if (firstClick != true) {
                        // force a prompt
                        _ = self.checkPrivilege(prompt: true)
                    }
                    firstClick = false
                }
                Button("Quit") {
                    NSApplication.shared.terminate(self)
                }
            }.padding()
        }.padding().onAppear() {
            if (checkPrivilegeHandle(timer: nil) != true) {
                self.accessTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
                    _ = checkPrivilegeHandle(timer: timer)
                 }
            }
        }
        
    }
    func checkPrivilegeHandle(timer: Timer?) -> Bool {
        if (self.checkPrivilege(prompt: false)) {
            // we got permission
            // start the windy Manager key event Listener
            print("permission granted!")
            print("window", self.accessWindow as Any)
            timer?.invalidate()
            self.accessWindow?.close()
            self.closeCallBack()
            return true
        }
        return false
    }
    func checkPrivilege(prompt: Bool) -> Bool {
        let options = NSDictionary(
            object: prompt ? kCFBooleanTrue! : kCFBooleanFalse!, forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString) as CFDictionary
        // this needs sandbox turned off :/
         let trusted = AXIsProcessTrustedWithOptions(options)
        
        if (trusted) {
            print("Trusted!")
            return true
        } else {
            print("Not trusted")
            return false
        }
    }

}

class PrivilegeManager {
    func checkPrivilege(prompt: Bool) -> Bool {
        let options = NSDictionary(
            object: prompt ? kCFBooleanTrue! : kCFBooleanFalse!, forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString) as CFDictionary
        // this needs sandbox turned off :/
         let trusted = AXIsProcessTrustedWithOptions(options)
        
        if (trusted) {
            print("Trusted!")
            return true
        } else {
            print("Not trusted")
            return false
        }
    }

}
