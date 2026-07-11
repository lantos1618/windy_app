//
//  windyManager.swift
//  windy
//
//  Created by Lyndon Leong on 09/01/2023.
//

import Foundation


class WindyManager {
    var snapManager : SnapWindowManager
    var gridManager : GridManager
    var spaceLabelManager: SpaceLabelManager
    var missionControlOverlayManager: MissionControlOverlayManager
    
    init(windyData: WindyData) {
        snapManager = SnapWindowManager(windyData: windyData)
        gridManager = GridManager(windyData: windyData)
        spaceLabelManager = SpaceLabelManager()
        missionControlOverlayManager = MissionControlOverlayManager(spaceLabelManager: spaceLabelManager)
    }
    
    func registerGlobalEvents() {
        // keyboard shortcuts
        self.gridManager.registerEvents()
        self.snapManager.registerEvents()
        self.spaceLabelManager.start()
        self.missionControlOverlayManager.start()
    }
}
