//
//  MenuPopover.swift
//  windy
//
//  Created by Lyndon Leong on 15/01/2023.
//

import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

struct KeyboardShortcutsSettings: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            shortcutGroupTitle("Move within display")
            shortcutRow("Left", systemImage: "arrow.left", name: .moveWindowLeft)
            shortcutRow("Right", systemImage: "arrow.right", name: .moveWindowRight)
            shortcutRow("Up", systemImage: "arrow.up", name: .moveWindowUp)
            shortcutRow("Down", systemImage: "arrow.down", name: .moveWindowDown)

            Divider()
                .padding(.vertical, 2)

            shortcutGroupTitle("Move to another display")
            shortcutRow("Left display", systemImage: "arrow.left.to.line", name: .moveWindowScreenLeft)
            shortcutRow("Right display", systemImage: "arrow.right.to.line", name: .moveWindowScreenRight)
            shortcutRow("Display above", systemImage: "arrow.up.to.line", name: .moveWindowScreenUp)
            shortcutRow("Display below", systemImage: "arrow.down.to.line", name: .moveWindowScreenDown)
        }
    }

    private func shortcutGroupTitle(_ title: String) -> some View {
        Text(title)
            .font(.callout.weight(.medium))
            .foregroundStyle(.secondary)
    }

    private func shortcutRow(
        _ title: String,
        systemImage: String,
        name: KeyboardShortcuts.Name
    ) -> some View {
        HStack(spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.callout)
                .lineLimit(1)

            Spacer(minLength: 12)

            KeyboardShortcuts.Recorder(for: name)
                .frame(width: 150, alignment: .trailing)
        }
        .frame(minHeight: 24)
    }
}

struct MenuPopover: View {
    @StateObject var windyData: WindyData
    @ObservedObject var spaceLabelManager: SpaceLabelManager
    @State private var isConfirmingDisplayReset = false
    @State private var isConfirmingShortcutReset = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if windyData.displaySettings.keys.contains(windyData.activeSettingScreen) {
                        settingsSection("Layout") {
                            screenPickerSection
                        }
                    }

                    settingsSection("Spaces") {
                        spaceLabelsSection
                    }

                    settingsSection("Shortcuts") {
                        KeyboardShortcutsSettings()
                    }

                    settingsSection("General") {
                        generalSettings
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 400, height: 620)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            spaceLabelManager.refresh()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.3.group")
                .font(.title3)
                .foregroundStyle(windyData.accentColour)

            Text("Windy")
                .font(.headline)

            Spacer()

            Button {
                NSApplication.shared.terminate(self)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit Windy")
            .accessibilityLabel("Quit Windy")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            content()
        }
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            LaunchAtLogin.Toggle()
                .toggleStyle(.checkbox)

            Divider()

