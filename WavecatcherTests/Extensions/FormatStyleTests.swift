//
//  FormatStyleTests.swift
//  WavecatcherTests
//

import XCTest
@testable import Wavecatcher

final class FormatStyleTests: XCTestCase {
    
    func testCardinalDirectionFormat() {
        XCTAssertEqual(  0.formatted(.cardinalDirection), "N")
        XCTAssertEqual( 23.formatted(.cardinalDirection), "NNE")
        XCTAssertEqual( 45.formatted(.cardinalDirection), "NE")
        XCTAssertEqual( 68.formatted(.cardinalDirection), "ENE")
        XCTAssertEqual( 90.formatted(.cardinalDirection), "E")
        XCTAssertEqual(113.formatted(.cardinalDirection), "ESE")
        XCTAssertEqual(135.formatted(.cardinalDirection), "SE")
        XCTAssertEqual(158.formatted(.cardinalDirection), "SSE")
        XCTAssertEqual(180.formatted(.cardinalDirection), "S")
        XCTAssertEqual(202.formatted(.cardinalDirection), "SSW")
        XCTAssertEqual(225.formatted(.cardinalDirection), "SW")
        XCTAssertEqual(248.formatted(.cardinalDirection), "WSW")
        XCTAssertEqual(270.formatted(.cardinalDirection), "W")
        XCTAssertEqual(292.formatted(.cardinalDirection), "WNW")
        XCTAssertEqual(315.formatted(.cardinalDirection), "NW")
        XCTAssertEqual(338.formatted(.cardinalDirection), "NNW")
    }
    
    func testCoordinatesFormat() {
        let precision = 5
        XCTAssertEqual(0.formatted(.coordinates(precision: precision)), "0.00000")
        XCTAssertEqual(8.48776.formatted(.coordinates(precision: precision)), "8.48776")
        XCTAssertEqual((-8.48776).formatted(.coordinates(precision: precision)), "-8.48776")
        XCTAssertEqual(8.487767777777.formatted(.coordinates(precision: precision)), "8.48776")
    }
}
