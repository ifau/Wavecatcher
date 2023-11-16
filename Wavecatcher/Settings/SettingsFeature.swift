//
//  SettingsFeature.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct SettingsFeature: Reducer {
    
    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var locations: IdentifiedArrayOf<SavedLocation>
    }
    
    enum Action: Equatable {
        case locationTap(Location.ID)
        case changeLocationOrder(IndexSet, Int)
        case destination(PresentationAction<Destination.Action>)
    }
    
    @Dependency(\.localStorage) var localStorage
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            
            switch action {
            case .locationTap(let locationId):
                if let location = state.locations[id: locationId] {
                    state.destination = .locationSettings(.init(location: location, selectedBackground: location.customBackground))
                }
                return .none
                
            case .changeLocationOrder(var source, var destination):
                source = IndexSet(source
                    .map { state.locations[$0] }
                    .compactMap { state.locations.index(id: $0.id) }
                )
                destination = (destination < state.locations.endIndex
                    ? state.locations.index(id: state.locations[destination].id)
                    : state.locations.endIndex)
                ?? destination
                
                let oldLocations = state.locations
                state.locations.move(fromOffsets: source, toOffset: destination)
                guard oldLocations != state.locations else { return .none }
                
                return .run { [locations = state.locations] send in
                    let updatedLocations = locations.enumerated().map { index, location -> SavedLocation in
                        var mutableLocation = location
                        mutableLocation.customOrderIndex = index
                        return mutableLocation
                    }
                    
                    try? await localStorage.saveLocations(updatedLocations)
                }
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

extension SettingsFeature {
    
    struct Destination: Reducer {
        enum State: Equatable {
            case locationSettings(LocationSettingsFeature.State)
        }
        
        enum Action: Equatable {
            case locationSettings(LocationSettingsFeature.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: /State.locationSettings, action: /Action.locationSettings) {
                LocationSettingsFeature()
            }
        }
    }
}
