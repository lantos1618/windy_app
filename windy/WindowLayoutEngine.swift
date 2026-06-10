//
//  WindowLayoutEngine.swift
//  windy
//
//  Created by Codex on 10/06/2026.
//

import Foundation

struct GridLayoutSettings: Equatable {
    let columns: Int
    let rows: Int

    init(columns: Int, rows: Int) {
        self.columns = max(1, columns)
        self.rows = max(1, rows)
    }

    init(point: NSPoint) {
        self.init(
            columns: Int(point.x.rounded()),
            rows: Int(point.y.rounded())
        )
    }
}

enum WindowLayoutEngine {
    static func gridRects(columns: Int, rows: Int, in frame: NSRect) -> [[NSRect]] {
        guard columns > 0, rows > 0 else {
            return []
        }

        let cellWidth = frame.width / CGFloat(columns)
        let cellHeight = frame.height / CGFloat(rows)

        return (0..<columns).map { column in
            (0..<rows).map { row in
                NSRect(
                    x: frame.minX + CGFloat(column) * cellWidth,
                    y: frame.minY + CGFloat(row) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                )
            }
        }
    }

    static func resizeLengths(totalLength: CGFloat, divisions: Int) -> [CGFloat] {
        guard totalLength.isFinite, totalLength > 0, divisions >= 1 else {
            return []
        }

        let halfLength = totalLength / 2
        let tolerance = max(1.0, totalLength * 0.001)
        var lengths = (1...divisions).map { index in
            totalLength * CGFloat(index) / CGFloat(divisions)
        }

        if !lengths.contains(where: { abs($0 - halfLength) <= tolerance }) {
            lengths.append(halfLength)
        }

        return lengths.sorted()
    }

    static func nextResizeLength(currentLength: CGFloat, totalLength: CGFloat, divisions: Int) -> CGFloat {
        let lengths = resizeLengths(totalLength: totalLength, divisions: divisions)
        guard let smallest = lengths.first, let largest = lengths.last else {
            return currentLength
        }

        let tolerance = max(1.0, totalLength * 0.01)
        if currentLength <= smallest + tolerance {
            return largest
        }

        for length in lengths.reversed() where length < currentLength - tolerance {
            return length
        }

        return largest
    }

    static func movedFrame(windowFrame: NSRect, screenFrame: NSRect, settings: GridLayoutSettings, direction: Direction) -> NSRect {
        var frame = windowFrame
        let cellWidth = round(screenFrame.width / CGFloat(settings.columns))
        let cellHeight = round(screenFrame.height / CGFloat(settings.rows))

        switch direction {
        case .Left:
            frame.origin.x -= cellWidth
        case .Right:
            frame.origin.x += cellWidth
        case .Up:
            frame.origin.y -= cellHeight
        case .Down:
            frame.origin.y += cellHeight
        }

        frame.origin = clampedOrigin(for: frame, in: screenFrame)
        return frame.integral
    }

    static func resizedFrame(windowFrame: NSRect, screenFrame: NSRect, settings: GridLayoutSettings, direction: Direction) -> NSRect {
        var frame = windowFrame
        let minWidth = resizeLengths(totalLength: screenFrame.width, divisions: settings.columns).first ?? screenFrame.width
        let minHeight = resizeLengths(totalLength: screenFrame.height, divisions: settings.rows).first ?? screenFrame.height

        switch direction {
        case .Left:
            frame.size.width = nextResizeLength(
                currentLength: frame.width,
                totalLength: screenFrame.width,
                divisions: settings.columns
            )
        case .Right:
            frame.size.width = nextResizeLength(
                currentLength: frame.width,
                totalLength: screenFrame.width,
                divisions: settings.columns
            )
            frame.origin.x = screenFrame.maxX - frame.width
        case .Up:
            frame.size.height = nextResizeLength(
                currentLength: frame.height,
                totalLength: screenFrame.height,
                divisions: settings.rows
            )
        case .Down:
            frame.size.height = nextResizeLength(
                currentLength: frame.height,
                totalLength: screenFrame.height,
                divisions: settings.rows
            )
            frame.origin.y = screenFrame.maxY - frame.height
        }

        frame.size.width = frame.width.clamp(to: minWidth...screenFrame.width)
        frame.size.height = frame.height.clamp(to: minHeight...screenFrame.height)
        frame.origin = clampedOrigin(for: frame, in: screenFrame)
        return frame.integral
    }

    static func shouldResize(windowFrame: NSRect, screenFrame: NSRect, direction: Direction) -> Bool {
        let collisions = windowFrame.collisionsInside(rect: screenFrame)
        return !collisions.isEmpty && collisions.contains(direction)
    }

    private static func clampedOrigin(for frame: NSRect, in bounds: NSRect) -> NSPoint {
        NSPoint(
            x: frame.minX.clamp(to: safeRange(bounds.minX, bounds.maxX - frame.width)),
            y: frame.minY.clamp(to: safeRange(bounds.minY, bounds.maxY - frame.height))
        )
    }

    private static func safeRange(_ lower: CGFloat, _ upper: CGFloat) -> ClosedRange<CGFloat> {
        lower <= upper ? lower...upper : lower...lower
    }
}
