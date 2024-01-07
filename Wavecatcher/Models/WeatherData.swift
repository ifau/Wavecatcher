//
//  WeatherData.swift
//  Wavecatcher
//

import Foundation
import Tagged

struct WeatherData: Equatable, Codable {
    
    let date: Date
    
    let airTemperature: Double?
    let windDirection: Double?
    let windSpeed: Double?
    let windGust: Double?
    
    let swellDirection: Double?
    let swellPeriod: Double?
    let swellHeight: Double?
    
    let tideHeight: Double?
    let waveHeight: Double?
    
    init(date: Date,
         airTemperature: Double? = nil,
         windDirection: Double? = nil,
         windSpeed: Double? = nil,
         windGust: Double? = nil,
         swellDirection: Double? = nil,
         swellPeriod: Double? = nil,
         swellHeight: Double? = nil,
         tideHeight: Double? = nil,
         waveHeight: Double? = nil) {
        self.date = date
        self.airTemperature = airTemperature
        self.windDirection = windDirection
        self.windSpeed = windSpeed
        self.windGust = windGust
        self.swellDirection = swellDirection
        self.swellPeriod = swellPeriod
        self.swellHeight = swellHeight
        self.tideHeight = tideHeight
        self.waveHeight = waveHeight
    }
}

extension WeatherData {
    
    static let previewData: [WeatherData] = {
        let startOfTheDay = Calendar.current.nextDate(after: .now, matching: .init(hour: 0, minute: 0, second: 0), matchingPolicy: .previousTimePreservingSmallerComponents, direction: .backward)!
        
        return (0...48).map { index in
            WeatherData(date: Date(timeInterval: 60*60*Double(index), since: startOfTheDay),
                        airTemperature: Double.random(in: 24...32),
                        windDirection: Double.random(in: 0...359),
                        windSpeed: Double.random(in: 5...25),
                        windGust: Double.random(in: 25...27),
                        swellDirection: Double.random(in: 0...359),
                        swellPeriod: Double.random(in: 8...15),
                        swellHeight: Double.random(in: 1...2.5),
                        tideHeight: Double.random(in: 0.5...3.0),
                        waveHeight: Double.random(in: 1...2.5))
        }
    }()
}
