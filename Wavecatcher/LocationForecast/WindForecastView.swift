//
//  WindForecastView.swift
//  Wavecatcher
//

import SwiftUI

struct WindForecastView: View {
    
    let weatherData: [WeatherData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "location.north.fill")
                        .rotationEffect(.degrees(weatherData.nowData()?.windDirection ?? 0))
                        .font(.subheadline)
                    Text(valueDescription)
                        .font(.title)
                }
                Text(directionDescription)
                    .font(.caption)
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
        "Cross-shore"
    }
}

#Preview(traits: .fixedLayout(width: 300, height: 300)) {
    WindForecastView(weatherData: WeatherData.previewData)
}
