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
    WindySettingsStore.defaultDisplaySettings()
}

func mergeDisplaySettings(left: [String: NSPoint] = [:] , right: [String: NSPoint] = [:]) -> [String: NSPoint] {
    WindySettingsStore.mergeDisplaySettings(existing: left, defaults: right)
}

func storeDisplaySettings(settings: [String: NSPoint]) {
    WindySettingsStore.saveDisplaySettings(settings)
}


func createDefaultAccentColor() {
    WindySettingsStore.saveAccentColour(WindySettingsStore.defaultAccentColour)
}



func createDefaultDisplaySettings() {
    storeDisplaySettings(settings: generateDisplaySettingsFromActiveScreens())
}



class WindyData: ObservableObject {
    
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
            WindySettingsStore.saveDisplaySettings(displaySettings)

        }
    }
    @Published var accentColour         = Color(
            red     : 0.4,
            green   : 0.4,
            blue    : 0.4,
            opacity : 0.2
    ) {
        didSet {
            WindySettingsStore.saveAccentColour(self.accentColour)
        }
    }
    
    init() {
        // create the default settings
        WindySettingsStore.ensureDefaultsExist()
        activeScreens = NSScreen.screens.map( {screen in screen.getIdString()})
        
        // load the default display settings into the windyData
        do {
            let oldDisplaySettings      = try WindySettingsStore.loadDisplaySettings()
            let newDisplaySettings      = WindySettingsStore.defaultDisplaySettings()
            let mergedDisplaySettings   = WindySettingsStore.mergeDisplaySettings(existing: oldDisplaySettings, defaults: newDisplaySettings)
            self.displaySettings = mergedDisplaySettings
        } catch {
            debugPrint("failed to get the displaySettings")
        }

        // load the default access colour into the windyData
        self.accentColour       = WindySettingsStore.loadAccentColour()
        
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
