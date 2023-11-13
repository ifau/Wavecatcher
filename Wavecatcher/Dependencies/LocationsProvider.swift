//
//  LocationsProvider.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct LocationsProvider {
    var getAvailableLocations: () async throws -> [Location]
}

extension DependencyValues {
    var locationsProvider: LocationsProvider {
        get { self[LocationsProvider.self] }
        set { self[LocationsProvider.self] = newValue }
    }
}

extension LocationsProvider: DependencyKey {
    
    static let liveValue: LocationsProvider = {
        
        return LocationsProvider {
            // TODO: Remove hardcoded locations, call an API instead
            return [
                Location(id: "1", latitude: -8.72, longitude: 115.17, offshorePerpendicular: 80, title: "Kuta Beach"),
                Location(id: "2", latitude: -8.82, longitude: 115.09, offshorePerpendicular: 120, title: "Uluwatu")
            ]
        }
    }()
}
