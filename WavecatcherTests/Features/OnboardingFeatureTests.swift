//
//  OnboardingFeatureTests.swift
//  WavecatcherTests
//

import XCTest
import ComposableArchitecture
@testable import Wavecatcher

@MainActor
final class OnboardingFeatureTests: XCTestCase {
    
    func testShowAddLocationsButtonAfterScrollToGetStartedPage() async {
        
        let store = TestStore(initialState: OnboardingFeature.State.firstLaunchState) {
            OnboardingFeature()
        }
        
        await store.send(.selectPage(.welcome))
        await store.send(.selectPage(.getStarted)) {
            $0.addLocationsButtonVisible = true
        }
        await store.send(.selectPage(.welcome))
    }
}
