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

extension FormatStyle where Self == FloatingPointFormatStyle<Double> {
    static func coordinates(precision: Int) -> FloatingPointFormatStyle<Double> {
        FloatingPointFormatStyle<Double>(locale: Locale(identifier: "en_US"))
            .grouping(.never)
            .decimalSeparator(strategy: .always)
            .rounded(rule: .down)
            .precision(.fractionLength(precision...precision))
    }
}
