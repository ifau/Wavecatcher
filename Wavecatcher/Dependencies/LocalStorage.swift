//
//  LocalStorage.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct LocalStorage {
    var fetchLocations: () async throws -> [Location]
    var saveLocation: (_ location: Location) async throws -> Void
    var deleteLocation: (_ location: Location) async throws -> Void
    
    var fetchWeatherForLocation: (_ location: Location) async throws -> [WeatherData]
    var saveWeatherForLocation: (_ weatherData: [WeatherData], _ location: Location) async throws -> Void
}

extension DependencyValues {
    var localStorage: LocalStorage {
        get { self[LocalStorage.self] }
        set { self[LocalStorage.self] = newValue }
    }
}

extension LocalStorage: DependencyKey {
    
    static let liveValue: LocalStorage = {
        // FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: <your_app_group>)
        let databaseFileURL = URL.documentsDirectory.appending(component: "db.sqlite")
        let coreDataStorage = CoreDataStorage(storeType: .file(databaseFileURL))
        
        return LocalStorage(fetchLocations: coreDataStorage.fetchLocations,
                            saveLocation: coreDataStorage.insertOrUpdate(location:),
                            deleteLocation: coreDataStorage.delete(location:),
                            fetchWeatherForLocation: coreDataStorage.fetchWeather(for:),
                            saveWeatherForLocation: coreDataStorage.deleteAndInsertWeather(_:for:)
        )
    }()
    
    static let testValue: LocalStorage = {
        .init(fetchLocations: unimplemented("\(Self.self).fetchLocations"),
              saveLocation: unimplemented("\(Self.self).saveLocation"),
              deleteLocation: unimplemented("\(Self.self).deleteLocation"),
              fetchWeatherForLocation: unimplemented("\(Self.self).fetchWeatherForLocation"),
              saveWeatherForLocation: unimplemented("\(Self.self).saveWeatherForLocation")
        )
    }()
}
