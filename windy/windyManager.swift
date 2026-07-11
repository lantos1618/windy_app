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
    var missionControlOverlayManager: MissionControlOverlayManager
    
    init(windyData: WindyData) {
        snapManager = SnapWindowManager(windyData: windyData)
        gridManager = GridManager(windyData: windyData)
        missionControlOverlayManager = MissionControlOverlayManager()
    }
    
    func registerGlobalEvents() {
        // keyboard shortcuts
        self.gridManager.registerEvents()
        self.snapManager.registerEvents()
        self.missionControlOverlayManager.start()
    }
}
