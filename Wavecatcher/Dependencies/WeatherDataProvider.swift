//
//  WeatherDataProvider.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct WeatherDataProvider {
    var updateWeatherDataForLocation: (_ location: SavedLocation) async throws -> SavedLocation
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
        
        return WeatherDataProvider { location in
            // TODO: Call an API if weather data is outdated, update local data
            location
        }
    }()
}
