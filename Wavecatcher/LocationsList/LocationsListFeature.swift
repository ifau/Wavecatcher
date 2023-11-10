//
//  LocationsListFeature.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct LocationsListFeature: Reducer {
    
    struct State: Equatable {
        var locations: IdentifiedArrayOf<SavedLocation> = .init()
        var selectedLocationID: SavedLocation.ID? = nil
    }
    
    enum Action: Equatable {
        case task
        case reloadLocations
        case reloadLocationsResponse(TaskResult<[SavedLocation]>)
        case selectLocation(SavedLocation.ID?)
        case deleteSelectedLocation
        case addLocation
        case openSettings
    }
    
    @Dependency(\.localStorage) var localStorage
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    // await send(.reloadLocations)
                    for await _ in await self.localStorage.wasUpdated() {
                      await send(.reloadLocations)
                    }
                }
                
            case .reloadLocations:
                return .run { send in
                    await send(.reloadLocationsResponse(
                        TaskResult { try await localStorage.fetchLocations() }
                    ))
                }
                
            case .reloadLocationsResponse(.success(let locations)):
                state.locations = IdentifiedArrayOf<SavedLocation>(uniqueElements: locations)
                return .none
                
            case .reloadLocationsResponse(.failure):
                return .none
                
            case .selectLocation(let locationID):
                state.selectedLocationID = locationID
                return .none
                
            case .deleteSelectedLocation:
                guard let selectedLocationID = state.selectedLocationID else { return .none }
                guard let locationToDelete = state.locations[id: selectedLocationID] else { return .none }
                
                state.locations.remove(id: selectedLocationID)
                state.selectedLocationID = state.locations.first?.id
                
                return .run { send in
                    try? await localStorage.deleteLocation(locationToDelete)
                }
                
            case .addLocation:
                return .none
                
            case .openSettings:
                return .none
            }
        }
    }
}
