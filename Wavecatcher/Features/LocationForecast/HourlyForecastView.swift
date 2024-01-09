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
            .filter { weather in
                let components = Calendar.current.dateComponents([.minute, .second], from: weather.date)
                guard let minute = components.minute, let seconds = components.second else { return false }
                return (minute == 0) && (seconds == 0)
            }
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
                        timeRow(weatherData)
                            .foregroundStyle(.secondary)
                            .frame(height: rowFrameHeight)
                        
                        Circle()
                            .fill(surfRatingColor(for: weatherData.surfRating))
                            .frame(width: 8)
                            .shadow(radius: 8)
                            .padding(.trailing, 8)
                        
                        waveHeightRow(weatherData)
                            .foregroundStyle(.primary)
                            .frame(height: rowFrameHeight * 2)
                        
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
            Spacer()
                .frame(height: 8 + 8)
            
            Text("locationForecast.text.waveHeight(m)")
                .font(.caption)
                .frame(height: rowFrameHeight * 2, alignment: .center)
            
            Text("locationForecast.text.wind(km/h)")
                .font(.caption)
                .frame(height: rowFrameHeight, alignment: .bottom)
            VStack(alignment: .trailing, spacing: 0.0) {
                Text("locationForecast.text.swellHeight(m)")
                    .font(.caption)
                    .frame(height: rowFrameHeight, alignment: .bottom)
                Text("locationForecast.text.swellPeriod(s)")
                    .font(.caption)
                    .frame(height: rowFrameHeight, alignment: .bottom)
            }
            Text("locationForecast.text.airTemperature(°C)")
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
    
    private func waveHeightRow(_ data: WeatherData) -> some View {
        VStack(spacing: 0.0) {
            Text((data.waveHeightMin ?? 0).formatted(.number.precision(.fractionLength(0...1))))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text((data.waveHeightMax ?? 0).formatted(.number.precision(.fractionLength(0...1))))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
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
    
    private func timeRow(_ data: WeatherData) -> some View {
        guard !Calendar.current.isDate(data.date, equalTo: .now, toGranularity: .hour) else { return
            Text("locationForecast.text.Now")
                .font(.caption)
                .bold()
        }
        
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("E, dd MMM")
        
        let text = needDisplayNewDayIndicator(for: data)
        ? formatter.string(from: data.date)
        : data.date.formatted(.dateTime.hour(.twoDigits(amPM: .abbreviated)))
        
        return Text(text)
            .font(.caption)
            .bold()
    }
    
    private func needDisplayNewDayIndicator(for data: WeatherData) -> Bool {
        let visibleWeather = self.visibleWeather
        guard let index = visibleWeather.firstIndex(of: data), index > 0 else { return false }
        let previousData = visibleWeather[index - 1]
        return !Calendar.current.isDate(previousData.date, inSameDayAs: data.date)
    }
    
    private func surfRatingColor(for rating: WeatherData.SurfRating) -> Color {
        switch rating {
        case .unknown: return .gray
        case .veryPoor: return .red
        case .poor: return .orange
        case .poorToFair: return .yellow
        case .fair, .fairToGood, .good: return .green
        }
    }
}

#Preview {
    HourlyForecastView(weatherData: WeatherData.previewData)
}
