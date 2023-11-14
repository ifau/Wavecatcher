//
//  LocationsListFeature.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct LocationsListFeature: Reducer {
    
    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var locations: IdentifiedArrayOf<SavedLocation> = .init()
        var selectedLocationID: SavedLocation.ID? = nil
    }
    
    enum Action: Equatable {
        case task
        case viewAppear
        case reloadLocations
        case reloadLocationsResponse(TaskResult<[SavedLocation]>)
        case selectLocation(SavedLocation.ID?)
        case deleteSelectedLocation
        case addLocation
        case openSettings
        case destination(PresentationAction<Destination.Action>)
    }
    
    @Dependency(\.localStorage) var localStorage
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    for await _ in await self.localStorage.wasUpdated() {
                      await send(.reloadLocations)
                    }
                }
                
            case .viewAppear:
                return .run { send in
                    await send(.reloadLocations)
                }
                
            case .reloadLocations:
                return .run { send in
                    await send(.reloadLocationsResponse(
                        TaskResult { try await localStorage.fetchLocations() }
                    ))
                }
                
            case .reloadLocationsResponse(.success(let locations)):
                state.locations = IdentifiedArrayOf<SavedLocation>(uniqueElements: locations)
                if state.selectedLocationID == nil {
                    state.selectedLocationID = locations.first?.id
                }
                if let selectedLocationID = state.selectedLocationID, state.locations[id: selectedLocationID] == nil {
                    state.selectedLocationID = locations.first?.id
                }
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
                state.destination = .addLocation(.init())
                return .none
                
            case .openSettings:
                state.destination = .settings(.init(locations: state.locations))
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

extension LocationsListFeature {
    
    struct Destination: Reducer {
        enum State: Equatable {
            case settings(SettingsFeature.State)
            case addLocation(AddLocationFeature.State)
        }
        
        enum Action: Equatable {
            case settings(SettingsFeature.Action)
            case addLocation(AddLocationFeature.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: /State.settings, action: /Action.settings) {
                SettingsFeature()
            }
            Scope(state: /State.addLocation, action: /Action.addLocation) {
                AddLocationFeature()
            }
        }
    }
}
