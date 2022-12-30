//
//  windyApp.swift
//  windy
//
//  Created by Lyndon Leong on 30/12/2022.
//

import SwiftUI

@main
struct windyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
