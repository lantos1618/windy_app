//
//  SpaceLabelManager.swift
//  windy
//
//  Created by Codex on 11/07/2026.
//

import AppKit
import Combine
import Darwin
import SwiftUI

struct WindySpace: Identifiable, Equatable {
    let id: String
    let managedSpaceID: UInt64
    let displayIdentifier: String
    let index: Int
    let isCurrent: Bool
}

struct WindySpaceDisplay: Identifiable, Equatable {
    let id: String
    let index: Int
    let spaces: [WindySpace]
}

enum SpaceLabelColour: String, CaseIterable, Codable, Identifiable {
    case teal
    case pink
    case green
    case orange
    case blue
    case yellow

    var id: String { rawValue }

    var nsColor: NSColor {
        switch self {
        case .teal: return .systemTeal
        case .pink: return .systemPink
        case .green: return .systemGreen
        case .orange: return .systemOrange
        case .blue: return .systemBlue
        case .yellow: return .systemYellow
        }
    }

    var color: Color {
        Color(nsColor: nsColor)
    }

    var displayName: String {
        rawValue.capitalized
    }
}

struct StoredSpaceLabel: Codable, Equatable {
    var name: String
    var colour: SpaceLabelColour
}

final class SpaceLabelStore {
    static let labelsKey = "spaceLabels"

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = labelsKey) {
        self.defaults = defaults
        self.key = key
    }

    func load() -> [String: StoredSpaceLabel] {
        guard
            let data = defaults.data(forKey: key),
            let labels = try? JSONDecoder().decode([String: StoredSpaceLabel].self, from: data)
        else {
            return [:]
        }

        return labels
    }

    func save(_ labels: [String: StoredSpaceLabel]) {
        guard let data = try? JSONEncoder().encode(labels) else { return }
        defaults.set(data, forKey: key)
    }
}

final class SpaceService {
    private typealias MainConnectionFunction = @convention(c) () -> Int32
    private typealias CopyManagedDisplaySpacesFunction = @convention(c) (Int32) -> Unmanaged<CFArray>?

    private let libraryHandle: UnsafeMutableRawPointer?
    private let mainConnection: MainConnectionFunction?
    private let copyManagedDisplaySpaces: CopyManagedDisplaySpacesFunction?

    init() {
        let path = "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight"
        libraryHandle = dlopen(path, RTLD_NOW | RTLD_LOCAL)

        if let libraryHandle {
            mainConnection = Self.loadSymbol(
                "SLSMainConnectionID",
                from: libraryHandle,
                as: MainConnectionFunction.self
            )
            copyManagedDisplaySpaces = Self.loadSymbol(
                "SLSCopyManagedDisplaySpaces",
                from: libraryHandle,
                as: CopyManagedDisplaySpacesFunction.self
            )
        } else {
            mainConnection = nil
            copyManagedDisplaySpaces = nil
        }
    }

    deinit {
        if let libraryHandle {
            dlclose(libraryHandle)
        }
    }

    func managedDisplays() -> [WindySpaceDisplay] {
        guard
            let mainConnection,
            let copyManagedDisplaySpaces,
            let rawDisplays = copyManagedDisplaySpaces(mainConnection())?.takeRetainedValue() as? [[String: Any]]
        else {
            return []
        }

        return Self.parseManagedDisplays(rawDisplays)
    }

