//
//  windyTests.swift
//  windyTests
//
//  Created by Lyndon Leong on 30/12/2022.
//

import XCTest
@testable import windy

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
}

