//
//  LocationForecastFeature.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct LocationForecastFeature: Reducer {
    
    struct State: Equatable {
        var location: SavedLocation
        var displayState: DisplayState = .notRequested
        
        enum DisplayState: Equatable {
            case notRequested, loading, loaded, failed(Error)
        }
    }
    
    enum Action: Equatable {
        case viewAppear
        case tryAgainButtonPressed
        case updateLocationResponse(TaskResult<EquatableVoid>)
    }
    
    struct EquatableVoid: Equatable {}
    
    @Dependency(\.weatherDataProvider) var weatherDataProvider
    private enum CancelID { case updateLocationRequest }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .viewAppear, .tryAgainButtonPressed:
                if case .loading = state.displayState { return .none }
                state.displayState = .loading
                return .run { [location = state.location] send in
                    await send(.updateLocationResponse(TaskResult {
                        try await self.weatherDataProvider.updateWeatherDataForLocation(location)
                        return EquatableVoid()
                    }))
                }
                .cancellable(id: CancelID.updateLocationRequest)
                
            case .updateLocationResponse(.success):
                state.displayState = .loaded
                return .none
                
            case .updateLocationResponse(.failure(let error)):
                state.displayState = .failed(error)
                return .none
            }
        }
    }
}

func == (lhs: LocationForecastFeature.State.DisplayState, rhs: LocationForecastFeature.State.DisplayState) -> Bool {
    switch (lhs, rhs) {
    case (.notRequested, .notRequested), (.loading, .loading), (.loaded, .loaded): return true
    case (.failed(let err1), .failed(let err2)): return err1 == err2
    default: return false
    }
}
