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
                let tidesForecast = (try? await openMeteoClient.getTidesForecast(latitude: location.latitude, longitude: location.longitude, name: location.title)) ?? [:]
                let surfRatings = (try? await openMeteoClient.getSurfRating(latitude: location.latitude, longitude: location.longitude, name: location.title)) ?? [:]
                
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
                    let tideHeight = tidesForecast[Int(date.timeIntervalSince1970)] ?? 0.0
                    let waveHeight = marineResponse.hourly.waveHeight[safe: index]
                    let surfRating = surfRatings[Int(date.timeIntervalSince1970)] ?? .unknown
                    
                    newWeather.append(WeatherData(date: date,
                                                  airTemperature: airTemperature,
                                                  windDirection: windDirection,
                                                  windSpeed: windSpeed,
                                                  windGust: windGust,
                                                  swellDirection: swellDirection,
                                                  swellPeriod: swellPeriod,
                                                  swellHeight: swellHeight,
                                                  tideHeight: tideHeight,
                                                  waveHeight: waveHeight,
                                                  surfRating: surfRating))
                }
                
                let weatherDatesSet: Set<Int> = Set(newWeather.map({ Int($0.date.timeIntervalSince1970) }))
                let tideDatesSet: Set<Int> = Set(tidesForecast.keys)
                let peakTideDates = tideDatesSet.subtracting(weatherDatesSet)
                peakTideDates.forEach { timestamp in
                    let peakTideDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
                    guard let nearestWeather = newWeather.first (where:{ $0.date.timeIntervalSince(peakTideDate) > 0 }) else { return }
                    newWeather.append(WeatherData(date: peakTideDate,
                                                  airTemperature: nearestWeather.airTemperature,
                                                  windDirection: nearestWeather.windDirection,
                                                  windSpeed: nearestWeather.windSpeed,
                                                  windGust: nearestWeather.windGust,
                                                  swellDirection: nearestWeather.swellDirection,
                                                  swellPeriod: nearestWeather.swellPeriod,
                                                  swellHeight: nearestWeather.swellHeight,
                                                  tideHeight: tidesForecast[timestamp] ?? 0.0,
                                                  waveHeight: nearestWeather.waveHeight,
                                                  surfRating: nearestWeather.surfRating))
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
