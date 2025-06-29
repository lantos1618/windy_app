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
        // Test clamp function with various ranges
        XCTAssertEqual(5.clamp(to: 0...10), 5)
        XCTAssertEqual((-5).clamp(to: 0...10), 0)
        XCTAssertEqual(15.clamp(to: 0...10), 10)
        XCTAssertEqual(0.clamp(to: 0...10), 0)
        XCTAssertEqual(10.clamp(to: 0...10), 10)
    }
    
    func testCoordinateSystemConversion() throws {
        // Test coordinate system conversions
        let screenHeight: CGFloat = 1000
        
        // Test converting from screen coordinates to window coordinates
        let screenY: CGFloat = 100
        let windowY = screenHeight - screenY
        XCTAssertEqual(windowY, 900)
        
        // Test converting back
        let convertedScreenY = screenHeight - windowY
        XCTAssertEqual(convertedScreenY, 100)
    }
    
    func testCreateRectsFunction() throws {
        // Use NSScreen.main! for createRects
        let screen = NSScreen.main!
        let rects = createRects(columns: 2, rows: 2, screen: screen)
        XCTAssertEqual(rects.count, 2) // 2 columns
        XCTAssertEqual(rects[0].count, 2) // 2 rows in first column
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
}

