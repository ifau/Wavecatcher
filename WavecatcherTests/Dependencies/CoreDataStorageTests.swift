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
        
        let location1 = Location(id: "1", latitude: 2.2, longitude: -2.2, title: "Title")
        try await storage.insertOrUpdate(location: location1)
        
        let location2 = try await storage.fetchLocations().first!
        XCTAssertEqual(location1, location2)
        
        try await storage.delete(location: location1)
        savedLocations = try await storage.fetchLocations()
        XCTAssertTrue(savedLocations.isEmpty)
    }
    
    func testFetchInsertDeleteWeatherData() async throws {
        
        let storage = CoreDataStorage(storeType: .inMemory)
        let location = Location(id: "1", latitude: 2.2, longitude: -2.2, title: "Title")
        var savedWeather = try await storage.fetchWeather(for: location)
        XCTAssertTrue(savedWeather.isEmpty)
        
        let weatherData1 = [WeatherData(locationId: location.id, date: Date(timeIntervalSince1970: 10), airTemperature: 20, windDirection: 0, windSpeed: 10, windGust: 20, swellDirection: 0, swellPeriod: 0, swellHeight: 0, tideHeight: 0)]
        
        try await storage.deleteAndInsertWeather(weatherData1, for: location)
        
        let weatherData2 = try await storage.fetchWeather(for: location)
        XCTAssertEqual(weatherData1, weatherData2)
        
        try await storage.deleteAndInsertWeather([], for: location)
        savedWeather = try await storage.fetchWeather(for: location)
        XCTAssertTrue(savedWeather.isEmpty)
    }
}
