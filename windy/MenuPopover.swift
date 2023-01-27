//
//  MenunPopover.swift
//  windy
//
//  Created by Lyndon Leong on 15/01/2023.
//

import SwiftUI

struct MenuPopover: View {
    @StateObject var gridManager: GridManager
    @State var window: NSWindow?



    var body: some View {
        VStack {
            Text("Windy window manager").padding()
            
 
            
            Grid {
                GridRow {
                    Text ("Columns \(Int(gridManager.columns))")
                    HStack {
                        Button {
                            gridManager.columns = (gridManager.columns - 1).clamp(to: 1...6)

                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        Button {
                            gridManager.columns = (gridManager.columns + 1).clamp(to: 1...6)

                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
                GridRow {
                    Text ("Rows \(Int(gridManager.rows))")
                    HStack {
                        Button {
                            gridManager.rows = (gridManager.rows - 1).clamp(to: 1...6)

                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        Button {
                            gridManager.rows = (gridManager.rows + 1).clamp(to: 1...6)
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
                ColorPicker("Accent colour:", selection: $gridManager.accentColour)

            }
            
            
            Button("Quit Windy") {
                NSApplication.shared.terminate(self)
            }.padding()
            //        }.padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        }.padding()
    }
}
