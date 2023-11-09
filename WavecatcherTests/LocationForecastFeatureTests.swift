//
//  LocationForecastFeatureTests.swift
//  WavecatcherTests
//

import XCTest
import ComposableArchitecture
@testable import Wavecatcher

@MainActor
final class LocationForecastFeatureTests: XCTestCase {
    
    func testRequestWeatherAndDisplayDataAfterViewAppear() async {
        
        let initialLocation = SavedLocation.previewData.first!
        var updatedLocation = SavedLocation.previewData.first!
        updatedLocation.weather = [WeatherData(date: Date(timeIntervalSince1970: 10), airTemperature: 20)]
        
        let state = LocationForecastFeature.State(location: SavedLocation.previewData.first!, displayState: .notRequested)
        let store = TestStore(initialState: state) {
            LocationForecastFeature()
        } withDependencies: {
            $0.weatherDataProvider.updateWeatherDataForLocation = { _ in return updatedLocation }
        }
        
        await store.send(.viewAppear) {
            $0.displayState = .loading
        }
        await store.receive(.updateLocationResponse(.success(updatedLocation))) {
            $0.displayState = .loaded
            $0.location = updatedLocation
        }
    }
    
    func testRequestWeatherAndDisplayErrorAfterTryAgainButtonPressed() async {
        
        let connectionError = URLError(URLError.notConnectedToInternet)
        
        let state = LocationForecastFeature.State(location: SavedLocation.previewData.first!, displayState: .notRequested)
        let store = TestStore(initialState: state) {
            LocationForecastFeature()
        } withDependencies: {
            $0.weatherDataProvider.updateWeatherDataForLocation = { _ in throw connectionError }
        }
        
        await store.send(.tryAgainButtonPressed) {
            $0.displayState = .loading
        }
        await store.receive(.updateLocationResponse(.failure(connectionError))) {
            $0.displayState = .failed(connectionError)
        }
    }
}
