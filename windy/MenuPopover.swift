//
//  MenunPopover.swift
//  windy
//
//  Created by Lyndon Leong on 15/01/2023.
//

import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin



struct KeyboardShortcutsSettings: View {
    var body: some View {
        Form {
            Section(header: Text("Move Window in Screen")) {
                KeyboardShortcuts.Recorder("Move window left:",     name: .moveWindowLeft)
                KeyboardShortcuts.Recorder("Move window right:",    name: .moveWindowRight)
                KeyboardShortcuts.Recorder("Move window up:",       name: .moveWindowUp)
                KeyboardShortcuts.Recorder("Move window down:",     name: .moveWindowDown)
            }
            Section(header: Text("Move Window to Screen")) {
                KeyboardShortcuts.Recorder("Move window to left screen:",     name: .moveWindowScreenLeft)
                KeyboardShortcuts.Recorder("Move window to right screen:",    name: .moveWindowScreenRight)
                KeyboardShortcuts.Recorder("Move window to up screen:",       name: .moveWindowScreenUp)
                KeyboardShortcuts.Recorder("Move window down screen:",        name: .moveWindowScreenDown)
            }
        }
    }
}



struct MenuPopover: View {
    @StateObject var windyData              : WindyData
    @State var window                       : NSWindow?
    @State private var isPresentingConfirm  : Bool = false
    
    var body: some View {
        VStack {
            Text("Windy window manager").font(.title).padding()
            
            if (windyData.displaySettings.keys.contains(windyData.activeSettingScreen)) {
                screenPickerSection
            }
            
            Text("Keyboard Shortcuts").font(.title2).padding()
            KeyboardShortcutsSettings()
            Text("Reset settings").font(.title2).padding()
            
            VStack {
                Button("Reset all display Settings") {
                    isPresentingConfirm = true
                }.confirmationDialog("Are you sure you want to reset all displaySettings", isPresented: $isPresentingConfirm) {
                    Button("rest all display settings", role: .destructive) {
                        windyData.restSettings()
                    }
                }
                Button("Reset Keyboard shortcuts") {
                    isPresentingConfirm = true
                }.confirmationDialog("Are you sure you want to reset all displaySettings", isPresented: $isPresentingConfirm) {
                    Button("rest keyboard shortcuts", role: .destructive, action: resetKeyboardShortcuts)
                }
                LaunchAtLogin.Toggle()
                Button("Quit Windy") {
                    NSApplication.shared.terminate(self)
                }.padding()
            }.padding()
        }.padding()
    }
    
    func resetKeyboardShortcuts() {
        KeyboardShortcuts.reset([
            .moveWindowLeft,
            .moveWindowRight,
            .moveWindowUp,
            .moveWindowDown,
            .moveWindowScreenLeft,
            .moveWindowScreenRight,
            .moveWindowScreenUp,
            .moveWindowScreenDown,
        ])
    }

    private var activeDisplaySetting: NSPoint {
        windyData.displaySettings[windyData.activeSettingScreen] ?? NSPoint(x: 2.0, y: 2.0)
    }

    private func updateActiveDisplaySetting(_ update: (inout NSPoint) -> Void) {
        guard !windyData.activeSettingScreen.isEmpty else {
            return
        }

        var setting = activeDisplaySetting
        update(&setting)
        windyData.displaySettings[windyData.activeSettingScreen] = setting
    }

    var screenPickerSection: some View {
        VStack {
            Text("Screen Settings").font(.title2).padding()
            Grid {
                screenPickerRow
                columnPickerRow
                rowPickerRow
                layoutPreviewRow
                accentColorRow
            }
        }
    }
    
    var screenPickerRow: some View {
        GridRow {
            Text ("Screen:").gridColumnAlignment(.trailing) // Align the entire first column.
            Picker("", selection: $windyData.activeSettingScreen) {
                ForEach(windyData.displaySettings.keys.sorted(), id: \.self) {
                    key in
                    let screenName = NSScreen.fromIdString(str: key)?.localizedName ?? key
                    Text(screenName + (windyData.activeScreens.contains(key) ? " (currently connected)" : "")).tag(key)
                }
            }.gridCellColumns(2)
        }
    }
    
    var columnPickerRow: some View {
        GridRow {
            Text ("Columns:").gridColumnAlignment(.trailing) // Align the entire first column.
            Text ("\(Int(activeDisplaySetting.x))")
            HStack {
                Button {
                    updateActiveDisplaySetting { setting in
                        setting.x = (setting.x - 1).clamp(to: 1...6)
                    }
                } label: {
                    Image(systemName: "minus.circle")
                }
                Button {
                    updateActiveDisplaySetting { setting in
                        setting.x = (setting.x + 1).clamp(to: 1...6)
                    }
                    
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
    }
    var rowPickerRow: some View {
        GridRow {
            Text ("Rows:")
            Text(" \(Int(activeDisplaySetting.y))")
            HStack {
                Button {
                    updateActiveDisplaySetting { setting in
                        setting.y = (setting.y - 1).clamp(to: 1...6)
                    }
                } label: {
                    Image(systemName: "minus.circle")
                }
                Button {
                    updateActiveDisplaySetting { setting in
                        setting.y = (setting.y + 1).clamp(to: 1...6)
                    }
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
    }
    var layoutPreviewRow: some View {
        GridRow {
            Text("Preview Layout")
            Spacer()
                    Button {
                        windyData.isShown = !windyData.isShown
                    } label: {
                        windyData.isShown ? Image(systemName: "eye.fill") : Image(systemName: "eye")
                    }
            
        }
        
    }
    var accentColorRow: some View {
        GridRow {
            Text("Accent colour:")
            Spacer()
            ColorPicker("", selection: $windyData.accentColour)
        }
    }
}
