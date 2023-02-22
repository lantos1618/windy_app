//
//  MenunPopover.swift
//  windy
//
//  Created by Lyndon Leong on 15/01/2023.
//

import SwiftUI


struct MenuPopover: View {
    @StateObject var windyData: WindyData
    @State var window: NSWindow?
    @State var selectedScreenHash = NSScreen.main!.getIdString()
    var body: some View {
        VStack {
            Text("Windy window manager").padding()
            Picker("Screen", selection: $selectedScreenHash) {
                ForEach(NSScreen.screens, id: \.hash) { screen in
                    Text("\(screen.hash):\(screen.localizedName)").tag(screen.getIdString())
                }
            }
            if (windyData.displaySettings.keys.contains(selectedScreenHash)) {
                Grid {
                    GridRow {
                        Text ("Rows \(Int(windyData.displaySettings[selectedScreenHash]!.x))")
                        HStack {
                            Button {
                                windyData.displaySettings[selectedScreenHash]!.x = (windyData.displaySettings[selectedScreenHash]!.x - 1).clamp(to: 1...6)
                                windyData.isShown = true
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            Button {
                                windyData.displaySettings[selectedScreenHash]!.x = (windyData.displaySettings[selectedScreenHash]!.x + 1).clamp(to: 1...6)
                                windyData.isShown = false

                            } label: {
                                Image(systemName: "plus.circle")
                            }
                        }
                        GridRow {
                            Text ("Columns \(Int(windyData.displaySettings[selectedScreenHash]!.y))")
                            HStack {
                                Button {
                                    windyData.displaySettings[selectedScreenHash]!.y = (windyData.displaySettings[selectedScreenHash]!.y - 1).clamp(to: 1...6)
                                    
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                Button {
                                    windyData.displaySettings[selectedScreenHash]!.y = (windyData.displaySettings[selectedScreenHash]!.y + 1).clamp(to: 1...6)
                                    
                                } label: {
                                    Image(systemName: "plus.circle")
                                }
                            }
                        }
                    }
                }
//
//                GridRow {
//                    Text("Move Window Left :").gridColumnAlignment(.leading) // Align the entire first column.
//                    Button("CTRL+OPTION+←") {
//                    }.gridColumnAlignment(.trailing) // Align the entire first column.
//                }
//                GridRow {
//                    Text("Move Window Right:")
//                    Button("CTRL+OPTION+→") {
//                    }
//                }
//                GridRow {
//                    Text("Move Window Up:")
//                    Button("CTRL+OPTION+↑") {
//                    }
//                }
//                GridRow {
//                    Text("Move Window Down:")
//                    Button("CTRL+OPTION+↑") {
//                    }
//                }
                ColorPicker("Accent colour:", selection: $windyData.accentColour)
            }
            
            
            Button("Quit Windy") {
                NSApplication.shared.terminate(self)
            }.padding()
        }.padding()
    }
}
