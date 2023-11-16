//
//  LocationSettingsFeatureTests.swift
//  WavecatcherTests
//

import XCTest
import ComposableArchitecture

import SwiftUI
import PhotosUI

@testable import Wavecatcher

@MainActor
final class LocationSettingsFeatureTests: XCTestCase {
    
    func testSelectBackground() async {
        
        let location = SavedLocation(location: Location(id: .init("1"), latitude: 0, longitude: 0, offshorePerpendicular: 0, title: "Location1"), dateCreated: .now, dateUpdated: .now, weather: [], customOrderIndex: 0, customBackground: .aurora(.variant1))
        
        let store = TestStore(initialState: LocationSettingsFeature.State.init(location: location, selectedBackground: location.customBackground, isLoadingPhotosPickerItem: false)) {
            LocationSettingsFeature()
        }
        
        await store.send(.selectBackground(location.customBackground))
        await store.send(.selectBackground(.aurora(.variant3))) {
            $0.selectedBackground = .aurora(.variant3)
        }
    }
    
    func testSelectPhotosPickerItem() async {
        
        let location = SavedLocation(location: Location(id: .init("1"), latitude: 0, longitude: 0, offshorePerpendicular: 0, title: "Location1"), dateCreated: .now, dateUpdated: .now, weather: [], customOrderIndex: 0, customBackground: .aurora(.variant1))
        
        let photosPickerItem = PhotosPickerItem(itemIdentifier: "")
        let fileName = "file.mp4"
        let loadedURL = URL(string: "file:///Users/User/Downloads/" + fileName)!
        
        let store = TestStore(initialState: LocationSettingsFeature.State.init(location: location, selectedBackground: location.customBackground, isLoadingPhotosPickerItem: false)) {
            LocationSettingsFeature()
        } withDependencies: {
            $0.photosAssetsLoader.loadPhotosPickerItem = { _ in return loadedURL }
        }
        
        await store.send(.selectPhotosPickerItem(photosPickerItem)) {
            $0.isLoadingPhotosPickerItem = true
        }
        await store.receive(.loadPhotosPickerItemComplete(.success(loadedURL))) {
            $0.isLoadingPhotosPickerItem = false
        }
        await store.receive(.selectBackground(.video(.init(fileName: fileName)))) {
            $0.selectedBackground = .video(.init(fileName: fileName))
        }
    }
    
    func testSelectPhotosPickerItemFailed() async {
        
        let location = SavedLocation(location: Location(id: .init("1"), latitude: 0, longitude: 0, offshorePerpendicular: 0, title: "Location1"), dateCreated: .now, dateUpdated: .now, weather: [], customOrderIndex: 0, customBackground: .aurora(.variant1))
        
        let photosPickerItem = PhotosPickerItem(itemIdentifier: "")
        struct LoadItemError: Error, Equatable { }
        let error = LoadItemError()
        
        let store = TestStore(initialState: LocationSettingsFeature.State.init(location: location, selectedBackground: location.customBackground, isLoadingPhotosPickerItem: false)) {
            LocationSettingsFeature()
        } withDependencies: {
            $0.photosAssetsLoader.loadPhotosPickerItem = { _ in throw error }
        }
        
        await store.send(.selectPhotosPickerItem(photosPickerItem)) {
            $0.isLoadingPhotosPickerItem = true
        }
        await store.receive(.loadPhotosPickerItemComplete(.failure(error))) {
            $0.isLoadingPhotosPickerItem = false
        }
    }
}