    static func parseManagedDisplays(_ rawDisplays: [[String: Any]]) -> [WindySpaceDisplay] {
        rawDisplays.enumerated().compactMap { displayIndex, rawDisplay in
            guard let rawSpaces = rawDisplay["Spaces"] as? [[String: Any]] else { return nil }

            let displayIdentifier = rawDisplay["Display Identifier"] as? String ?? "display-\(displayIndex)"
            let currentSpace = rawDisplay["Current Space"] as? [String: Any]
            let currentSpaceID = number(in: currentSpace, keys: ["id64", "ManagedSpaceID"])?.uint64Value
            let userSpaces = rawSpaces.filter { number(in: $0, keys: ["type"])?.intValue == 0 }
            let spaces = userSpaces.enumerated().compactMap { userIndex, rawSpace -> WindySpace? in
                guard let number = number(in: rawSpace, keys: ["id64", "ManagedSpaceID"]) else { return nil }
                let managedSpaceID = number.uint64Value
                let uuid = rawSpace["uuid"] as? String ?? String(managedSpaceID)

                return WindySpace(
                    id: uuid,
                    managedSpaceID: managedSpaceID,
                    displayIdentifier: displayIdentifier,
                    index: userIndex + 1,
                    isCurrent: managedSpaceID == currentSpaceID
                )
            }

            return WindySpaceDisplay(id: displayIdentifier, index: displayIndex, spaces: spaces)
        }
    }

    private static func number(in dictionary: [String: Any]?, keys: [String]) -> NSNumber? {
        guard let dictionary else { return nil }
        for key in keys {
            if let number = dictionary[key] as? NSNumber {
                return number
            }
            if let integer = dictionary[key] as? Int {
                return NSNumber(value: integer)
            }
        }
        return nil
    }

    private static func loadSymbol<T>(_ name: String, from handle: UnsafeMutableRawPointer, as type: T.Type) -> T? {
        guard let pointer = dlsym(handle, name) else { return nil }
        return unsafeBitCast(pointer, to: type)
    }
}

final class SpaceLabelManager: ObservableObject {
    @Published private(set) var displays: [WindySpaceDisplay] = []
    @Published private(set) var labels: [String: StoredSpaceLabel]

    private let service: SpaceService
    private let store: SpaceLabelStore
    private var activeSpaceObserver: NSObjectProtocol?
    private var isRunning = false

    init(service: SpaceService = SpaceService(), store: SpaceLabelStore = SpaceLabelStore()) {
        self.service = service
        self.store = store
        labels = store.load()
    }

    deinit {
        if let activeSpaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activeSpaceObserver)
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        refresh()
        activeSpaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        displays = service.managedDisplays()
    }

    func space(displayIndex: Int, desktopIndex: Int) -> WindySpace? {
        guard displays.indices.contains(displayIndex) else { return nil }
        let spaces = displays[displayIndex].spaces
        guard spaces.indices.contains(desktopIndex) else { return nil }
        return spaces[desktopIndex]
    }

    func name(for space: WindySpace?, fallbackIndex: Int) -> String {
        guard let space else { return "Windy \(fallbackIndex)" }
        let storedName = labels[space.id]?.name ?? ""
        let trimmedName = storedName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Windy \(fallbackIndex)" : trimmedName
    }

    func colour(for space: WindySpace?, fallbackIndex: Int) -> SpaceLabelColour {
        if let space, let colour = labels[space.id]?.colour {
            return colour
        }
        return SpaceLabelColour.allCases[(fallbackIndex - 1) % SpaceLabelColour.allCases.count]
    }

    func setName(_ name: String, for spaceID: String) {
        let existing = labels[spaceID] ?? StoredSpaceLabel(
            name: "",
            colour: defaultColour(for: spaceID)
        )
        labels[spaceID] = StoredSpaceLabel(
            name: name,
            colour: existing.colour
        )
        store.save(labels)
    }

    func setColour(_ colour: SpaceLabelColour, for spaceID: String) {
        let existing = labels[spaceID] ?? StoredSpaceLabel(name: "", colour: colour)
        labels[spaceID] = StoredSpaceLabel(name: existing.name, colour: colour)
        store.save(labels)
    }

    private func defaultColour(for spaceID: String) -> SpaceLabelColour {
        let index = displays
            .flatMap(\.spaces)
            .first(where: { $0.id == spaceID })?
            .index ?? 1
        return SpaceLabelColour.allCases[(index - 1) % SpaceLabelColour.allCases.count]
    }
}
