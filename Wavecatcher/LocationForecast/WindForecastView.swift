//
//  WindForecastView.swift
//  Wavecatcher
//

import SwiftUI

struct WindForecastView: View {
    
    let weatherData: [WeatherData]
    let offshorePerpendicular: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(directionDescription)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .padding(.horizontal)
            
            HStack {
                Image(systemName: "location.north.fill")
                    .rotationEffect(.degrees(weatherData.nowData()?.windDirection ?? 0))
                    .font(.subheadline)
                Text(valueDescription)
                    .font(.title)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal)
            
            Spacer(minLength: 0.0)
                .frame(maxWidth: .infinity)
            
            Text(gustDescription)
                .foregroundStyle(.primary)
                .font(.caption)
                .padding(.horizontal)
        }
    }
    
    private var valueDescription: String {
        let value = weatherData.nowData()?.windSpeed ?? 0.0
        return "\(value.formatted(.number.precision(.fractionLength(0...1))))km/h"
    }
    
    private var gustDescription: String {
        let value = weatherData.nowData()?.windGust ?? 0.0
        return "\(value.formatted(.number.precision(.fractionLength(0...1))))km/h gust"
    }
    
    private var directionDescription: String {
        guard let windDirection = weatherData.nowData()?.windDirection else { return "" }
        let diff = (windDirection - offshorePerpendicular + 360).truncatingRemainder(dividingBy: 360)
        
        if diff <= 45 || diff >= 315 {
            return "Offshore wind"
        } else if diff > 45 && diff < 135 {
            return "Cross-shore wind"
        } else {
            return "Onshore wind"
        }
    }
}

#Preview(traits: .fixedLayout(width: 300, height: 300)) {
    WindForecastView(weatherData: WeatherData.previewData, offshorePerpendicular: 90.0)
}
