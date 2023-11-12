//
//  HourlyForecastView.swift
//  Wavecatcher
//

import SwiftUI

struct HourlyForecastView: View {
    
    private let rowFrameHeight: CGFloat = 20.0
    
    let weatherData: [WeatherData]
    private var visibleWeather: [WeatherData] {
        let nowHour = Calendar.current.nextDate(after: .now, matching: .init(minute: 0, second: 0), matchingPolicy: .previousTimePreservingSmallerComponents, direction: .backward)!
        
        return weatherData
            .filter { $0.date >= nowHour }
            .sorted(by: { $0.date < $1.date })
    }
    
    init(weatherData: [WeatherData]) {
        self.weatherData = weatherData
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                columnsDescriptions
                    .padding(.trailing)
                ForEach(visibleWeather, id: \.date) { weatherData in
                    VStack(alignment: .trailing) {
                        timeRow(date: weatherData.date)
                            .foregroundStyle(.secondary)
                            .frame(height: rowFrameHeight)
                        
                        windRow(weatherData)
                            .foregroundStyle(.primary)
                            .frame(height: rowFrameHeight)
                        
                        swellRow(weatherData)
                            .foregroundStyle(.primary)
                            .frame(height: rowFrameHeight * 2)
                        
                        airTemperatureRow(weatherData)
                            .foregroundStyle(.primary)
                            .frame(height: rowFrameHeight)
                    }
                }
            }
            .drawingGroup()
        }
    }
    
    private var columnsDescriptions: some View {
        VStack(alignment: .trailing) {
            Spacer()
                .frame(height: rowFrameHeight)
            Text("Wind (km/h)")
                .font(.caption)
                .frame(height: rowFrameHeight, alignment: .bottom)
            VStack(alignment: .trailing, spacing: 0.0) {
                Text("Swell height (m)")
                    .font(.caption)
                    .frame(height: rowFrameHeight, alignment: .bottom)
                Text("Swell period (s)")
                    .font(.caption)
                    .frame(height: rowFrameHeight, alignment: .bottom)
            }
            Text("Air temp. (°C)")
                .font(.caption)
                .frame(height: rowFrameHeight, alignment: .bottom)
        }
        .foregroundStyle(.secondary)
        .bold()
    }
    
    private func windRow(_ data: WeatherData) -> some View {
        HStack(alignment: .center, spacing: 4.0) {
            Image(systemName: "location.north.fill")
                .rotationEffect(.degrees(data.windDirection ?? 0))
                .font(.caption2)
            
            Text((data.windSpeed ?? 0).formatted(.number.precision(.fractionLength(0...1))))
                .font(.headline)
        }
    }
    
    private func swellRow(_ data: WeatherData) -> some View {
        VStack(spacing: 0.0) {
            HStack(alignment: .center, spacing: 4.0) {
                Image(systemName: "location.north.fill")
                    .rotationEffect(.degrees(data.swellDirection ?? 0))
                    .font(.caption2)
                
                Text((data.swellHeight ?? 0).formatted(.number.precision(.fractionLength(0...1))))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text((data.swellPeriod ?? 0).formatted(.number.precision(.fractionLength(0))))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    private func airTemperatureRow(_ data: WeatherData) -> some View {
        Text((data.airTemperature ?? 0).formatted(.number.precision(.fractionLength(0))))
            .font(.headline)
    }
    
    private func timeRow(date: Date) -> some View {
        let getString = {
            guard !Calendar.current.isDate(date, equalTo: .now, toGranularity: .hour) else { return "Now" }
            return date.formatted(.dateTime.hour(.twoDigits(amPM: .abbreviated)))
        }
        return Text(getString()).font(.caption).bold()
    }
}

#Preview {
    HourlyForecastView(weatherData: WeatherData.previewData)
}
