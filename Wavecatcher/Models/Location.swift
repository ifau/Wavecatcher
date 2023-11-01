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
    let title: String
}

extension Location {
    
    static var previewData: [Location] {[
        Location(id: "1", latitude: -8.72, longitude: 115.17, title: "Kuta Beach"),
        Location(id: "2", latitude: -8.82, longitude: 115.09, title: "Uluwatu")
    ]}
}
