//
//  WidgetsDataProvider.swift
//  WavecatcherWidgets
//

import WidgetKit
import ComposableArchitecture

struct WidgetsDataProvider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> WeatherDataEntry {
        let locationTitle = "Uluwatu"
        let startDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: .now, matchingPolicy: .previousTimePreservingSmallerComponents, direction: .backward) ?? .now
        
        let dates = (0..<24).map { hourOffset in
            return Calendar.current.date(byAdding: .hour, value: hourOffset, to: startDate)
            ?? Date(timeInterval: TimeInterval(60*60*hourOffset), since: startDate)
        }
        
        let weather = dates.enumerated().map { index, date -> WeatherData in
            WeatherData(date: date,
                        airTemperature: Double.random(in: 30...32),
                        windDirection: Double.random(in: 80...100),
                        windSpeed: Double.random(in: 20...25),
                        windGust: Double.random(in: 25...27),
                        swellDirection: Double.random(in: 180...230),
                        swellPeriod: Double.random(in: 8...12),
                        swellHeight: Double.random(in: 1.2...2.5),
                        tideHeight: sin(Double(index) / 2.2) + 2)
        }
        
        return WeatherDataEntry(date: startDate, state: .configured(weatherData: weather, dateUpdated: .now, locationTitle: locationTitle))
    }

    func snapshot(for configuration: WidgetsConfiguration, in context: Context) async -> WeatherDataEntry {
        guard let location = await getSavedLocationUpdatedIfNeeded(configuration: configuration) else {
            return context.isPreview ? placeholder(in: context) : WeatherDataEntry(date: .now, state: .notConfigured)
        }
        return WeatherDataEntry(date: .now, state: .configured(weatherData: location.weather, dateUpdated: location.dateUpdated, locationTitle: location.title))
    }
    
    func timeline(for configuration: WidgetsConfiguration, in context: Context) async -> Timeline<WeatherDataEntry> {
        
        guard let location = await getSavedLocationUpdatedIfNeeded(configuration: configuration) else {
            return Timeline(entries: [WeatherDataEntry(date: .now, state: .notConfigured)],
                            policy: .after(Date(timeIntervalSinceNow: 60)))
        }
        
        let nowHour = Calendar.current.nextDate(after: .now, matching: .init(minute: 0, second: 0), matchingPolicy: .previousTimePreservingSmallerComponents, direction: .backward) ?? .now
        
        var entries = [WeatherDataEntry(date: .now, state: .configured(weatherData: location.weather, dateUpdated: location.dateUpdated, locationTitle: location.title))]
        
        for hourOffset in 0 ..< 4 {
            guard let nextHour = Calendar.current.date(byAdding: .hour, value: hourOffset, to: nowHour) else { continue }
            guard Calendar.current.isDateInToday(nextHour) else { continue }
            entries.append(WeatherDataEntry(date: nextHour, state: .configured(weatherData: location.weather, dateUpdated: location.dateUpdated, locationTitle: location.title)))
        }
        
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    private func getSavedLocationUpdatedIfNeeded(configuration: WidgetsConfiguration) async -> SavedLocation? {
        
        guard let locationId = configuration.location?.id else { return nil }
        
        let dependencies = DependencyProvider()
        
        guard let location = try? await dependencies.localStorage.fetchLocations().first(where: { $0.id.rawValue == locationId }) else { return nil }
        guard dependencies.weatherDataProvider.needUpdateWeatherForLocation(location) else { return location }
        
        try? await dependencies.weatherDataProvider.updateWeatherDataForLocation(location)
        
        guard let updatedLocation = try? await dependencies.localStorage.fetchLocations().first(where: { $0.id.rawValue == locationId }) else { return location }
        return updatedLocation
    }
}

struct WeatherDataEntry: TimelineEntry {
    let date: Date
    let state: WeatherDataEntry.State
    
    enum State { case notConfigured, configured(weatherData: [WeatherData], dateUpdated: Date, locationTitle: String) }
}

struct DependencyProvider {
    @Dependency(\.localStorage) var localStorage
    @Dependency(\.weatherDataProvider) var weatherDataProvider
}