            HStack(spacing: 8) {
                Button("Reset Layout", role: .destructive) {
                    isConfirmingDisplayReset = true
                }
                .confirmationDialog(
                    "Reset display layouts?",
                    isPresented: $isConfirmingDisplayReset
                ) {
                    Button("Reset Display Layouts", role: .destructive) {
                        windyData.restSettings()
                    }
                } message: {
                    Text("This restores the default rows, columns, and display settings.")
                }

                Button("Reset Shortcuts", role: .destructive) {
                    isConfirmingShortcutReset = true
                }
                .confirmationDialog(
                    "Reset keyboard shortcuts?",
                    isPresented: $isConfirmingShortcutReset
                ) {
                    Button("Reset Keyboard Shortcuts", role: .destructive) {
                        resetKeyboardShortcuts()
                    }
                } message: {
                    Text("This restores every Windy keyboard shortcut to its default.")
                }
            }
        }
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

    private var activeDisplaySetting: NSPoint {
        windyData.displaySettings[windyData.activeSettingScreen] ?? NSPoint(x: 2, y: 2)
    }

    private var columnsBinding: Binding<Int> {
        Binding(
            get: { Int(activeDisplaySetting.x) },
            set: { value in
                updateActiveDisplaySetting { $0.x = CGFloat(value) }
            }
        )
    }

    private var rowsBinding: Binding<Int> {
        Binding(
            get: { Int(activeDisplaySetting.y) },
            set: { value in
                updateActiveDisplaySetting { $0.y = CGFloat(value) }
            }
        )
    }

    private func updateActiveDisplaySetting(_ update: (inout NSPoint) -> Void) {
        guard !windyData.activeSettingScreen.isEmpty else {
            return
        }

        var setting = activeDisplaySetting
        update(&setting)
        windyData.displaySettings[windyData.activeSettingScreen] = setting
    }

    private var screenPickerSection: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
            GridRow {
                settingLabel("Display")
                Picker("Display", selection: $windyData.activeSettingScreen) {
                    ForEach(windyData.displaySettings.keys.sorted(), id: \.self) { key in
                        let screenName = NSScreen.fromIdString(str: key)?.localizedName ?? key
                        let status = windyData.activeScreens.contains(key) ? " - Connected" : ""
                        Text(screenName + status).tag(key)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GridRow {
                settingLabel("Columns")
                Stepper(value: columnsBinding, in: 1...6) {
                    Text("\(columnsBinding.wrappedValue)")
                        .monospacedDigit()
                }
            }

            GridRow {
                settingLabel("Rows")
                Stepper(value: rowsBinding, in: 1...6) {
                    Text("\(rowsBinding.wrappedValue)")
                        .monospacedDigit()
                }
            }

            GridRow {
                settingLabel("Preview")
                Button {
                    windyData.isShown.toggle()
                } label: {
                    Image(systemName: windyData.isShown ? "eye.fill" : "eye")
                }
                .help(windyData.isShown ? "Hide layout preview" : "Show layout preview")
                .accessibilityLabel(windyData.isShown ? "Hide layout preview" : "Show layout preview")
            }

            GridRow {
                settingLabel("Accent color")
                ColorPicker("Accent color", selection: $windyData.accentColour)
                    .labelsHidden()
            }
        }
    }

    @ViewBuilder
    private var spaceLabelsSection: some View {
        if spaceLabelManager.displays.allSatisfy({ $0.spaces.isEmpty }) {
            Text("No desktop Spaces found")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(spaceLabelManager.displays) { display in
                    if spaceLabelManager.displays.count > 1 {
                        Text(displayName(for: display))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    ForEach(display.spaces) { space in
                        spaceLabelRow(space)
                    }
                }
            }
        }
    }

    private func spaceLabelRow(_ space: WindySpace) -> some View {
        HStack(spacing: 10) {
            Image(systemName: space.isCurrent ? "circle.inset.filled" : "circle")
                .font(.caption)
                .foregroundStyle(space.isCurrent ? .primary : .tertiary)
                .frame(width: 14)
                .help(space.isCurrent ? "Current Space" : "Space \(space.index)")

            TextField(
                "Space name",
                text: spaceNameBinding(for: space),
                prompt: Text("Windy \(space.index)")
            )
            .textFieldStyle(.roundedBorder)

            HStack(spacing: 3) {
                Circle()
                    .fill(selectedColour(for: space).color)
                    .frame(width: 14, height: 14)

                Menu {
                    ForEach(SpaceLabelColour.allCases) { colour in
                        Button {
                            spaceLabelManager.setColour(colour, for: space.id)
                        } label: {
                            Text(colour.displayName)
                            if colour == selectedColour(for: space) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 16, height: 22)
            }
            .help("Label colour")
            .accessibilityLabel("Label colour for Space \(space.index)")
        }
        .frame(minHeight: 26)
    }

    private func spaceNameBinding(for space: WindySpace) -> Binding<String> {
        Binding(
            get: { spaceLabelManager.labels[space.id]?.name ?? "" },
            set: { spaceLabelManager.setName($0, for: space.id) }
        )
    }

    private func selectedColour(for space: WindySpace) -> SpaceLabelColour {
        spaceLabelManager.colour(for: space, fallbackIndex: space.index)
    }

    private func displayName(for display: WindySpaceDisplay) -> String {
        guard NSScreen.screens.indices.contains(display.index) else {
            return "Display \(display.index + 1)"
        }
        return NSScreen.screens[display.index].localizedName
    }

    private func settingLabel(_ title: String) -> some View {
        Text(title)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(width: 88, alignment: .leading)
    }
}
