//
//  SavedLocation.swift
//  Wavecatcher
//

import Foundation
import Tagged

struct SavedLocation: Equatable, Codable {
    let location: Location
    let dateCreated: Date
    var dateUpdated: Date
    var weather: [WeatherData]
    var customOrderIndex: Int
    var customBackground: BackgroundVariant
}

extension SavedLocation: Identifiable {
    var id: Location.ID { location.id }
    var title: String { location.title }
    var latitude: Double { location.latitude }
    var longitude: Double { location.longitude }
    var offshorePerpendicular: Double { location.offshorePerpendicular }
}

extension SavedLocation {
    static let previewData: [SavedLocation] = {
        Location.previewData.map {
            SavedLocation(location: $0, dateCreated: Date(timeIntervalSinceNow: -60*60*24*8), dateUpdated: Date(timeIntervalSinceNow: -60*60*24*1), weather: WeatherData.previewData, customOrderIndex: Int($0.id.rawValue) ?? 0, customBackground: .aurora(.variant1))
        }
    }()
}
