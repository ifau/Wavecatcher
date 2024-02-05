//
//  TideForecastView.swift
//  Wavecatcher
//

import SwiftUI
import Charts

struct TideForecastView: View {
    
    @Environment(\.colorScheme) var colorScheme
    let weatherData: [WeatherData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(isRising ? "locationForecast.text.risingTide" : "locationForecast.text.droppingTide")
                .foregroundStyle(.primary)
                .font(.subheadline)
                .padding(.horizontal)
            HStack {
                Image(systemName: (isRising ? "arrow.up" : "arrow.down"))
                    .font(.title3)
                    .accessibilityHidden(true)
                (Text(verbatim: "\(currentHeight.formatted(.number.precision(.fractionLength(0...1))))") + Text("m"))
                    .font(.title)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal)
            
            Spacer(minLength: 0.0)
            
            chart
                .frame(height: 40)
                .accessibilityHidden(true)
            
            Spacer(minLength: 0.0)
            
            Text(nextMaximumTideDescription)
                .foregroundStyle(.primary)
                .font(.caption)
                .padding(.horizontal)
        }
        .accessibilityElement(children: .combine)
    }
    
    private var chart: some View {
        Chart {
            ForEach(Array(weatherData.todayData().enumerated()), id: \.offset) { index, data in
                LineMark(x: .value("locationForecast.tideChartText.hour", data.date),
                         y: .value("locationForecast.tideChartText.height", data.tideHeight ?? 0.0))
                .interpolationMethod(.catmullRom)
                .lineStyle(.init(lineWidth: 2))
                .foregroundStyle(lineGradient)
                .symbol {
                    if let nowData = self.nowData, nowData == data {
                        Circle()
                            .fill(colorScheme == .dark ? .white : .black)
                            .frame(width: 12)
                            .shadow(color: (colorScheme == .dark ? Color(.sRGBLinear, white: 1, opacity: 0.33) : Color(.sRGBLinear, white: 0, opacity: 0.33)), radius: 8)
                    }
                }
                .opacity(0.5)
            }
        }
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis(.visible)
        .chartYAxis {
            AxisMarks(values: [currentHeight]) {
                AxisGridLine()
            }
        }
    }
    
    private var currentHeight: Double {
        return nowData?.tideHeight ?? 0.0
    }
    
    private var nowData: WeatherData? {
        weatherData.first(where: { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .hour) } )
    }
    
    private var lineGradient: LinearGradient {
        let mainColor: Color = (colorScheme == .dark ? .white : .black)
        let oppositeColor: Color = (colorScheme == .dark ? .black : Color(red: 0.7, green: 0.7, blue: 0.7))
        
        let stops = [
            Gradient.Stop(color: oppositeColor, location: 0.0),
            
            Gradient.Stop(color: mainColor, location: 0.4),
            Gradient.Stop(color: mainColor, location: 0.6),
            
            Gradient.Stop(color: oppositeColor, location: 1.0)
        ]
        return LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
    }
    
    private var isRising: Bool {
        guard let nowData = weatherData.nowData(), let nextMaximumTide = weatherData.dataOfNextMaximumTide() else { return false }
        return (nowData.tideHeight ?? 0.0) < (nextMaximumTide.tideHeight ?? 0.0)
    }
    
    private var nextMaximumTideDescription: LocalizedStringKey {
        guard let nextMaximumTide = weatherData.dataOfNextMaximumTide() else { return "" }
        let meters = (nextMaximumTide.tideHeight ?? 0.0).formatted(.number.precision(.fractionLength(0...1)))
        let time = nextMaximumTide.date.formatted(date: .omitted, time: .shortened)
        return isRising ? "locationForecast.text.nextMaximumTide \(meters)m \(time)" : "locationForecast.text.nextMinimumTide \(meters)m \(time)"
    }
}

#Preview(traits: .fixedLayout(width: 300, height: 300)) {
    TideForecastView(weatherData: WeatherData.previewData)
}
