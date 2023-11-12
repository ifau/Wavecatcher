//
//  OpenMeteoClient+ForecastResponse.swift
//  Wavecatcher
//

import Foundation

extension OpenMeteoClient {
    
    struct ForecastResponse: Codable {
        let latitude: Double
        let longitude: Double
        let generationtimeMS: Double
        let utcOffsetSeconds: Int
        let timezone: String
        let timezoneAbbreviation: String
        let elevation: Int
        let hourlyUnits: ForecastResponse.HourlyUnits
        let hourly: ForecastResponse.Hourly

        enum CodingKeys: String, CodingKey {
            case latitude = "latitude"
            case longitude = "longitude"
            case generationtimeMS = "generationtime_ms"
            case utcOffsetSeconds = "utc_offset_seconds"
            case timezone = "timezone"
            case timezoneAbbreviation = "timezone_abbreviation"
            case elevation = "elevation"
            case hourlyUnits = "hourly_units"
            case hourly = "hourly"
        }
    }
}

extension OpenMeteoClient.ForecastResponse {
    
    struct Hourly: Codable {
        let time: [String]
        let temperature2M: [Double]
        let windSpeed10M: [Double]
        let windDirection10M: [Int]
        let windGusts10M: [Double]
        
        enum CodingKeys: String, CodingKey {
            case time = "time"
            case temperature2M = "temperature_2m"
            case windSpeed10M = "wind_speed_10m"
            case windDirection10M = "wind_direction_10m"
            case windGusts10M = "wind_gusts_10m"
        }
    }
    
    struct HourlyUnits: Codable {
        let time: String
        let temperature2M: String
        let windSpeed10M: String
        let windDirection10M: String
        let windGusts10M: String
        
        enum CodingKeys: String, CodingKey {
            case time = "time"
            case temperature2M = "temperature_2m"
            case windSpeed10M = "wind_speed_10m"
            case windDirection10M = "wind_direction_10m"
            case windGusts10M = "wind_gusts_10m"
        }
    }
}
