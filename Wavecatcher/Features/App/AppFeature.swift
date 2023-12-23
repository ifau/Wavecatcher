//
//  AppFeature.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct AppFeature: Reducer {
    
    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var locations: IdentifiedArrayOf<SavedLocation> = .init()
    }
    
    enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case task
        case rootViewAppear
        case reloadLocations
        case reloadLocationsResponse(TaskResult<[SavedLocation]>)
    }
    
    @Dependency(\.localStorage) var localStorage
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {                
            case .destination:
                return .none
                
            case .task:
                return .run { send in
                    for await _ in await self.localStorage.wasUpdated() {
                      await send(.reloadLocations)
                    }
                }
                
            case .rootViewAppear:
                return .run { send in
                    await send(.reloadLocations)
                }
                
            case .reloadLocations:
                return .run { send in
                    await send(.reloadLocationsResponse(
                        TaskResult { try await localStorage.fetchLocations() }
                    ))
                }.animation()
                
            case .reloadLocationsResponse(.success(let locations)):
                let hadAtLeastOneLocationBefore = !state.locations.isEmpty
                state.locations = IdentifiedArrayOf<SavedLocation>(uniqueElements: locations)
                
                if state.locations.isEmpty {
                    state.destination = .onboarding(hadAtLeastOneLocationBefore ? .secondLaunchState : .firstLaunchState)
                }
                else if case .locationsList(var locationsListState) = state.destination {
                    locationsListState.locations = state.locations
                    if let selectedLocationID = locationsListState.selectedLocationID, state.locations[id: selectedLocationID] == nil {
                        locationsListState.selectedLocationID = locations.first?.id
                    }
                    if locationsListState.selectedLocationID == nil {
                        locationsListState.selectedLocationID = locations.first?.id
                    }
                    if case .settings(var settingsState) = locationsListState.destination {
                        settingsState.locations = state.locations
                        locationsListState.destination = .settings(settingsState)
                    }
                    state.destination = .locationsList(locationsListState)
                } else {
                    state.destination = .locationsList(.init(locations: state.locations, selectedLocationID: state.locations.first?.id))
                }
                return .none
                
            case .reloadLocationsResponse(.failure):
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

extension AppFeature {
    
    struct Destination: Reducer {
        enum State: Equatable {
            case onboarding(OnboardingFeature.State)
            case locationsList(LocationsListFeature.State)
        }
        
        enum Action: Equatable {
            case onboarding(OnboardingFeature.Action)
            case locationsList(LocationsListFeature.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: /State.onboarding, action: /Action.onboarding) {
                OnboardingFeature()
            }
            Scope(state: /State.locationsList, action: /Action.locationsList) {
                LocationsListFeature()
            }
        }
    }
}
