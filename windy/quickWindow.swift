//
//  quickWindow.swift
//  windy
//
//  Created by Lyndon Leong on 10/04/2023.
//

import Foundation


// when a user holds the quick action
// the single click moves the window
// the double click resizes the window


class quickWindowManager {
    var windyData               : WindyData
    
    init(windyData: WindyData) {
        self.windyData = windyData
    }
    
    func globalLeftMouseDownHandler(event: NSEvent) {
        
//        do {
//            // get current window
//            _ = WindyWindow.currentWindow()
//            
//            
//        }
    }
    
    func registerEvents() {
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown,     handler: self.globalLeftMouseDownHandler)
    }
}
