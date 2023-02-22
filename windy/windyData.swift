//
//  windyData.swift
//  windy
//
//  Created by Lyndon Leong on 27/01/2023.
//

import Foundation
import SwiftUI


func createDefaultDisplaySettings() -> [String: NSPoint]{
    var result: [String: NSPoint] = [:]
    for screen in NSScreen.screens {
        result[screen.getIdString()] = NSPoint(x: 2.0, y: 2.0)
    }
    return result
}


class WindyData: ObservableObject {
    // could move this to its own struct and have its own toJson fromJson
    @Published var displaySettings: [String: NSPoint] = [:] {
        didSet {
//            print("changed:\(displaySettings)")
            do {
                try UserDefaults.standard.set(dict: displaySettings, forKey: "displaySettings")
            }
            catch {
                print("\(error)")
            }
            
            if !isShownTimeout {
                self.isShown = true
                isShownTimeout = true
                Timer.init(timeInterval: 1, repeats: false) { timer in
                    print("pong")
                    self.isShown = false
                    self.isShownTimeout = false
                    timer.invalidate()
                    
                }
            }
           
        }
    }
    @Published var isShown = false {
        didSet {
            print("isShown", isShown)
        }
    }
    var isShownTimeout = false
    @Published var rects: [[NSRect]] = []
    @Published var accentColour = Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2) {
        didSet {
            UserDefaults.standard.set(self.accentColour, forKey: "accentColour")
        }
    }
    
    init() {
        if UserDefaults.standard.bool(forKey: "defaultsSet") == false {
            do {
                try UserDefaults.standard.set(dict: createDefaultDisplaySettings(), forKey: "displaySettings")
            } catch {
                print("failed to set default displaySettings")
            }
            
            let defaultAccentColour = Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2)
            UserDefaults.standard.set(defaultAccentColour, forKey: "accentColour")
            UserDefaults.standard.set(true, forKey: "defaultsSet")
        }
        do {
            self.displaySettings = try UserDefaults.standard.getDictPoints(forKey: "displaySettings")
        } catch {
            print("failed to get the displaySettings")
        }
        self.accentColour =  UserDefaults.standard.color(forKey: "accentColour")
    }
    
}
