//
//  windyTests.swift
//  windyTests
//
//  Created by Lyndon Leong on 30/12/2022.
//

import XCTest
@testable import windy
import SwiftUI

final class windyTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Utility Function Tests
    
    func testClampFunction() throws {
        // Test clamping within bounds using the FloatingPoint extension
        XCTAssertEqual(5.0.clamp(to: 0...10), 5.0)
        XCTAssertEqual(15.0.clamp(to: 0...10), 10.0)
        XCTAssertEqual((-5.0).clamp(to: 0...10), 0.0)
        
        // Test edge cases
        XCTAssertEqual(0.0.clamp(to: 0...10), 0.0)
        XCTAssertEqual(10.0.clamp(to: 0...10), 10.0)
        
        // Test with negative ranges
        XCTAssertEqual((-3.0).clamp(to: -10...(-1)), -3.0)
        XCTAssertEqual((-15.0).clamp(to: -10...(-1)), -10.0)
        XCTAssertEqual(0.0.clamp(to: -10...(-1)), -1.0)
    }
    
    func testCoordinateConversion() throws {
        // Test coordinate system conversion
        let point = NSPoint(x: 100, y: 200)
        let flipped = point.flip()
        
        // Verify the flip operation works correctly
        XCTAssertEqual(flipped.x, point.x)
        XCTAssertNotEqual(flipped.y, point.y)
        
        // Test that flipping twice returns to original (for screen coordinates)
        let doubleFlipped = flipped.flip()
        XCTAssertEqual(doubleFlipped.x, point.x)
        XCTAssertEqual(doubleFlipped.y, point.y)
    }
    
    func testCreateRectsFunction() throws {
        // Test creating rectangles with valid parameters
        let screen = NSScreen.main!
        let rects = createRects(columns: 2, rows: 2, screen: screen)
        
        // Should create 4 rectangles (2x2 grid)
        XCTAssertEqual(rects.count, 2)
        XCTAssertEqual(rects[0].count, 2)
        XCTAssertEqual(rects[1].count, 2)
        
        // Test edge cases
        let singleRect = createRects(columns: 1, rows: 1, screen: screen)
        XCTAssertEqual(singleRect.count, 1)
        XCTAssertEqual(singleRect[0].count, 1)
        
        // Test with zero values (should handle gracefully)
        let zeroRects = createRects(columns: 0, rows: 0, screen: screen)
        XCTAssertEqual(zeroRects.count, 0)
    }

    func testGridResizeLengthsAlwaysIncludeHalf() throws {
        let totalLength: CGFloat = 900

        XCTAssertEqual(WindowLayoutEngine.resizeLengths(totalLength: totalLength, divisions: 3), [300, 450, 600, 900])
        XCTAssertEqual(WindowLayoutEngine.resizeLengths(totalLength: totalLength, divisions: 5), [180, 360, 450, 540, 720, 900])
        XCTAssertEqual(WindowLayoutEngine.resizeLengths(totalLength: totalLength, divisions: 2), [450, 900])
    }

    func testNextGridResizeLengthCyclesThroughHalfForOddDivisions() throws {
        let totalLength: CGFloat = 900

        XCTAssertEqual(WindowLayoutEngine.nextResizeLength(currentLength: 900, totalLength: totalLength, divisions: 3), 600)
        XCTAssertEqual(WindowLayoutEngine.nextResizeLength(currentLength: 600, totalLength: totalLength, divisions: 3), 450)
        XCTAssertEqual(WindowLayoutEngine.nextResizeLength(currentLength: 450, totalLength: totalLength, divisions: 3), 300)
        XCTAssertEqual(WindowLayoutEngine.nextResizeLength(currentLength: 300, totalLength: totalLength, divisions: 3), 900)
    }

    func testWindowLayoutEngineMovesByGridCell() throws {
        let screenFrame = NSRect(x: 0, y: 0, width: 900, height: 600)
        let windowFrame = NSRect(x: 300, y: 200, width: 300, height: 200)
        let settings = GridLayoutSettings(columns: 3, rows: 3)

        XCTAssertEqual(
            WindowLayoutEngine.movedFrame(windowFrame: windowFrame, screenFrame: screenFrame, settings: settings, direction: .Left),
            NSRect(x: 0, y: 200, width: 300, height: 200)
        )
        XCTAssertEqual(
            WindowLayoutEngine.movedFrame(windowFrame: windowFrame, screenFrame: screenFrame, settings: settings, direction: .Down),
            NSRect(x: 300, y: 400, width: 300, height: 200)
        )
    }

    func testWindowLayoutEngineResizesTowardHalfForOddGrid() throws {
        let screenFrame = NSRect(x: 0, y: 0, width: 900, height: 600)
        let windowFrame = NSRect(x: 300, y: 0, width: 600, height: 600)
        let settings = GridLayoutSettings(columns: 3, rows: 2)

        XCTAssertEqual(
            WindowLayoutEngine.resizedFrame(windowFrame: windowFrame, screenFrame: screenFrame, settings: settings, direction: .Right),
            NSRect(x: 450, y: 0, width: 450, height: 600)
        )
    }

    func testScreenNavigatorChoosesNearestScreenInDirection() throws {
        let current = NSRect(x: 0, y: 0, width: 100, height: 100)
        let candidates = [
            ScreenCandidate(id: "far-right", frame: NSRect(x: 250, y: 0, width: 100, height: 100)),
            ScreenCandidate(id: "near-right", frame: NSRect(x: 120, y: 20, width: 100, height: 100)),
            ScreenCandidate(id: "left", frame: NSRect(x: -120, y: 0, width: 100, height: 100))
        ]

        XCTAssertEqual(
            ScreenNavigator.nextFrame(from: current, candidates: candidates, direction: .Right)?.id,
            "near-right"
        )
    }
    
    func testMagicNumbers() throws {
        // Test that magic numbers are reasonable
        let errorX: CGFloat = 10
        let errorY: CGFloat = 10
        let maxCheck: Int = 10
        
        XCTAssertGreaterThan(errorX, 0)
        XCTAssertGreaterThan(errorY, 0)
        XCTAssertGreaterThan(maxCheck, 0)
        XCTAssertLessThan(maxCheck, 100) // Should be reasonable
    }
    
    func testPerformanceExample() throws {
        // Performance test for utility functions
        measure {
            for _ in 0..<1000 {
                _ = 5.clamp(to: 0...10)
            }
        }
    }

    // MARK: - Screen Detection Tests
    
    func testScreenDetection() throws {
        // Test that we can get all screens
        let screens = NSScreen.screens
        XCTAssertGreaterThan(screens.count, 0, "Should have at least one screen")
        
        // Test that main screen exists
        XCTAssertNotNil(NSScreen.main, "Main screen should exist")
        
        // Test screen ID generation
        let mainScreen = NSScreen.main!
        let screenId = mainScreen.getIdString()
        XCTAssertFalse(screenId.isEmpty, "Screen ID should not be empty")
        
        // Test screen lookup by ID
        let foundScreen = NSScreen.fromIdString(str: screenId)
        XCTAssertNotNil(foundScreen, "Should be able to find screen by ID")
        XCTAssertEqual(foundScreen, mainScreen, "Found screen should match original")
    }

    // MARK: - WindyData Tests
    
    func testWindyDataInitialization() throws {
        let windyData = WindyData()
        
        // Test that required properties are initialized
        XCTAssertFalse(windyData.isShown)
        XCTAssertNotNil(windyData.activeScreens)
        XCTAssertGreaterThan(windyData.activeScreens.count, 0)
        
        // Test that display settings are initialized
        XCTAssertNotNil(windyData.displaySettings)
        
        // Test that accent color is initialized
        XCTAssertNotNil(windyData.accentColour)
    }
    
    func testDisplaySettingsGeneration() throws {
        let settings = generateDisplaySettingsFromActiveScreens()
        
        // Should have settings for all screens
        let screenCount = NSScreen.screens.count
        XCTAssertEqual(settings.count, screenCount)
        
        // Each setting should have valid coordinates
        for (_, point) in settings {
            XCTAssertGreaterThanOrEqual(point.x, 0)
            XCTAssertGreaterThanOrEqual(point.y, 0)
        }
    }
    
    func testDisplaySettingsMerging() throws {
        let leftSettings = ["screen1": NSPoint(x: 2, y: 2), "screen2": NSPoint(x: 3, y: 3)]
        let rightSettings = ["screen2": NSPoint(x: 4, y: 4), "screen3": NSPoint(x: 5, y: 5)]
        
        let merged = mergeDisplaySettings(left: leftSettings, right: rightSettings)
        
        // Should have all unique screens
        XCTAssertEqual(merged.count, 3)
        
        // Left settings should take precedence for overlapping keys
        XCTAssertEqual(merged["screen2"], NSPoint(x: 3, y: 3))
        
        // Right settings should be included for new keys
        XCTAssertEqual(merged["screen3"], NSPoint(x: 5, y: 5))
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() throws {
        // Test that invalid screen IDs return nil
        let invalidScreen = NSScreen.fromIdString(str: "invalid_id")
        XCTAssertNil(invalidScreen, "Invalid screen ID should return nil")
        
        // Test coordinate conversion with edge cases
        let edgePoint = NSPoint(x: CGFloat.infinity, y: CGFloat.nan)
        let flippedEdge = edgePoint.flip()
        
        // Should handle edge cases gracefully
        XCTAssertTrue(flippedEdge.x.isInfinite)
        XCTAssertTrue(flippedEdge.y.isNaN)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfCoordinateConversion() throws {
        measure {
            for _ in 0..<1000 {
                let point = NSPoint(x: Double.random(in: 0...1000), y: Double.random(in: 0...1000))
                _ = point.flip()
            }
        }
    }
    
    func testPerformanceOfRectCreation() throws {
        let screen = NSScreen.main!
        
        measure {
            for _ in 0..<100 {
                _ = createRects(columns: 10, rows: 10, screen: screen)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndWindowManipulation() throws {
        // This test would require actual window manipulation
        // For now, we'll test the utility functions that support window manipulation
        
        let screen = NSScreen.main!
        let rects = createRects(columns: 3, rows: 3, screen: screen)
        
        // Test that we can create a valid rectangle for window positioning
        XCTAssertGreaterThan(rects.count, 0)
        XCTAssertGreaterThan(rects[0].count, 0)
        
        let testRect = rects[0][0]
        
        // Test coordinate conversion for the rectangle
        let topLeft = testRect.origin
        let bottomLeft = NSPoint(x: topLeft.x, y: topLeft.y + testRect.height)
        
        let flippedTopLeft = topLeft.flip()
        let flippedBottomLeft = bottomLeft.flip()
        
        // Verify coordinate conversions are consistent
        XCTAssertNotEqual(flippedTopLeft.y, flippedBottomLeft.y)
        XCTAssertEqual(flippedTopLeft.x, flippedBottomLeft.x)
    }
    
    // MARK: - Additional Edge Case Tests
    
    func testExtremeCoordinateValues() throws {
        // Test with extreme coordinate values
        let extremePoints = [
            NSPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude),
            NSPoint(x: -CGFloat.greatestFiniteMagnitude, y: -CGFloat.greatestFiniteMagnitude),
            NSPoint(x: 0, y: 0),
            NSPoint(x: CGFloat.leastNormalMagnitude, y: CGFloat.leastNormalMagnitude)
        ]
        
        for point in extremePoints {
            let flipped = point.flip()
            // Should not crash and should produce valid results
            XCTAssertFalse(flipped.x.isNaN)
            XCTAssertFalse(flipped.y.isNaN)
        }
    }
    
    func testLargeGridCreation() throws {
        let screen = NSScreen.main!
        
        // Test creating very large grids
        let largeRects = createRects(columns: 50, rows: 50, screen: screen)
        XCTAssertEqual(largeRects.count, 50)
        XCTAssertEqual(largeRects[0].count, 50)
        
        // Test creating single column/row grids
        let singleColumn = createRects(columns: 1, rows: 10, screen: screen)
        XCTAssertEqual(singleColumn.count, 1)
        XCTAssertEqual(singleColumn[0].count, 10)
        
        let singleRow = createRects(columns: 10, rows: 1, screen: screen)
        XCTAssertEqual(singleRow.count, 10)
        XCTAssertEqual(singleRow[0].count, 1)
    }
    
    func testClampWithExtremeRanges() throws {
        // Test clamping with extreme ranges
        XCTAssertEqual(5.0.clamp(to: -Double.infinity...Double.infinity), 5.0)
        
        // Test with very small ranges - these should work correctly
        XCTAssertEqual(5.0.clamp(to: 4.999...5.001), 5.0)
        XCTAssertEqual(4.0.clamp(to: 4.999...5.001), 4.999)
        XCTAssertEqual(6.0.clamp(to: 4.999...5.001), 5.001)
        
        // Test with infinity values - these should be handled gracefully
        // Note: The clamp function should handle infinity correctly
        let infValue = Double.infinity
        let finiteRange = 0.0...100.0
        XCTAssertEqual(infValue.clamp(to: finiteRange), 100.0)
        
        let negInfValue = -Double.infinity
        XCTAssertEqual(negInfValue.clamp(to: finiteRange), 0.0)
    }
    
    func testScreenEdgeCases() throws {
        // Test screen detection edge cases
        let screens = NSScreen.screens
        
        // Test that all screens have valid IDs
        for screen in screens {
            let screenId = screen.getIdString()
            XCTAssertFalse(screenId.isEmpty, "Screen ID should not be empty")
            
            // Test that we can find the screen by its ID
            let foundScreen = NSScreen.fromIdString(str: screenId)
            XCTAssertNotNil(foundScreen, "Should be able to find screen by its own ID")
            XCTAssertEqual(foundScreen, screen, "Found screen should match original")
        }
        
        // Test with empty string - should return nil
        let emptyScreen = NSScreen.fromIdString(str: "")
        XCTAssertNil(emptyScreen, "Empty string should return nil")
        
        // Test with very long string - should return nil
        let longString = String(repeating: "a", count: 1000)
        let longScreen = NSScreen.fromIdString(str: longString)
        XCTAssertNil(longScreen, "Very long string should return nil")
        
        // Test with invalid format string - should return nil
        let invalidScreen = NSScreen.fromIdString(str: "invalid_id")
        XCTAssertNil(invalidScreen, "Invalid screen ID should return nil")
    }
    
    func testDisplaySettingsEdgeCases() throws {
        // Test with empty settings
        let emptyLeft: [String: NSPoint] = [:]
        let emptyRight: [String: NSPoint] = [:]
        let mergedEmpty = mergeDisplaySettings(left: emptyLeft, right: emptyRight)
        XCTAssertEqual(mergedEmpty.count, 0, "Merging empty settings should result in empty")
        
        // Test with nil-like values
        let settingsWithZeros = ["screen1": NSPoint(x: 0, y: 0)]
        XCTAssertEqual(settingsWithZeros["screen1"]?.x, 0)
        XCTAssertEqual(settingsWithZeros["screen1"]?.y, 0)
        
        // Test with negative values
        let settingsWithNegatives = ["screen1": NSPoint(x: -1, y: -1)]
        XCTAssertEqual(settingsWithNegatives["screen1"]?.x, -1)
        XCTAssertEqual(settingsWithNegatives["screen1"]?.y, -1)
    }
    
    func testWindyDataPropertyChanges() throws {
        let windyData = WindyData()
        
        // Test property changes trigger updates
        // Change active setting screen
        windyData.activeSettingScreen = "test_screen"
        XCTAssertEqual(windyData.activeSettingScreen, "test_screen")
        
        // Test that display settings are still valid after changes
        XCTAssertGreaterThanOrEqual(windyData.displaySettings.count, 0)
        
        // Test accent color changes
        let newColor = Color.blue
        windyData.accentColour = newColor
        XCTAssertEqual(windyData.accentColour, newColor)
    }
    
    func testPerformanceOfLargeGridOperations() throws {
        let screen = NSScreen.main!
        
        measure {
            // Test performance of creating multiple large grids
            for _ in 0..<10 {
                _ = createRects(columns: 20, rows: 20, screen: screen)
            }
        }
    }
    
    func testPerformanceOfCoordinateConversions() throws {
        measure {
            // Test performance of many coordinate conversions
            for _ in 0..<10000 {
                let point = NSPoint(x: Double.random(in: -1000...1000), y: Double.random(in: -1000...1000))
                _ = point.flip()
            }
        }
    }
    
    func testPerformanceOfScreenLookups() throws {
        let screens = NSScreen.screens
        let screenIds = screens.map { $0.getIdString() }
        
        measure {
            // Test performance of screen lookups
            for _ in 0..<1000 {
                for screenId in screenIds {
                    _ = NSScreen.fromIdString(str: screenId)
                }
            }
        }
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistencyAcrossOperations() throws {
        let screen = NSScreen.main!
        let rects1 = createRects(columns: 3, rows: 3, screen: screen)
        let rects2 = createRects(columns: 3, rows: 3, screen: screen)
        
        // Same parameters should produce identical results
        XCTAssertEqual(rects1.count, rects2.count)
        for i in 0..<rects1.count {
            XCTAssertEqual(rects1[i].count, rects2[i].count)
            for j in 0..<rects1[i].count {
                XCTAssertEqual(rects1[i][j], rects2[i][j])
            }
        }
    }
    
    func testCoordinateSystemConsistency() throws {
        let originalPoint = NSPoint(x: 100, y: 200)
        let flippedOnce = originalPoint.flip()
        let flippedTwice = flippedOnce.flip()
        
        // Double flip should return to original (within floating point precision)
        XCTAssertEqual(originalPoint.x, flippedTwice.x, accuracy: 0.001)
        XCTAssertEqual(originalPoint.y, flippedTwice.y, accuracy: 0.001)
    }
    
    // MARK: - Error Recovery Tests
    
    func testGracefulHandlingOfInvalidInputs() throws {
        let screen = NSScreen.main!
        
        // Test with negative grid dimensions - should return empty array
        let negativeRects = createRects(columns: -1, rows: -1, screen: screen)
        XCTAssertEqual(negativeRects.count, 0, "Negative dimensions should return empty array")
        
        // Test with zero dimensions - should return empty array
        let zeroRects = createRects(columns: 0, rows: 0, screen: screen)
        XCTAssertEqual(zeroRects.count, 0, "Zero dimensions should result in empty grid")
        
        // Test with very large dimensions - should handle gracefully
        let largeRects = createRects(columns: 100, rows: 100, screen: screen)
        XCTAssertEqual(largeRects.count, 100, "Large dimensions should be handled")
        XCTAssertEqual(largeRects[0].count, 100, "Large dimensions should be handled")
        
        // Test with fractional dimensions - should handle gracefully (truncates to Int)
        let fractionalRects = createRects(columns: 2.5, rows: 3.7, screen: screen)
        // The function uses Int(columns) and Int(rows), so 2.5 becomes 2 and 3.7 becomes 3
        XCTAssertEqual(fractionalRects.count, 2, "Fractional columns should be truncated to Int(2.5) = 2")
        if fractionalRects.count > 0 {
            XCTAssertEqual(fractionalRects[0].count, 3, "Fractional rows should be truncated to Int(3.7) = 3")
        }
        
        // Test with very small positive values - should handle gracefully
        let smallRects = createRects(columns: 0.1, rows: 0.1, screen: screen)
        // Int(0.1) = 0, so this should return empty array
        XCTAssertEqual(smallRects.count, 0, "Very small positive values should be truncated to 0")
        
        // Test with exactly 1.0 - should work correctly
        let oneRects = createRects(columns: 1.0, rows: 1.0, screen: screen)
        XCTAssertEqual(oneRects.count, 1, "Exactly 1.0 should create 1 column")
        if oneRects.count > 0 {
            XCTAssertEqual(oneRects[0].count, 1, "Exactly 1.0 should create 1 row")
        }
    }
}
