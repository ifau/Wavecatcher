//
//  AppFeatureTests.swift
//  WavecatcherTests
//

import XCTest
import ComposableArchitecture
@testable import Wavecatcher

@MainActor
final class AppFeatureTests: XCTestCase {
    
    func testSubscribeToStoreChangesOnViewAppear() async {
        
        let (wasUpdated, updateStorage) = AsyncStream.makeStream(of: Void.self)
        let fetchLocationsResponse = SavedLocation.previewData
        
        let store = TestStore(initialState: AppFeature.State.init()) {
            AppFeature()
        } withDependencies: {
            $0.localStorage.fetchLocations = { return fetchLocationsResponse }
            $0.localStorage.wasUpdated = { wasUpdated }
        }
        store.exhaustivity = .off
        
        let task = await store.send(.task)
        
        updateStorage.yield()
        await store.receive(.reloadLocations)
        await store.receive(.reloadLocationsResponse(.success(fetchLocationsResponse))) {
            $0.locations = .init(uniqueElements: fetchLocationsResponse)
        }
        
        await task.cancel()
        updateStorage.yield()
    }
    
    func testShowOnboardingIfNoLocationsSaved() async {
        
        let emptyLocationsSet: [SavedLocation] = []
        let store = TestStore(initialState: AppFeature.State.init()) {
            AppFeature()
        } withDependencies: {
            $0.localStorage.fetchLocations = { return emptyLocationsSet }
        }
        
        await store.send(.rootViewAppear)
        
        await store.receive(.reloadLocations)
        await store.receive(.reloadLocationsResponse(.success(emptyLocationsSet))) {
            $0.destination = .onboarding(.firstLaunchState)
        }
    }
    
    func testShowLocationsListIfAtLeastOneLocationSaved() async {
        
        let locations = SavedLocation.previewData
        let store = TestStore(initialState: AppFeature.State.init()) {
            AppFeature()
        } withDependencies: {
            $0.localStorage.fetchLocations = { return locations }
        }
        
        await store.send(.rootViewAppear)
        
        await store.receive(.reloadLocations)
        await store.receive(.reloadLocationsResponse(.success(locations))) {
            $0.locations = .init(uniqueElements: locations)
            $0.destination = .locationsList(.init(locations: $0.locations, selectedLocationID: locations.first?.id))
        }
    }
}
