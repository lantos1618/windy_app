//
//  windyData.swift
//  windy
//
//  Created by Lyndon Leong on 27/01/2023.
//

import Foundation
import SwiftUI


// this should be split into its own data class
class WindyData: ObservableObject {
    //    var gridManagerData = GridManagerData()
    
    @Published var columns = 2.0 {
        didSet {
            UserDefaults.standard.set(self.columns, forKey: "columns")
        }
    }
    @Published var rows = 2.0  {
        didSet {
            UserDefaults.standard.set(self.rows, forKey: "rows")
        }
    }
    @Published var isShown = false
    @Published var point =  NSPoint(x: 0, y: 0)
    @Published var rects: [NSRect] = []
    
    @Published var accentColour =
    Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2) {
        didSet {
            UserDefaults.standard.setColor(self.accentColour, forKey: "accentColour")
        }
    }
    
    init() {
        if UserDefaults.standard.bool(forKey: "defaultsSet") == false {
            UserDefaults.standard.set(2.0, forKey: "rows")
            UserDefaults.standard.set(2.0, forKey: "columns")
            
            let defaultAccentColour = Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2)
            UserDefaults.standard.setColor(defaultAccentColour, forKey: "accentColour")
            UserDefaults.standard.set(true, forKey: "defaultsSet")
        }
        
        self.rows = UserDefaults.standard.double(forKey: "rows")
        self.columns = UserDefaults.standard.double(forKey: "columns")
        self.accentColour =  UserDefaults.standard.color(forKey: "accentColour")
    }
}
