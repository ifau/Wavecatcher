//
//  Location.swift
//  Wavecatcher
//

import Foundation
import Tagged

struct Location: Equatable, Identifiable, Codable {
    typealias Id = Tagged<Location, String>
    
    let id: Id
    let latitude: Double
    let longitude: Double
    let offshorePerpendicular: Double
    let title: String
}

extension Location {
    
    static var previewData: [Location] {[
        Location(id: "1", latitude: -8.72, longitude: 115.17, offshorePerpendicular: 80, title: "Kuta Beach"),
        Location(id: "2", latitude: -8.82, longitude: 115.09, offshorePerpendicular: 120, title: "Uluwatu")
    ]}
}
