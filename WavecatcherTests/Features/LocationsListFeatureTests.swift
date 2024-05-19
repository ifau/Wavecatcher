//
//  LocationsListFeatureTests.swift
//  WavecatcherTests
//

import XCTest
import ComposableArchitecture
@testable import Wavecatcher

@MainActor
final class LocationsListFeatureTests: XCTestCase {
    
    func testDeleteSelectedLocation() async {
        
        let location = SavedLocation.previewData.first!
        var requestedLocationIdToDelete: Location.ID? = nil
        
        let store = TestStore(initialState: LocationsListFeature.State.init(
            locationForecasts: .init(uniqueElements: [LocationForecastFeature.State(location: location)]), selectedLocationID: location.id)) {
            LocationsListFeature()
        } withDependencies: {
            $0.localStorage.deleteLocation = { requestedLocationIdToDelete = $0.id }
        }
        
        await store.send(.deleteSelectedLocation)
        XCTAssertEqual(requestedLocationIdToDelete, location.id)
    }
    
    func testSelectLocation() async {
        
        let location = SavedLocation.previewData.first!
        
        let store = TestStore(initialState: LocationsListFeature.State.init(
            locationForecasts: .init(uniqueElements: [LocationForecastFeature.State(location: location)]), selectedLocationID: nil)) {
            LocationsListFeature()
        }
        
        await store.send(.selectLocation(location.id)) {
            $0.selectedLocationID = location.id
        }
    }
}
