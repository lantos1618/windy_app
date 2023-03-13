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
    @StateObject var windyData      : WindyData
    @State var window               : NSWindow?
    @State private var isPresentingConfirm: Bool = false

    var body: some View {
        VStack {
            Text("Windy window manager").font(.title).padding()
            
            if (windyData.displaySettings.keys.contains(windyData.activeSettingScreen)) {
                Text("Screen Settings").font(.title2).padding()

                Grid {
                    GridRow {
                        Text ("Screen:").gridColumnAlignment(.trailing) // Align the entire first column.
                        Picker("", selection: $windyData.activeSettingScreen) {
                            ForEach(windyData.displaySettings.keys.sorted(), id: \.self) {
                                key in
                                Text(key + (windyData.activeScreens.contains(key) ? " (currently connected)" : "")).tag(key)
                            }
                        }.gridCellColumns(2)
                    }
                    GridRow {
                        Text ("Columns:").gridColumnAlignment(.trailing) // Align the entire first column.
                        Text ("\(Int(windyData.displaySettings[windyData.activeSettingScreen]!.x))")
                        HStack {
                            Button {
                                windyData.displaySettings[windyData.activeSettingScreen]!.x = (windyData.displaySettings[windyData.activeSettingScreen]!.x - 1).clamp(to: 1...6)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            Button {
                                windyData.displaySettings[windyData.activeSettingScreen]!.x = (windyData.displaySettings[windyData.activeSettingScreen]!.x + 1).clamp(to: 1...6)
                                
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                        }
                    }
                    GridRow {
                        Text ("Rows:")
                        Text(" \(Int(windyData.displaySettings[windyData.activeSettingScreen]!.y))")
                        HStack {
                            Button {
                                windyData.displaySettings[windyData.activeSettingScreen]!.y = (windyData.displaySettings[windyData.activeSettingScreen]!.y - 1).clamp(to: 1...6)
                                
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            Button {
                                windyData.displaySettings[windyData.activeSettingScreen]!.y = (windyData.displaySettings[windyData.activeSettingScreen]!.y + 1).clamp(to: 1...6)
                                
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                        }
                    }
                    GridRow {
                        Text("Preview Layout")
                        Spacer()
                                Button {
                                    windyData.isShown = !windyData.isShown
                                } label: {
                                    windyData.isShown ? Image(systemName: "eye.fill") : Image(systemName: "eye")
                                }
                        
                    }
                    
                    GridRow {
                        Text("Accent colour:")
                        Spacer()
                        ColorPicker("", selection: $windyData.accentColour)
                    }
                    
                    
                  
                }
            }
            
            Text("Keyboard Shortcuts").font(.title2).padding()
            KeyboardShortcutsSettings()
            Text("Reset settings").font(.title2).padding()
            HStack {
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
                    Button("rest keyboard shortcuts", role: .destructive) {
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
                }
            }
            LaunchAtLogin.Toggle()
            Button("Quit Windy") {
                NSApplication.shared.terminate(self)
            }.padding()
        }.padding()
    }
}
