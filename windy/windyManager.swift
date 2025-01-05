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
    
    init(appState: AppState) {
        snapManager = SnapWindowManager(appState: appState)
        gridManager = GridManager(appState: appState)
    }
    
    func registerGlobalEvents() {
        // keyboard shortcuts
        self.gridManager.registerEvents()
        self.snapManager.registerEvents()
    }
}

