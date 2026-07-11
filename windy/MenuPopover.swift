//
//  MenuPopover.swift
//  windy
//
//  Created by Lyndon Leong on 15/01/2023.
//

import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

private struct CompactColorWell: NSViewRepresentable {
    @Binding var colour: Color

    final class Coordinator: NSObject {
        var colour: Binding<Color>

        init(colour: Binding<Color>) {
            self.colour = colour
        }

        @objc func colourChanged(_ sender: NSColorWell) {
            colour.wrappedValue = Color(nsColor: sender.color)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(colour: $colour)
    }

    func makeNSView(context: Context) -> NSColorWell {
        let colorWell = NSColorWell(frame: NSRect(x: 0, y: 0, width: 26, height: 26))
        colorWell.colorWellStyle = .minimal
        colorWell.target = context.coordinator
        colorWell.action = #selector(Coordinator.colourChanged(_:))
        colorWell.toolTip = "Choose a custom accent colour"
        return colorWell
    }

    func updateNSView(_ colorWell: NSColorWell, context: Context) {
        context.coordinator.colour = $colour
        colorWell.color = NSColor(colour)
    }
}

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
    private static let accentPalette: [NSColor] = [
        .systemBlue,
        .systemTeal,
        .systemGreen,
        .systemOrange,
        .systemPink,
        .systemPurple,
    ]

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
        VStack(spacing: 8) {
            settingRow("Display") {
                Picker("Display", selection: $windyData.activeSettingScreen) {
                    ForEach(windyData.displaySettings.keys.sorted(), id: \.self) { key in
                        let screenName = NSScreen.fromIdString(str: key)?.localizedName ?? key
                        let status = windyData.activeScreens.contains(key) ? " - Connected" : ""
                        Text(screenName + status).tag(key)
                    }
                }
                .labelsHidden()
                .frame(width: 252)
            }

            settingRow("Columns") {
                countControl(value: columnsBinding, range: 1...6, name: "columns")
            }

            settingRow("Rows") {
                countControl(value: rowsBinding, range: 1...6, name: "rows")
            }

            settingRow("Preview") {
                Toggle("Preview layout", isOn: $windyData.isShown)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                .help(windyData.isShown ? "Hide layout preview" : "Show layout preview")
                    .accessibilityLabel("Preview layout")
            }

            settingRow("Accent colour") {
                HStack(spacing: 7) {
                    ForEach(Array(Self.accentPalette.enumerated()), id: \.offset) { _, colour in
                        Button {
                            windyData.accentColour = Color(nsColor: colour)
                        } label: {
                            Circle()
                                .fill(Color(nsColor: colour))
                                .frame(width: 15, height: 15)
                                .overlay {
                                    if isSelectedAccent(colour) {
                                        Circle()
                                            .stroke(.primary, lineWidth: 2)
                                            .padding(-3)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 22, height: 26)
                        .help("Use \(accentName(colour))")
                        .accessibilityLabel("Use \(accentName(colour))")
                    }

                    CompactColorWell(colour: $windyData.accentColour)
                        .frame(width: 26, height: 26)
                        .accessibilityLabel("Choose a custom accent colour")
                }
            }
        }
    }

    private func settingRow<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            settingLabel(title)
            Spacer(minLength: 8)
            content()
        }
        .frame(height: 30)
    }

    private func countControl(
        value: Binding<Int>,
        range: ClosedRange<Int>,
        name: String
    ) -> some View {
        HStack(spacing: 0) {
            countButton(
                systemImage: "minus",
                help: "Decrease \(name)",
                isDisabled: value.wrappedValue == range.lowerBound
            ) {
                value.wrappedValue -= 1
            }

            Text("\(value.wrappedValue)")
                .font(.callout.monospacedDigit())
                .frame(width: 34)

            countButton(
                systemImage: "plus",
                help: "Increase \(name)",
                isDisabled: value.wrappedValue == range.upperBound
            ) {
                value.wrappedValue += 1
            }
        }
        .frame(height: 26)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        }
    }

    private func countButton(
        systemImage: String,
        help: String,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .frame(width: 28, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .help(help)
        .accessibilityLabel(help)
    }

    private func isSelectedAccent(_ colour: NSColor) -> Bool {
        guard
            let selected = NSColor(windyData.accentColour).usingColorSpace(.deviceRGB),
            let candidate = colour.usingColorSpace(.deviceRGB)
        else {
            return false
        }

        return abs(selected.redComponent - candidate.redComponent) < 0.01
            && abs(selected.greenComponent - candidate.greenComponent) < 0.01
            && abs(selected.blueComponent - candidate.blueComponent) < 0.01
    }

    private func accentName(_ colour: NSColor) -> String {
        switch colour {
        case NSColor.systemBlue: return "blue"
        case NSColor.systemTeal: return "teal"
        case NSColor.systemGreen: return "green"
        case NSColor.systemOrange: return "orange"
        case NSColor.systemPink: return "pink"
        default: return "purple"
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
            .frame(width: 94, alignment: .leading)
    }
}
