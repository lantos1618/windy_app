//
//  MenunPopover.swift
//  windy
//
//  Created by Lyndon Leong on 15/01/2023.
//

import SwiftUI



struct MenuPopover: View {
    @AppStorage("windowColumns") var windowColumns = 2.0
    @AppStorage("windowRows") var windowRows = 2.0
    
    var body: some View {
        VStack {
            Text("Windy window manager")
            
            Text ("Columns \(Int(windowColumns))")
            Slider(value: $windowColumns, in: 2...10) {
                Text("Columns")
            } minimumValueLabel: {
                Text("2")
            } maximumValueLabel: {
                Text("10")
            }.padding()
            
            Text ("Rows \(Int(windowRows))")
            Slider(value: $windowRows, in: 2...10) {
                Text("Columns")
            } minimumValueLabel: {
                Text("2")
            } maximumValueLabel: {
                Text("10")
            }.padding()
            
            Button("Close windy") {
                NSApplication.shared.terminate(self)
            }.padding()
            
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
            }
        }.padding()
    }
}
