//
//  SettingsFeatureTests.swift
//  WavecatcherTests
//

import XCTest
import ComposableArchitecture
@testable import Wavecatcher

@MainActor
final class SettingsFeatureTests: XCTestCase {
    
    func testChangeLocationOrder() async {
        
        let location1 = SavedLocation(location: Location(id: .init("1"), latitude: 0, longitude: 0, offshorePerpendicular: 0, title: "Location1"), dateCreated: .now, dateUpdated: .now, weather: [], customOrderIndex: 0)
        
        var location2 = SavedLocation(location: Location(id: .init("2"), latitude: 0, longitude: 0, offshorePerpendicular: 0, title: "Location2"), dateCreated: .now, dateUpdated: .now, weather: [], customOrderIndex: 1)
        
        let location3 = SavedLocation(location: Location(id: .init("3"), latitude: 0, longitude: 0, offshorePerpendicular: 0, title: "Location3"), dateCreated: .now, dateUpdated: .now, weather: [], customOrderIndex: 2)
        
        let initialLocations: IdentifiedArrayOf<SavedLocation> = .init(uniqueElements: [location1, location2, location3])
        
        var location1AfterReorder = location1
        location1AfterReorder.customOrderIndex = 1
        
        var location2AfterReorder = location2
        location2AfterReorder.customOrderIndex = 2
        
        var location3AfterReorder = location3
        location3AfterReorder.customOrderIndex = 0
        
        let reorderedLocations = [location3AfterReorder, location1AfterReorder, location2AfterReorder]
        
        let store = TestStore(initialState: SettingsFeature.State.init(locations: initialLocations)) {
            SettingsFeature()
        } withDependencies: {
            $0.localStorage.saveLocations = { locationsToSave in XCTAssertEqual(locationsToSave, reorderedLocations)}
        }
        
        await store.send(.changeLocationOrder([0], 0))
        await store.send(.changeLocationOrder([2], 0)) {
            $0.locations = .init(uniqueElements: [location3, location1, location2])
        }
    }
}
