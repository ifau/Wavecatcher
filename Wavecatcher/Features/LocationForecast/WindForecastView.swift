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
                    .accessibilityHidden(true)
                (Text(verbatim: (weatherData.nowData()?.windSpeed ?? 0.0).formatted(.number.precision(.fractionLength(0)))) + Text(windUnit))
                    .font(.title)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal)
            
            Spacer(minLength: 0.0)
                .frame(maxWidth: .infinity)
            
            (Text(verbatim: (weatherData.nowData()?.windGust ?? 0.0).formatted(.number.precision(.fractionLength(0)))) + Text(windUnit) + Text(verbatim: " ") + Text ("locationForecast.text.gust"))
                .foregroundStyle(.primary)
                .font(.caption)
                .padding(.horizontal)
        }
        .accessibilityElement(children: .combine)
    }
    
    private var windUnit: LocalizedStringKey { "km/h" }
    private var directionDescription: LocalizedStringKey {
        guard let windDirection = weatherData.nowData()?.windDirection else { return "" }
        let diff = (windDirection - offshorePerpendicular + 360).truncatingRemainder(dividingBy: 360)
        
        if diff <= 45 || diff >= 315 {
            return "locationForecast.text.offshoreWind"
        } else if diff > 45 && diff < 135 {
            return "locationForecast.text.crossShoreWind"
        } else {
            return "locationForecast.text.onshoreWind"
        }
    }
}

#Preview(traits: .fixedLayout(width: 300, height: 300)) {
    WindForecastView(weatherData: WeatherData.previewData, offshorePerpendicular: 90.0)
}
