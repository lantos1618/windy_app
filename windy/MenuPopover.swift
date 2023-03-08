//
//  MenunPopover.swift
//  windy
//
//  Created by Lyndon Leong on 15/01/2023.
//

import SwiftUI

struct MenuPopover: View {
    @StateObject var windyData      : WindyData
    @State var window               : NSWindow?
    
    var body: some View {
        VStack {
            Text("Windy window manager").font(.title).padding()
            
            if (windyData.displaySettings.keys.contains(windyData.activeSettingScreen)) {
                Text("Grid Settings").font(.title2).padding()

                Grid {
                    GridRow {
                        Text ("Screen:").gridColumnAlignment(.trailing) // Align the entire first column.
                        Picker("", selection: $windyData.activeSettingScreen) {
                            ForEach(windyData.displaySettings.keys.sorted(), id: \.self) {
                                key in
                                Text(key).tag(key)
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
                        Text("")
                        HStack {
                            Button {
                                windyData.isShown = !windyData.isShown
                            } label: {
                                windyData.isShown ? Image(systemName: "eye.fill") : Image(systemName: "eye")
                            }
                        }
                    }
                    
                    GridRow {
                        Text("Accent colour:")
                        Text("")
                        HStack{
                            ColorPicker("", selection: $windyData.accentColour)
                        }
                    }
                  
                }
            }
            
            Text("Hot Key Settings").font(.title2).padding()
            Grid {
                GridRow {
                    Text("Move Window Left :").gridColumnAlignment(.leading) // Align the entire first column.
                    Button("CTRL+OPTION+←") {
                    }.gridColumnAlignment(.trailing) // Align the entire first column.
                }
                GridRow {
                    Text("Move Window Right:")
                    Button("CTRL+OPTION+→") {
                    }
                }
                GridRow {
                    Text("Move Window Up:")
                    Button("CTRL+OPTION+↑") {
                    }
                }
                GridRow {
                    Text("Move Window Down:")
                    Button("CTRL+OPTION+↑") {
                    }
                }
            }.padding()
            
            
            Button("Quit Windy") {
                NSApplication.shared.terminate(self)
            }.padding()
        }.padding()
    }
}
