//
//  LocationsListFeature.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct LocationsListFeature: Reducer {
    
    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var locationForecasts: IdentifiedArrayOf<LocationForecastFeature.State> = .init()
        var selectedLocationID: SavedLocation.ID? = nil
        
        var locations: IdentifiedArrayOf<SavedLocation> {
            .init(uniqueElements: locationForecasts.map({ $0.location }))
        }
    }
    
    enum Action: Equatable {
        case selectLocation(SavedLocation.ID?)
        case deleteSelectedLocation
        case addLocation
        case openSettings
        case destination(PresentationAction<Destination.Action>)
        case locationForecast(id: LocationForecastFeature.State.ID, action: LocationForecastFeature.Action)
    }
    
    @Dependency(\.localStorage) var localStorage
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {                
            case .selectLocation(let locationID):
                state.selectedLocationID = locationID
                return .none
                
            case .deleteSelectedLocation:
                guard let selectedLocationID = state.selectedLocationID else { return .none }
                guard let locationToDelete = state.locations[id: selectedLocationID] else { return .none }
                
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
                
            case .locationForecast:
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
        .forEach(\.locationForecasts, action: /Action.locationForecast) {
            LocationForecastFeature()
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
