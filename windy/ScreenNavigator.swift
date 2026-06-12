//
//  ScreenNavigator.swift
//  windy
//
//  Created by Codex on 10/06/2026.
//

import Foundation
import AppKit

struct ScreenCandidate: Equatable {
    let id: String
    let frame: NSRect
}

enum ScreenNavigator {
    static func nextScreen(from currentScreen: NSScreen, direction: Direction, screens: [NSScreen] = NSScreen.screens) -> NSScreen? {
        let currentId = ScreenGeometryService.id(for: currentScreen)
        let candidates = screens
            .filter { ScreenGeometryService.id(for: $0) != currentId }
            .map { ScreenCandidate(id: ScreenGeometryService.id(for: $0), frame: ScreenGeometryService.accessibilityFrame(for: $0)) }

        guard let nextCandidate = nextFrame(
            from: ScreenGeometryService.accessibilityFrame(for: currentScreen),
            candidates: candidates,
            direction: direction
        ) else {
            return nil
        }

        return screens.first { ScreenGeometryService.id(for: $0) == nextCandidate.id }
    }

    static func nextFrame(from currentFrame: NSRect, candidates: [ScreenCandidate], direction: Direction) -> ScreenCandidate? {
        let center = currentFrame.centerPoint()

        return candidates
            .filter { isCandidate($0.frame, in: direction, from: currentFrame) }
            .min { left, right in
                score(candidate: left.frame, fromCenter: center, direction: direction)
                    < score(candidate: right.frame, fromCenter: center, direction: direction)
            }
    }

    private static func isCandidate(_ candidate: NSRect, in direction: Direction, from current: NSRect) -> Bool {
        switch direction {
        case .Left:
            return candidate.midX < current.midX
        case .Right:
            return candidate.midX > current.midX
        case .Up:
            return candidate.midY < current.midY
        case .Down:
            return candidate.midY > current.midY
        }
    }

    private static func score(candidate: NSRect, fromCenter center: NSPoint, direction: Direction) -> CGFloat {
        let primaryDistance: CGFloat
        let overlapPenalty: CGFloat

        switch direction {
        case .Left:
            primaryDistance = max(0, center.x - candidate.maxX)
            overlapPenalty = distanceFromRange(center.y, min: candidate.minY, max: candidate.maxY)
        case .Right:
            primaryDistance = max(0, candidate.minX - center.x)
            overlapPenalty = distanceFromRange(center.y, min: candidate.minY, max: candidate.maxY)
        case .Up:
            primaryDistance = max(0, center.y - candidate.maxY)
            overlapPenalty = distanceFromRange(center.x, min: candidate.minX, max: candidate.maxX)
        case .Down:
            primaryDistance = max(0, candidate.minY - center.y)
            overlapPenalty = distanceFromRange(center.x, min: candidate.minX, max: candidate.maxX)
        }

        return primaryDistance + overlapPenalty * 2
    }

    private static func distanceFromRange(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if value < min {
            return min - value
        }

        if value > max {
            return value - max
        }

        return 0
    }
}
