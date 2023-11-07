//
//  WeatherDataTests.swift
//  WavecatcherTests
//

import XCTest
@testable import Wavecatcher

final class WeatherDataTests: XCTestCase {
    
    func testClosestDataTo() {
        
        let baseDate = Date(timeIntervalSince1970: 14_200_800)
        
        let second1 = Calendar.current.date(bySettingHour: 1, minute: 0, second: 1, of: baseDate)!
        let second2 = Calendar.current.date(bySettingHour: 1, minute: 0, second: 2, of: baseDate)!
        let second3 = Calendar.current.date(bySettingHour: 1, minute: 0, second: 3, of: baseDate)!
        let second4 = Calendar.current.date(bySettingHour: 1, minute: 0, second: 4, of: baseDate)!
        let second5 = Calendar.current.date(bySettingHour: 1, minute: 0, second: 5, of: baseDate)!
        
        let weather1 = WeatherData(date: second1)
        let weather2 = WeatherData(date: second2)
        let weather3 = WeatherData(date: second3)
        // let weather4 = WeatherData(date: second4)
        let weather5 = WeatherData(date: second5)
        
        XCTAssertEqual([weather1, weather2, weather3].closestData(to: second1), weather1)
        XCTAssertEqual([weather1, weather2, weather3].closestData(to: second2), weather2)
        XCTAssertEqual([weather2, weather3, weather5].closestData(to: second4), weather3)
        XCTAssertEqual([weather2, weather3, weather5].closestData(to: second5), weather5)
    }
    
    func testTodayData() {
        let today = Date.now
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let weather1 = WeatherData(date: yesterday)
        let weather2 = WeatherData(date: today)
        let weather3 = WeatherData(date: tomorrow)
        
        XCTAssertEqual([weather1, weather2, weather3].todayData(), [weather2])
    }
    
    func testDataOfNextMaximumTide() {
        do {
            let firstDate = Date.now
            let tides = [0.5, 0.8, 1.0, 1.5, 1.4, 1.3]
            let weather: [WeatherData] = tides.enumerated().map { index, value in
                let data = Calendar.current.date(byAdding: .minute, value: index, to: firstDate)!
                return WeatherData(date: data, tideHeight: value)
            }
            
            XCTAssertEqual(weather.dataOfNextMaximumTide()?.tideHeight, 1.5)
        }
        do {
            let firstDate = Date.now
            let tides = [1.5, 1.2, 1.9, 1.5, 1.4, 1.3]
            let weather: [WeatherData] = tides.enumerated().map { index, value in
                let data = Calendar.current.date(byAdding: .minute, value: index, to: firstDate)!
                return WeatherData(date: data, tideHeight: value)
            }
            
            XCTAssertEqual(weather.dataOfNextMaximumTide()?.tideHeight, 1.2)
        }
        do {
            let firstDate = Date.now
            let tides = [1.5, 1.2]
            let weather: [WeatherData] = tides.enumerated().map { index, value in
                let data = Calendar.current.date(byAdding: .minute, value: index, to: firstDate)!
                return WeatherData(date: data, tideHeight: value)
            }
            
            XCTAssertEqual(weather.dataOfNextMaximumTide()?.tideHeight, 1.2)
        }
    }
}
