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
}

extension WeatherData {
    
    static let previewData: [WeatherData] = {
        (0...23).map { index in
            WeatherData(date: Date(timeIntervalSinceNow: 60*60*Double(index)),
                        airTemperature: Double.random(in: 24...32),
                        windDirection: Double.random(in: 0...359),
                        windSpeed: Double.random(in: 5...25),
                        windGust: Double.random(in: 25...27),
                        swellDirection: Double.random(in: 0...359),
                        swellPeriod: Double.random(in: 8...15),
                        swellHeight: Double.random(in: 1...2.5),
                        tideHeight: Double.random(in: 0.5...3.0))
        }
    }()
}
