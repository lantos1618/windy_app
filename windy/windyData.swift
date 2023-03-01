//
//  windyData.swift
//  windy
//
//  Created by Lyndon Leong on 27/01/2023.
//

import Foundation
import SwiftUI

func createDefaultSettings() -> [String: NSPoint] {
    var result: [String: NSPoint] = [:]
    for screen in NSScreen.screens {
        var screenName = screen.getIdString()
        if !result.keys.contains(screenName) {
            result[screenName] = NSPoint(x: 2.0, y: 2.0)
        }
    }
    return result
}

func setDisplaySettings(settings: [String: NSPoint] = [:]) {
    var result = createDefaultSettings()
    // create the settings dict create default settings for anything that isn't set
    for (key, val) in settings {
        result[key] = val
    }
    do {
        try UserDefaults.standard.set(dict: result, forKey: "displaySettings")
    } catch {
        print("failed to set default displaySettings")
    }
}



func createDefaultAccentColor() {
    let defaultAccentColour = Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2)
    UserDefaults.standard.set(defaultAccentColour, forKey: "accentColour")
}


class WindyData: ObservableObject {
    // could move this to its own struct and have its own toJson fromJson
    @Published var displaySettings: [String: NSPoint] = [:] {
        didSet {
            setDisplaySettings(settings: displaySettings)
            if !isShownTimeout {
                self.isShown    = true
                isShownTimeout  = true
                _ = Timer.init(timeInterval: 1, repeats: false) { timer in
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
    @Published var isShownTimeout   = false
    @Published var rects            : [[NSRect]] = []
    @Published var accentColour     = Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2) {
        didSet {
            UserDefaults.standard.set(self.accentColour, forKey: "accentColour")
        }
    }
    
    init() {
        // create the default settings
        if UserDefaults.standard.bool(forKey: "defaultsSet") == false {
            setDisplaySettings()
            createDefaultAccentColor()
            UserDefaults.standard.set(true, forKey: "defaultsSet")
        }
        // load the default display settings into the windyData
        do {
            self.displaySettings = try UserDefaults.standard.getDictPoints(forKey: "displaySettings")
        } catch {
            print("failed to get the displaySettings")
        }
        // load the default access colour into the windyData
        self.accentColour =  UserDefaults.standard.color(forKey: "accentColour")
        
        // add listener to update the defaults when a new monitor is added
        NotificationCenter.default.addObserver(
            forName : NSApplication.didChangeScreenParametersNotification,
            object  : NSApplication.shared,
            queue   : OperationQueue.main
        ){
            notification -> Void in setDisplaySettings()
        }
    }
}
