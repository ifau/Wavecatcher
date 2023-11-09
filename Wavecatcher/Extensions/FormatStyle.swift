//
//  FormatStyle.swift
//  Wavecatcher
//

import Foundation

struct CardinalDirectionFormat: FormatStyle {
    
    func format(_ degrees: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        
        let index = Int((degrees + 11.25) / 22.5) % 16
        return directions[index]
    }
}

extension FormatStyle where Self == Decimal.FormatStyle {
    static var cardinalDirection: CardinalDirectionFormat { .init() }
}
