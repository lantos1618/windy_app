//
//  MenunPopover.swift
//  windy
//
//  Created by Lyndon Leong on 15/01/2023.
//

import SwiftUI
//
//struct WindyScreen: Identifiable {
//    var id: ObjectIdentifier
//    var screen: NSScreen
//}

struct MenuPopover: View {
    @StateObject var windyData: WindyData
    @State var window: NSWindow?
//    @State var screens: [WindyScreen] {
//        get {
//            let tScreens = NSScreen.screens
//            let wScreens: [WindyScreen] = []
//            for screen in tScreens {
//                let wScreen = WindyScreen(id: screen.hash, screen: screen)
//            }
//            return wScreens
//        }
//
//    }
    @State var selectedScreenHash = 0
    var body: some View {
        VStack {
            Text("Windy window manager").padding()
            Picker("Select Moniter", selection: $selectedScreenHash) {
                ForEach(NSScreen.screens, id: \.hash) { screen in
                    Text("\(screen.localizedName) \(screen.hash)")
                }
            }
            Grid {
                GridRow {
                    Text ("Columns \(Int(windyData.columns))")
                    HStack {
                        Button {
                            windyData.columns = (windyData.columns - 1).clamp(to: 1...6)

                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        Button {
                            windyData.columns = (windyData.columns + 1).clamp(to: 1...6)

                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
                GridRow {
                    Text ("Rows \(Int(windyData.rows))")
                    HStack {
                        Button {
                            windyData.rows = (windyData.rows - 1).clamp(to: 1...6)

                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        Button {
                            windyData.rows = (windyData.rows + 1).clamp(to: 1...6)
                        } label: {
                            Image(systemName: "plus.circle")
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
