//
//  WeatherDataProvider.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct WeatherDataProvider {
    var needUpdateWeatherForLocation: (_ location: SavedLocation) -> Bool
    var updateWeatherDataForLocation: (_ location: SavedLocation) async throws -> Void
}

extension DependencyValues {
    var weatherDataProvider: WeatherDataProvider {
        get { self[WeatherDataProvider.self] }
        set { self[WeatherDataProvider.self] = newValue }
    }
}

extension WeatherDataProvider: DependencyKey {
    
    static let liveValue: WeatherDataProvider = {
        @Dependency(\.localStorage) var localStorage
        
        return WeatherDataProvider(
            needUpdateWeatherForLocation: { location in
                guard location.weather.nowData() != nil else { return true }
                guard let tenHoursAgo = Calendar.current.date(byAdding: .hour, value: -10, to: .now) else { return true }
                return location.dateUpdated < tenHoursAgo
            },
            updateWeatherDataForLocation: { location in
            
            let openMeteoClient = OpenMeteoClient()
            let marineResponse = try await openMeteoClient.getMarineForecast(latitude: location.latitude, longitude: location.longitude)
            let forecastResponse = try await openMeteoClient.getWeatherForecast(latitude: location.latitude, longitude: location.longitude)
            
            var newWeather: [WeatherData] = []
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: marineResponse.utcOffsetSeconds)
            let maxIndex = min(marineResponse.hourly.time.count, forecastResponse.hourly.time.count)
            
            for index in 0..<maxIndex {
                guard let stringDate = marineResponse.hourly.time[safe: index], let date = dateFormatter.date(from: stringDate) else { continue }
                
                let airTemperature = forecastResponse.hourly.temperature2M[safe: index] ?? 0.0
                let windDirection = Double(forecastResponse.hourly.windDirection10M[safe: index] ?? 0)
                let windSpeed = forecastResponse.hourly.windSpeed10M[safe: index] ?? 0.0
                let windGust = forecastResponse.hourly.windGusts10M[safe: index] ?? 0.0
                let swellDirection = Double(marineResponse.hourly.swellWaveDirection[safe: index] ?? 0)
                let swellPeriod = marineResponse.hourly.swellWavePeriod[safe: index]
                let swellHeight = marineResponse.hourly.swellWaveHeight[safe: index]
                
                newWeather.append(WeatherData(date: date,
                                              airTemperature: airTemperature,
                                              windDirection: windDirection,
                                              windSpeed: windSpeed,
                                              windGust: windGust,
                                              swellDirection: swellDirection,
                                              swellPeriod: swellPeriod,
                                              swellHeight: swellHeight,
                                              tideHeight: 0.0)) // TODO: Add tide value
            }
            
            guard !newWeather.isEmpty else {
                struct EmptyResponse: Error {}
                throw EmptyResponse()
            }
            var mutableLocation = location
            mutableLocation.weather = newWeather
            mutableLocation.dateUpdated = .now
            
            try await localStorage.saveLocations([mutableLocation])
        })
    }()
}
