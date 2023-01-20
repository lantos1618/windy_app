//
//  MenunPopover.swift
//  windy
//
//  Created by Lyndon Leong on 15/01/2023.
//

import SwiftUI

struct GridPreviewShape: Shape {
    var rows: Int
    var columns: Int
    var spacing: Int
    var screen: NSScreen
   func path(in rect: CGRect) -> Path {
       
        var path = Path()
        let minWidth = screen.frame.width / CGFloat(rows) - CGFloat(spacing)
        let minHeight = screen.frame.height / CGFloat(columns) - CGFloat(spacing)


        for row in 0...rows {
            for column in 0...columns {
                let x = CGFloat(row) * (minWidth + CGFloat(spacing))
                let y = CGFloat(column) * (minHeight + CGFloat(spacing))
                
                let rect = CGRect(
                    x: x, y: y, width: minWidth, height: minHeight
                )
//                path.fill()
                path.addRect(rect)
      
            }
        }
       return path
    }
}

struct GridPreview: View {
    var rows: Int
    var columns: Int
    var spacing: Int
    var screen: NSScreen
    var body: some View {
        GridPreviewShape(
            rows: rows,
            columns: columns,
            spacing: 10,
            screen: NSScreen.main!
        )
    }
}


struct MenuPopover: View {
    @AppStorage("windowColumns") var windowColumns = 2.0
    @AppStorage("windowRows") var windowRows = 2.0
    @State var windowColumns1 = 2.0
    @State var window: NSWindow?
    
    
    var body: some View {
        VStack {
            Text("Windy window manager").padding()
            Text ("Columns \(Int(windowColumns1))")
            
            Slider(
                value: $windowColumns1,
                in: 2...10,
                onEditingChanged: {_ in
//                    if(window == nil){
//                        self.window = NSWindow(
//                            contentRect: NSScreen.main!.frame,
//                            styleMask: [.borderless, .fullSizeContentView],
//                            backing: .buffered, defer: false
//                        )
//                        self.window?.contentView = NSHostingView(
//                            rootView: GridPreview(
//                                rows: Int(windowRows),
//                                columns: Int(windowColumns1),
//                                spacing: 5,
//                                screen: NSScreen.main!)
//                        )
//                        self.window?.backgroundColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
//                        self.window?.setIsVisible(true)
//                        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
//                            if (self.window != nil) {
//                                self.window?.setIsVisible(false)
//                                window?.close()
//                                window = nil
//                            }
//                            timer.invalidate()
//                        }
//                    }
                },
                minimumValueLabel: Text("2"),
                maximumValueLabel: Text("10"),
                label: {Text("Columns")}
            ).padding()
           
            Text ("Columns \(Int(windowColumns))")
            Slider(value: $windowColumns, in: 2...10) {
                Text("Columns")
            } minimumValueLabel: {
                Text("2")
            } maximumValueLabel: {
                Text("10")
            }
            Text ("Rows \(Int(windowRows))")
            Slider(value: $windowRows, in: 2...10) {
                Text("Columns")
            } minimumValueLabel: {
                Text("2")
            } maximumValueLabel: {
                Text("10")
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
            
            
            Button("Close windy") {
                NSApplication.shared.terminate(self)
            }.padding()
            //        }.padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        }.padding()
    }
}
