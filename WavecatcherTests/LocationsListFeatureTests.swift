//
//  LocationsListFeatureTests.swift
//  WavecatcherTests
//

import XCTest
import ComposableArchitecture
@testable import Wavecatcher

@MainActor
final class LocationsListFeatureTests: XCTestCase {
    
    func testSubscribeToStoreChangesOnViewAppear() async {
        
        let (wasUpdated, updateStorage) = AsyncStream.makeStream(of: Void.self)
        let fetchLocationsResponse = SavedLocation.previewData
        
        let store = TestStore(initialState: LocationsListFeature.State.init()) {
            LocationsListFeature()
        } withDependencies: {
            $0.localStorage.fetchLocations = { return fetchLocationsResponse }
            $0.localStorage.wasUpdated = { wasUpdated }
        }
        
        let task = await store.send(.task)
        
        updateStorage.yield()
        await store.receive(.reloadLocations)
        await store.receive(.reloadLocationsResponse(.success(fetchLocationsResponse))) {
            $0.locations = .init(uniqueElements: fetchLocationsResponse)
            $0.selectedLocationID = fetchLocationsResponse.first?.id
        }
        
        await task.cancel()
        updateStorage.yield()
    }
    
    func testDeleteSelectedLocation() async {
        
        let location = SavedLocation.previewData.first!
        
        let store = TestStore(initialState: LocationsListFeature.State.init(
            locations: .init(uniqueElements: [location]), selectedLocationID: location.id)) {
            LocationsListFeature()
        } withDependencies: {
            $0.localStorage.deleteLocation = { _ in }
        }
        
        await store.send(.deleteSelectedLocation) {
            $0.locations = .init()
            $0.selectedLocationID = nil
        }
    }
    
    func testSelectLocation() async {
        
        let location = SavedLocation.previewData.first!
        
        let store = TestStore(initialState: LocationsListFeature.State.init(
            locations: .init(uniqueElements: [location]), selectedLocationID: nil)) {
            LocationsListFeature()
        }
        
        await store.send(.selectLocation(location.id)) {
            $0.selectedLocationID = location.id
        }
    }
}
