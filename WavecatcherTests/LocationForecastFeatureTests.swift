//
//  LocationForecastFeatureTests.swift
//  WavecatcherTests
//

import XCTest
import ComposableArchitecture
@testable import Wavecatcher

@MainActor
final class LocationForecastFeatureTests: XCTestCase {
    
    func testRequestWeatherAfterViewAppear() async {
        
        let state = LocationForecastFeature.State(location: SavedLocation.previewData.first!)
        let store = TestStore(initialState: state) {
            LocationForecastFeature()
        } withDependencies: {
            $0.weatherDataProvider.needUpdateWeatherForLocation = { _ in return true }
            $0.weatherDataProvider.updateWeatherDataForLocation = { _ in return }
        }
        
        await store.send(.viewAppear)
        await store.receive(.updateWeather) {
            $0.displayState = .loading
        }
        await store.receive(.updateWeatherComplete(.success(.init()))) {
            $0.displayState = .loaded
        }
    }
    
    func testNotRequestWeatherAfterViewAppear() async {
        
        let state = LocationForecastFeature.State(location: SavedLocation.previewData.first!)
        let store = TestStore(initialState: state) {
            LocationForecastFeature()
        } withDependencies: {
            $0.weatherDataProvider.needUpdateWeatherForLocation = { _ in return false }
            $0.weatherDataProvider.updateWeatherDataForLocation = { _ in return }
        }
        
        await store.send(.viewAppear)
    }
    
    func testRequestWeatherAndDisplayErrorAfterTryAgainButtonPressed() async {
        
        let connectionError = URLError(URLError.notConnectedToInternet)
        
        let state = LocationForecastFeature.State(location: SavedLocation.previewData.first!)
        let store = TestStore(initialState: state) {
            LocationForecastFeature()
        } withDependencies: {
            $0.weatherDataProvider.updateWeatherDataForLocation = { _ in throw connectionError }
        }
        
        await store.send(.tryAgainButtonPressed) {
            $0.displayState = .loading
        }
        await store.receive(.updateWeatherComplete(.failure(connectionError))) {
            $0.displayState = .failed(connectionError)
        }
    }
}
