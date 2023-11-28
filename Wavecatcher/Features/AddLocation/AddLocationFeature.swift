//
//  AddLocationFeature.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct AddLocationFeature: Reducer {
    
    struct State: Equatable {
        var searchQuery = ""
        var searchIsActive = false
        var searchResults: IdentifiedArrayOf<Location> {
            guard searchIsActive else { return .init(uniqueElements: locations) }
            guard !searchQuery.isEmpty else { return .init() }
            let filteredLocations = locations.filter { $0.title.lowercased().contains(searchQuery.lowercased()) }
            return .init(uniqueElements: filteredLocations.sorted(by: { $0.title < $1.title }))
        }
        
        var locations: IdentifiedArrayOf<Location> = .init()
        var savedLocations: IdentifiedArrayOf<SavedLocation> = .init()
        var selectedLocationID: Location.ID? = nil
        
        var displayState: DisplayState = .notRequested
        var selectionMode: SelectionMode = .list
        
        enum DisplayState: Equatable {
            case notRequested, loading, loaded, failed(Error)
        }
        enum SelectionMode: Equatable {
            case list, map
        }
    }
    
    enum Action: Equatable {
        case viewAppear
        case tryAgainButtonPressed
        case loadLocationsResponse(TaskResult<[Location]>)
        case loadSavedLocationsResponse(TaskResult<[SavedLocation]>)
        
        case selectionModeChanged(State.SelectionMode)
        case searchStateChanged(Bool)
        case searchQueryChanged(String)
        case locationTap(Location.ID?)
        case addSelectedLocation
    }
    
    @Dependency(\.localStorage) var localStorage
    @Dependency(\.locationsProvider) var locationsProvider
    @Dependency(\.date) var date
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.isPresented) var isPresented
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .viewAppear, .tryAgainButtonPressed:
                if case .loading = state.displayState { return .none }
                state.displayState = .loading
                return .run { send in
                    await send(.loadSavedLocationsResponse(TaskResult {
                        try await localStorage.fetchLocations()
                    }))
                    await send(.loadLocationsResponse(TaskResult {
                        try await locationsProvider.getAvailableLocations()
                    }))
                }
            
            case .loadSavedLocationsResponse(.success(let savedLocations)):
                state.savedLocations = .init(uniqueElements: savedLocations)
                return .none
                
            case .loadSavedLocationsResponse(.failure(let error)):
                state.displayState = .failed(error)
                return .none
                
            case .loadLocationsResponse(.success(let locations)):
                state.locations = .init(uniqueElements: locations)
                state.displayState = .loaded
                return .none
                
            case .loadLocationsResponse(.failure(let error)):
                state.displayState = .failed(error)
                return .none
                
            case .selectionModeChanged(let selectionMode):
                state.selectionMode = selectionMode
                return .none
                
            case .searchStateChanged(let isActive):
                state.searchIsActive = isActive
                return .none
                
            case .searchQueryChanged(let query):
                state.searchQuery = query
                return .none
                
            case .locationTap(let locationId):
                guard let locationId else { return .none }
                guard state.savedLocations[id: locationId] == nil else { return .none }
                state.selectedLocationID = (state.selectedLocationID == locationId) ? nil : locationId
                return .none
                
            case .addSelectedLocation:
                guard let locationId = state.selectedLocationID else { return .none }
                guard let location = state.locations[id: locationId] else { return .none }
                guard state.savedLocations[id: locationId] == nil else { return .none }
                
                let orderIndex = (state.savedLocations.map { $0.customOrderIndex }.max() ?? -1) + 1
                let background = state.savedLocations.last?.customBackground ?? .aurora(.variant1)
                
                let locationToSave = SavedLocation(location: location, dateCreated: date.now, dateUpdated: Date(timeIntervalSince1970: 0), weather: [], customOrderIndex: orderIndex, customBackground: background)
                return .run { _ in
                    try await localStorage.saveLocations([locationToSave])
                    guard isPresented else { return }
                    await self.dismiss()
                }
            }
        }
    }
}

func == (lhs: AddLocationFeature.State.DisplayState, rhs: AddLocationFeature.State.DisplayState) -> Bool {
    switch (lhs, rhs) {
    case (.notRequested, .notRequested), (.loading, .loading), (.loaded, .loaded): return true
    case (.failed(let err1), .failed(let err2)): return err1 == err2
    default: return false
    }
}
