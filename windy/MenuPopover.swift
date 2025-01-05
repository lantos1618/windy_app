//
//  MenunPopover.swift
//  windy
//
//  Created by Lyndon Leong on 15/01/2023.
//

import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin



struct KeyboardShortcutsSettings: View {
    var body: some View {
        Form {
            Section(header: Text("Move Window in Screen")) {
                KeyboardShortcuts.Recorder("Move window left:",     name: .moveWindowLeft)
                KeyboardShortcuts.Recorder("Move window right:",    name: .moveWindowRight)
                KeyboardShortcuts.Recorder("Move window up:",       name: .moveWindowUp)
                KeyboardShortcuts.Recorder("Move window down:",     name: .moveWindowDown)
            }
            Section(header: Text("Move Window to Screen")) {
                KeyboardShortcuts.Recorder("Move window to left screen:",     name: .moveWindowScreenLeft)
                KeyboardShortcuts.Recorder("Move window to right screen:",    name: .moveWindowScreenRight)
                KeyboardShortcuts.Recorder("Move window to up screen:",       name: .moveWindowScreenUp)
                KeyboardShortcuts.Recorder("Move window down screen:",        name: .moveWindowScreenDown)
            }
        }
    }
}



struct MenuPopover: View {
    @ObservedObject var appState: AppState
    @State private var isPresentingConfirm: Bool = false
    
    var body: some View {
        VStack {
            Text("Windy window manager")
                .font(.title)
                .padding()
            
            if appState.displaySettings.keys.contains(appState.activeSettingScreen) {
                screenSettingsSection
            }
            
            Text("Keyboard Shortcuts")
                .font(.title2)
                .padding()
            KeyboardShortcutsSettings()
            
            Text("Reset settings")
                .font(.title2)
                .padding()
            
            settingsSection
        }
        .padding()
    }
    
    private var screenSettingsSection: some View {
        VStack {
            Picker("Active Screen", selection: $appState.activeSettingScreen) {
                ForEach(appState.activeScreens, id: \.self) { screenId in
                    Text(screenId).tag(screenId)
                }
            }
            .pickerStyle(.menu)
            
            if let settings = appState.displaySettings[appState.activeSettingScreen] {
                HStack {
                    Text("Columns")
                    Stepper(
                        value: Binding(
                            get: { settings.x },
                            set: { appState.updateDisplaySettings(
                                for: appState.activeSettingScreen,
                                columns: $0,
                                rows: settings.y
                            )}
                        ),
                        in: 1...10
                    ) {
                        Text("\(Int(settings.x))")
                    }
                }
                
                HStack {
                    Text("Rows")
                    Stepper(
                        value: Binding(
                            get: { settings.y },
                            set: { appState.updateDisplaySettings(
                                for: appState.activeSettingScreen,
                                columns: settings.x,
                                rows: $0
                            )}
                        ),
                        in: 1...10
                    ) {
                        Text("\(Int(settings.y))")
                    }
                }
            }
        }
        .padding()
    }
    
    private var settingsSection: some View {
        VStack {
            Button("Reset all display Settings") {
                isPresentingConfirm = true
            }
            .confirmationDialog(
                "Are you sure you want to reset all display settings?",
                isPresented: $isPresentingConfirm
            ) {
                Button("Reset all display settings", role: .destructive) {
                    appState.resetSettings()
                }
            }
            
            Button("Reset Keyboard shortcuts") {
                isPresentingConfirm = true
            }
            .confirmationDialog(
                "Are you sure you want to reset keyboard shortcuts?",
                isPresented: $isPresentingConfirm
            ) {
                Button("Reset keyboard shortcuts", role: .destructive) {
                    resetKeyboardShortcuts()
                }
            }
            
            LaunchAtLogin.Toggle()
            
            Button("Quit Windy") {
                NSApplication.shared.terminate(nil)
            }
            .padding()
        }
        .padding()
    }
    
    private func resetKeyboardShortcuts() {
        KeyboardShortcuts.reset([
            .moveWindowLeft,
            .moveWindowRight,
            .moveWindowUp,
            .moveWindowDown,
            .moveWindowScreenLeft,
            .moveWindowScreenRight,
            .moveWindowScreenUp,
            .moveWindowScreenDown,
        ])
    }
}
