//
//  CoreDataStorageTests.swift
//  WavecatcherTests
//

import XCTest

@testable import Wavecatcher
final class CoreDataStorageTests: XCTestCase {
    
    func testFetchInsertDeleteLocations() async throws {
        
        let storage = CoreDataStorage(storeType: .inMemory)
        var savedLocations = try await storage.fetchLocations()
        XCTAssertTrue(savedLocations.isEmpty)
        
        let location1 = Location(id: "1", latitude: 2.2, longitude: -2.2, offshorePerpendicular: 80, title: "Title")
        
        let weather1 = [WeatherData(date: Date(timeIntervalSince1970: 850), airTemperature: 10, windDirection: 10, windSpeed: 10, windGust: 10, swellDirection: 10, swellPeriod: 10, swellHeight: 10, tideHeight: 10)]
        
        let savedLocation1 = SavedLocation(location: location1, dateCreated: Date(timeIntervalSince1970: 100), dateUpdated: Date(timeIntervalSince1970: 100*500), weather: weather1)
        
        try await storage.insertOrUpdate(savedLocation: savedLocation1)
        
        let savedLocation2 = try await storage.fetchLocations().first!
        XCTAssertEqual(savedLocation1, savedLocation2)
        
        try await storage.delete(savedLocation: savedLocation1)
        savedLocations = try await storage.fetchLocations()
        XCTAssertTrue(savedLocations.isEmpty)
    }
}
