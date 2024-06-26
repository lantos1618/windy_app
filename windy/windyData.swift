//
//  windyData.swift
//  windy
//
//  Created by Lyndon Leong on 27/01/2023.
//

import Foundation
import SwiftUI
import ServiceManagement



func generateDisplaySettingsFromActiveScreens() -> [String: NSPoint] {
    var result: [String: NSPoint] = [:]
    for screen in NSScreen.screens {
        let screenName = screen.getIdString()
        if !result.keys.contains(screenName) {
            result[screenName] = NSPoint(x: 2.0, y: 2.0)
        }
    }
    return result
}

func mergeDisplaySettings(left: [String: NSPoint] = [:] , right: [String: NSPoint] = [:]) -> [String: NSPoint] {
    var result: [String: NSPoint] = left
    for (key, val) in right {
        if !result.keys.contains(key) {
            result[key] = val
        }
    }
    return result
}

func storeDisplaySettings(settings: [String: NSPoint]) {
    do {
        try UserDefaults.standard.set(dict: settings , forKey: "displaySettings")
    } catch {
        debugPrint("failed to set default displaySettings")
    }
}


func createDefaultAccentColor() {
    let defaultAccentColour = Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2)
    UserDefaults.standard.set(defaultAccentColour, forKey: "accentColour")
}



func createDefaultDisplaySettings() {
    storeDisplaySettings(settings: generateDisplaySettingsFromActiveScreens())
}



class WindyData: ObservableObject {
    
    // license details
    @Published var email: String = UserDefaults.standard.string(forKey: "email") ?? "" {
        didSet {
            UserDefaults.standard.set(licenseKey, forKey: "email")
        }
    }
    @Published var licenseKey: String = UserDefaults.standard.string(forKey: "licenseKey") ?? "" {
        didSet {
            UserDefaults.standard.set(licenseKey, forKey: "licenseKey")
        }
    }
    @Published var licenseStatus: String = ""

    @Published var isShown              = false
    @Published var isShownTimeout       : Timer?
    @Published var rectsDict            : [String: [[NSRect]]]  = [:]
//    @Published var previewRects         : [[NSRect]] = []
    @Published var activeSettingScreen  : String                = NSScreen.main!.getIdString()
    @Published var activeScreens        : [String] = []
    
    @Published var displaySettings      : [String: NSPoint]     = [:] {
        didSet {
            // update the rects window when the displaySettings change
            for (key, val) in displaySettings {
                rectsDict[key] = createRects(
                    columns : Double(val.x),
                    rows    : Double(val.y),
                    screen  : NSScreen.fromIdString(str: key) ?? NSScreen.main!
                )
            }
            storeDisplaySettings(settings: displaySettings)

        }
    }
    @Published var accentColour         = Color(
            red     : 0.4,
            green   : 0.4,
            blue    : 0.4,
            opacity : 0.2
    ) {
        didSet {
            UserDefaults.standard.set(self.accentColour, forKey: "accentColour")
        }
    }
    
    init() {
        // create the default settings
        if UserDefaults.standard.bool(forKey: "defaultsSet") == false {
            createDefaultAccentColor()
            createDefaultDisplaySettings()
            UserDefaults.standard.set(true, forKey: "defaultsSet")
        }
        activeScreens = NSScreen.screens.map( {screen in screen.getIdString()})
        
        // load the default display settings into the windyData
        do {
            let oldDisplaySettings      = try UserDefaults.standard.getDictPoints(forKey: "displaySettings")
            let newDisplaySettings      = generateDisplaySettingsFromActiveScreens()
            let mergedDisplaySettings   = mergeDisplaySettings(left: oldDisplaySettings, right: newDisplaySettings)
            self.displaySettings = mergedDisplaySettings
        } catch {
            debugPrint("failed to get the displaySettings")
        }

        // load the default access colour into the windyData
        self.accentColour       = UserDefaults.standard.color(forKey: "accentColour")
        
        // add listener to update the defaults when a new monitor is added
        NotificationCenter.default.addObserver(
            forName : NSApplication.didChangeScreenParametersNotification,
            object  : NSApplication.shared,
            queue   : OperationQueue.main
        ){
            notification -> Void in
            let oldDisplaySettings      = self.displaySettings
            let newDisplaySettings      = generateDisplaySettingsFromActiveScreens()
            let mergedDisplaySettings   = mergeDisplaySettings(left: oldDisplaySettings, right: newDisplaySettings)
            self.displaySettings        = mergedDisplaySettings
            self.activeScreens          = NSScreen.screens.map({screen in screen.getIdString()})
            // refresh preview
            if (self.isShown) {
                self.isShown = false
            }
        }
    }
    func restSettings() {
        self.displaySettings = generateDisplaySettingsFromActiveScreens()
    }
}
