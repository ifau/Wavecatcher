//
//  AddLocationFeatureTests.swift
//  WavecatcherTests
//

import XCTest
import ComposableArchitecture
@testable import Wavecatcher

@MainActor
final class AddLocationFeatureTests: XCTestCase {
    
    func testLoadLocationsOnViewAppear() async {
        
        let savedLocations = SavedLocation.previewData
        let remoteLocations = Location.previewData
        
        let store = TestStore(initialState: AddLocationFeature.State.init()) {
            AddLocationFeature()
        } withDependencies: {
            $0.localStorage.fetchLocations = { return savedLocations }
            $0.locationsProvider.getAvailableLocations = { return remoteLocations }
        }
        
        await store.send(.viewAppear) {
            $0.displayState = .loading
        }
        await store.receive(.loadSavedLocationsResponse(.success(savedLocations))) {
            $0.savedLocations = .init(uniqueElements: savedLocations)
        }
        await store.receive(.loadLocationsResponse(.success(remoteLocations))) {
            $0.locations = .init(uniqueElements: remoteLocations)
            $0.displayState = .loaded
        }
    }
    
    func testSelectLocationOnTap() async {
        
        let locationId = Location.ID("1")
        
        let store = TestStore(initialState: AddLocationFeature.State.init(selectedLocationID: nil)) {
            AddLocationFeature()
        }
        
        await store.send(.locationTap(locationId)) {
            $0.selectedLocationID = locationId
        }
        await store.send(.locationTap(locationId)) {
            $0.selectedLocationID = nil
        }
    }
    
    func testSearchStateChange() async {
        
        let locationA1 = Location(id: .init("a1"), latitude: 0, longitude: 0, offshorePerpendicular: 80, title: "AAAA")
        let locationA2 = Location(id: .init("a2"), latitude: 0, longitude: 0, offshorePerpendicular: 80, title: "aaaa")
        
        let locationB1 = Location(id: .init("b1"), latitude: 0, longitude: 0, offshorePerpendicular: 80, title: "BBBB")
        let locationB2 = Location(id: .init("b2"), latitude: 0, longitude: 0, offshorePerpendicular: 80, title: "bbbb")
        
        let locationAB = Location(id: .init("ab"), latitude: 0, longitude: 0, offshorePerpendicular: 80, title: "qAbC")
        
        let allLocations: IdentifiedArrayOf<Location> = .init(uniqueElements: [locationA1, locationA2, locationB1, locationB2, locationAB])
        let store = TestStore(initialState: AddLocationFeature.State.init(locations: allLocations)) {
            AddLocationFeature()
        }
        
        await store.send(.searchStateChanged(true)) {
            $0.searchIsActive = true
        }
        XCTAssertEqual(store.state.searchResults, .init())
        
        await store.send(.searchQueryChanged("a")) {
            $0.searchQuery = "a"
        }
        XCTAssertEqual(store.state.searchResults, .init(uniqueElements: [locationA1, locationA2, locationAB]))
    }
    
    func testAddSelectedLocation() async {
        
        let nowDate = Date.now
        let location = Location(id: .init("a1"), latitude: 0, longitude: 0, offshorePerpendicular: 80, title: "AAAA")
        
        let locationToSave = SavedLocation(location: location, dateCreated: nowDate, dateUpdated: Date(timeIntervalSince1970: 0), weather: [], customOrderIndex: 0)
        
        let store = TestStore(initialState: AddLocationFeature.State.init(locations: .init(uniqueElements: [location]), selectedLocationID: location.id)) {
            AddLocationFeature()
        } withDependencies: {
            $0.date = .init({ return nowDate })
            $0.localStorage.saveLocations = { l in XCTAssertEqual(l, [locationToSave]) }
        }
        
        await store.send(.addSelectedLocation)
    }
}
