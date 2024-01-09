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
    let waveHeightMin: Double?
    let waveHeightMax: Double?
    
    let surfRating: SurfRating
    
    init(date: Date,
         airTemperature: Double? = nil,
         windDirection: Double? = nil,
         windSpeed: Double? = nil,
         windGust: Double? = nil,
         swellDirection: Double? = nil,
         swellPeriod: Double? = nil,
         swellHeight: Double? = nil,
         tideHeight: Double? = nil,
         waveHeightMin: Double? = nil,
         waveHeightMax: Double? = nil,
         surfRating: SurfRating = .unknown) {
        self.date = date
        self.airTemperature = airTemperature
        self.windDirection = windDirection
        self.windSpeed = windSpeed
        self.windGust = windGust
        self.swellDirection = swellDirection
        self.swellPeriod = swellPeriod
        self.swellHeight = swellHeight
        self.tideHeight = tideHeight
        self.waveHeightMin = waveHeightMin
        self.waveHeightMax = waveHeightMax
        self.surfRating = surfRating
    }
}

extension WeatherData {
    enum SurfRating: Int, Codable {
        case unknown = 0
        case veryPoor = 1
        case poor = 2
        case poorToFair = 3
        case fair = 4
        case fairToGood = 5
        case good = 6
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
                        waveHeightMin: Double.random(in: 0.1...0.9),
                        waveHeightMax: Double.random(in: 1...2.5),
                        surfRating: .init(rawValue: Int.random(in: 0...6)) ?? .good)
        }
    }()
}
