//
//  WeatherData+Extract.swift
//  Wavecatcher
//

import Foundation

extension Collection where Element == WeatherData {
    
    func closestData(to toDate: Date) -> WeatherData? {
        self.sorted { abs($0.date.timeIntervalSince(toDate)) < abs($1.date.timeIntervalSince(toDate)) }
            .first
    }
    
    func nowData() -> WeatherData? {
        self.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .hour) }
            .sorted { abs($0.date.timeIntervalSinceNow) < abs($1.date.timeIntervalSinceNow) }
            .first
    }
    
    func todayData() -> [WeatherData] {
        self.filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }
    
    func dataOfNextMaximumTide() -> WeatherData? {
        var data = self.todayData() // sorted
        guard let nowData = self.nowData() else { return nil }
        guard let nowTide = nowData.tideHeight else { return nil }
        guard let startIndex = data.lastIndex(of: nowData) else { return nil }
        data = Array(data.suffix(from: startIndex).filter({ $0.tideHeight != nil }))
        guard data.count >= 2 else { return nil }
        
        let findMinimum = (data[1].tideHeight ?? 0.0) < nowTide
        var result = data[1]
        
        guard data.count > 2 else { return result }
        for i in 2..<data.count {
            guard let currentTide = data[i].tideHeight, let previousTide = data[i-1].tideHeight else { return result }
            
            if findMinimum, currentTide < previousTide {
                result = data[i]
            } else if findMinimum {
                return data[i-1]
            }
            
            if !findMinimum, currentTide > previousTide {
                result = data[i]
            } else if !findMinimum {
                return data[i-1]
            }
        }
        
        return result
    }
}
