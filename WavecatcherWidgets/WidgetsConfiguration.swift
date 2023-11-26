//
//  WidgetsConfiguration.swift
//  WavecatcherWidgets
//

import WidgetKit
import AppIntents

struct WidgetsConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widgetsConfiguration.title"
    static var description = IntentDescription("widgetsConfiguration.description")

    @Parameter(title: "widgetsConfiguration.parameter.location")
    var location: LocationParameter?
}

struct LocationParameter: AppEntity {
    
    let id: String
    let title: String
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "widgetsConfiguration.parameter.location")
    static var defaultQuery = LocationsQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct LocationsQuery: EntityQuery {
    
    func entities(for identifiers: [LocationParameter.ID]) async throws -> [LocationParameter] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [LocationParameter] {
        let dependencies = DependencyProvider()
        return try await dependencies.localStorage.fetchLocations().map { LocationParameter(id: $0.id.rawValue, title: $0.title) }
    }
    
    func defaultResult() async -> LocationParameter? {
        try? await suggestedEntities().first
    }
}
