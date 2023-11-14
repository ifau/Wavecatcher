//
//  SettingsFeature.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct SettingsFeature: Reducer {
    
    struct State: Equatable {
        var locations: IdentifiedArrayOf<SavedLocation>
    }
    
    enum Action: Equatable {
        case changeLocationOrder(IndexSet, Int)
    }
    
    @Dependency(\.localStorage) var localStorage
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            
            switch action {
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
            }
        }
    }
}
