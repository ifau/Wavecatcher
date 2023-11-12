//
//  OpenMeteoClient+MarineResponse.swift
//  Wavecatcher
//

import Foundation

extension OpenMeteoClient {
    
    struct MarineResponse: Codable {
        let latitude: Double
        let longitude: Double
        let generationtimeMS: Double
        let utcOffsetSeconds: Int
        let timezone: String
        let timezoneAbbreviation: String
        let elevation: Int
        let hourlyUnits: MarineResponse.HourlyUnits
        let hourly: MarineResponse.Hourly

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

extension OpenMeteoClient.MarineResponse {
    
    struct Hourly: Codable {
        let time: [String]
        let waveHeight: [Double]
        let waveDirection: [Int]
        let wavePeriod: [Double]
        let swellWaveHeight: [Double]
        let swellWaveDirection: [Int]
        let swellWavePeriod: [Double]

        enum CodingKeys: String, CodingKey {
            case time = "time"
            case waveHeight = "wave_height"
            case waveDirection = "wave_direction"
            case wavePeriod = "wave_period"
            case swellWaveHeight = "swell_wave_height"
            case swellWaveDirection = "swell_wave_direction"
            case swellWavePeriod = "swell_wave_period"
        }
    }

    struct HourlyUnits: Codable {
        let time: String
        let waveHeight: String
        let waveDirection: String
        let wavePeriod: String
        let swellWaveHeight: String
        let swellWaveDirection: String
        let swellWavePeriod: String

        enum CodingKeys: String, CodingKey {
            case time = "time"
            case waveHeight = "wave_height"
            case waveDirection = "wave_direction"
            case wavePeriod = "wave_period"
            case swellWaveHeight = "swell_wave_height"
            case swellWaveDirection = "swell_wave_direction"
            case swellWavePeriod = "swell_wave_period"
        }
    }
}
