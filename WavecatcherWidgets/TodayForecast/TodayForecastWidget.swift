//
//  TodayForecastWidget.swift
//  WavecatcherWidgets
//

import SwiftUI
import WidgetKit
import Charts

struct TodayForecastWidget: Widget {
    let kind: String = "com.ifau.wavecatcher.today-forecast-widget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WidgetsConfiguration.self, provider: WidgetsDataProvider()) { entry in
            TodayForecastEntryView(entry: entry)
                .containerBackground(.background.tertiary, for: .widget)
        }
        .configurationDisplayName("todayForecast.widgetTitle")
        .description("todayForecast.widgetDescription")
        .supportedFamilies([.systemMedium])
    }
}

struct TodayForecastEntryView: View {
    var entry: WeatherDataEntry
    @Environment (\.dynamicTypeSize) var typeSize
    @Environment (\.redactionReasons) var redactionReasons
    
    var body: some View {
        switch entry.state {
        case .notConfigured:
            locationIsNotConfiguredView
        case let .configured(weatherData, dateUpdated, locationTitle):
            configuredView(weatherData, dateUpdated, locationTitle)
        }
    }
    
    private var locationIsNotConfiguredView: some View {
        VStack(spacing: 8.0) {
            Text("todayForecast.text.noLocationsAdded")
                .minimumScaleFactor(0.5)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("todayForecast.text.addLocationsInTheMainApp")
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func configuredView(_ weatherData: [WeatherData], _ dateUpdated: Date, _ locationTitle: String) -> some View {
        VStack {
            header(locationTitle: locationTitle, weatherData: weatherData)
            if case .placeholder = redactionReasons {
                Spacer()
            } else {
                Spacer()
                weatherTable(dateUpdated: dateUpdated, weatherData: weatherData)
            }
        }
    }
    
    private func header(locationTitle: String, weatherData: [WeatherData]) -> some View {
        HStack(alignment: .bottom) {
            Text(locationTitle)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            if let weather = weatherData.closestData(to: entry.date),
               let swellHeight = weather.swellHeight,
               let swellDirection = weather.swellDirection,
               let swellPeriod = weather.swellPeriod {
                HStack(spacing: 4.0) {
                    Text("\(swellHeight.formatted(.number.precision(.fractionLength(0...1))))m \(swellPeriod.formatted(.number.precision(.fractionLength(0))))s")
                    Image(systemName: "location.north.fill")
                        .rotationEffect(.degrees(swellDirection))
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                    Text(swellDirection.formatted(.cardinalDirection))
                    Text(verbatim: "\(swellDirection.formatted(.number.precision(.fractionLength(0))))°")
                        .foregroundStyle(.secondary)
                }
                .layoutPriority(1)
                .font(.caption2).fontDesign(.rounded).fontWeight(.semibold)
            }
        }
    }
    
    private func weatherTable(dateUpdated: Date, weatherData: [WeatherData]) -> some View {
        let sliceToDisplay = weatherData
            .filter { weather in
                if Calendar.current.isDate(weather.date, equalTo: entry.date, toGranularity: .hour) { return true }
                guard weather.date >= entry.date else { return false }
                let components = Calendar.current.dateComponents([.hour, .minute, .second], from: weather.date)
                guard let minute = components.minute, let second = components.second else { return false }
                return minute == 0 && second == 0
            }
            .sorted { $0.date < $1.date }
            .enumerated()
            .filter { index, element in
                index % 3 == 0
            }
            .map { $1 }
            .prefix(8)
        
        let dataToDisplay = Array(sliceToDisplay)
        let isEnoughtDataToDisplay = dataToDisplay.count >= 6
        
        return Group {
            if !isEnoughtDataToDisplay {
                weatherTableHasNotEnoughtDataToDisplay(dateUpdated: dateUpdated)
            } else {
                HStack(spacing: 0) {
                    ForEach(0..<dataToDisplay.count, id: \.self) { index in
                        if index > 0 {
                            Spacer(minLength: 0)
                        }
                        dataColumn(dataToDisplay[index], isCurrentHourConditions: index == 0)
                        
                        if index < dataToDisplay.count - 1 {
                            Spacer(minLength: 0)
                            Divider()
                        }
                    }
                }.background {
                    VStack {
                        Spacer()
                        TideChartView(weatherData: dataToDisplay)
                            .frame(height: 20.0)
                    }
                }
            }
        }
    }
    
    private func weatherTableHasNotEnoughtDataToDisplay(dateUpdated: Date) -> some View {
        VStack {
            Spacer()
            Text("todayForecast.text.noDataAvailable") // No data available
                .minimumScaleFactor(0.5)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("todayForecast.text.lastUpdated \(dateUpdated.formatted(.relative(presentation: .named, unitsStyle: .spellOut)))")
                .minimumScaleFactor(0.5)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    private func dataColumn(_ weather: WeatherData, isCurrentHourConditions: Bool) -> some View {
        VStack(spacing: 8.0) {
            (isCurrentHourConditions ? Text("todayForecast.text.now") : Text(timeString(weather.date)))
                .foregroundStyle(.secondary)
                .font(.caption2).fontDesign(.rounded).fontWeight(.semibold)
            
            Circle()
                .fill(surfRatingColor(for: weather.surfRating))
                .frame(height: 8)
            
            VStack(alignment: .leading, spacing: 0.0) {
                HStack(spacing: 1) {
                    Text((weather.waveHeightMin ?? 0.0).formatted(.number.precision(.fractionLength(0...1))))
                        .font(.caption2).fontDesign(.rounded).fontWeight(.semibold)
                    Text(verbatim: "~")
                        .font(.caption2).fontDesign(.rounded).fontWeight(.regular)
                }
                HStack(spacing: 1) {
                    Text((weather.waveHeightMax ?? 0.0).formatted(.number.precision(.fractionLength(0...1))))
                        .font(.caption2).fontDesign(.rounded).fontWeight(.semibold)
                    Text("m")
                        .font(.caption2).fontDesign(.rounded).fontWeight(.regular)
                }
            }
            Rectangle()
                .frame(width: 2, height: 14)
                .opacity(0.0)
        }
    }
    
    private func timeString(_ date: Date) -> String {
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))).lowercased().components(separatedBy: .whitespacesAndNewlines).joined()
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

extension TodayForecastEntryView {
    
    struct TideChartView: View {
        
        let weatherData: [WeatherData]
        
        var body: some View {
            Chart {
                ForEach(weatherData, id: \.date) { data in
                    LineMark(x: .value("todayForecast.tideChartText.hour", data.date),
                             y: .value("todayForecast.tideChartText.height", data.tideHeight ?? 0.0))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.clear)
                    AreaMark(x: .value("todayForecast.tideChartText.hour", data.date),
                             y: .value("todayForecast.tideChartText.height", data.tideHeight ?? 0.0))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(areaGradient)
                }
            }
            .chartLegend(.hidden)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartXScale(range: .plotDimension)
            .chartYScale(range: .plotDimension)
        }
        
        private static let startColor = Color(red: 181.0/255.0, green: 218.0/255.0, blue: 239.0/255.0)
        private let areaGradient = LinearGradient(gradient: Gradient(colors: [startColor, startColor.opacity(0.0)]), startPoint: .top, endPoint: .bottom)
    }
}

#Preview(as: .systemMedium) {
    TodayForecastWidget()
} timeline: {
    WeatherDataEntry(date: Date(timeIntervalSinceNow: 0), state: .notConfigured)
    WeatherDataEntry(date: Date(timeIntervalSinceNow: 100), state: .configured(weatherData: [], dateUpdated: Date(timeIntervalSinceNow: -200), locationTitle: "Uluwatu"))
    WeatherDataEntry(date: Date(timeIntervalSinceNow: 200), state: .configured(weatherData: WeatherData.previewData, dateUpdated: .now, locationTitle: "Uluwatu"))
}
