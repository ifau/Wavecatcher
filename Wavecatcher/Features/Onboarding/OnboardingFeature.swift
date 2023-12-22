//
//  OnboardingFeature.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct OnboardingFeature: Reducer {
    
    struct State: Equatable {
        var visiblePages: [OnboardingPage]
        var selectedPage: OnboardingPage
        var addLocationsButtonVisible: Bool
        @PresentationState var destination: Destination.State?
        
        enum OnboardingPage: Equatable, Hashable { case welcome, getStarted }
        static var firstLaunchState: State {
            .init(visiblePages: [.welcome, .getStarted], selectedPage: .welcome, addLocationsButtonVisible: false)
        }
        static var secondLaunchState: State {
            .init(visiblePages: [.getStarted], selectedPage: .getStarted, addLocationsButtonVisible: true)
        }
    }
    
    enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case selectPage(State.OnboardingPage)
        case addLocation
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
                
            case .selectPage(let page):
                state.selectedPage = page
                if case .getStarted = page {
                    state.addLocationsButtonVisible = true
                }
                return .none
                
            case .addLocation:
                state.destination = .addLocation(.init())
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

extension OnboardingFeature {
    
    struct Destination: Reducer {
        enum State: Equatable {
            case addLocation(AddLocationFeature.State)
        }
        
        enum Action: Equatable {
            case addLocation(AddLocationFeature.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: /State.addLocation, action: /Action.addLocation) {
                AddLocationFeature()
            }
        }
    }
}
