//
//  SurflineClient.swift
//  Wavecatcher
//

import Foundation

final class SurflineClient {
    
    let urlSession = URLSession(configuration: URLSessionConfiguration.ephemeral)
    
    // Getting tides information using Surfline API
    // This is a temporary solution until OpenMeteo integrates the corresponding API
    // https://github.com/open-meteo/open-meteo/issues/104
    
    func getTidesForecast(latitude: Double, longitude: Double, name: String) async throws -> [Int:Double] {
        
        let spotId = try await getSpotId(latitude: latitude, longitude: longitude, name: name)
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "services.surfline.com"
        urlComponents.path = "/kbyg/spots/forecasts/tides"
        urlComponents.queryItems = [
            URLQueryItem(name: "days", value: "3"),
            URLQueryItem(name: "intervalHours", value: "1"),
            URLQueryItem(name: "spotId", value: spotId)
        ]
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await urlSession.data(for: urlRequestWithHeaders(url: url))
        let tidesResponse = try JSONDecoder().decode(TidesResponse.self, from: data)
        
        var result: [Int:Double] = [:]
        tidesResponse.data.tides.forEach { result[$0.timestamp] = $0.height }
        return result
    }
    
    func getSurfRating(latitude: Double, longitude: Double, name: String) async throws -> [Int:WeatherData.SurfRating] {
        
        let spotId = try await getSpotId(latitude: latitude, longitude: longitude, name: name)
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "services.surfline.com"
        urlComponents.path = "/kbyg/spots/forecasts/rating"
        urlComponents.queryItems = [
            URLQueryItem(name: "days", value: "3"),
            URLQueryItem(name: "intervalHours", value: "1"),
            URLQueryItem(name: "spotId", value: spotId)
        ]
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await urlSession.data(for: urlRequestWithHeaders(url: url))
        let ratingResponse = try JSONDecoder().decode(RatingResponse.self, from: data)
        
        var result: [Int:WeatherData.SurfRating] = [:]
        ratingResponse.data.rating.forEach { result[$0.timestamp] = WeatherData.SurfRating.init(rawValue: Int($0.rating.value)) }
        return result
    }
    
    func getWaveParams(latitude: Double, longitude: Double, name: String) async throws -> [Int:(min: Double, max: Double)] {
        
        let spotId = try await getSpotId(latitude: latitude, longitude: longitude, name: name)
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "services.surfline.com"
        urlComponents.path = "/kbyg/spots/forecasts/wave"
        urlComponents.queryItems = [
            URLQueryItem(name: "days", value: "3"),
            URLQueryItem(name: "intervalHours", value: "1"),
            URLQueryItem(name: "spotId", value: spotId)
        ]
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await urlSession.data(for: urlRequestWithHeaders(url: url))
        let ratingResponse = try JSONDecoder().decode(WaveResponse.self, from: data)
        
        var result: [Int:(min: Double, max: Double)] = [:]
        ratingResponse.data.wave.forEach { result[$0.timestamp] = (min: $0.surf.min, max: $0.surf.max) }
        return result
    }
}

extension SurflineClient {
    
    func urlRequestWithHeaders(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15", forHTTPHeaderField: "User-agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    struct TidesResponse: Codable {
        let data: DataClass
        
        struct DataClass: Codable {
            let tides: [Tide]
        }
        struct Tide: Codable {
            let timestamp: Int
            let utcOffset: Int
            let type: String
            let height: Double
        }
    }
    
    struct RatingResponse: Codable {
        let data: DataClass
        
        struct DataClass: Codable {
            let rating: [RatingElement]
        }
        struct RatingElement: Codable {
            let timestamp: Int
            let utcOffset: Int
            let rating: Rating
        }
        struct Rating: Codable {
            let key: String
            let value: Double
        }
    }
    
    struct WaveResponse: Codable {
        let data: DataClass
        
        struct DataClass: Codable {
            let wave: [Wave]
        }
        struct Wave: Codable {
            let timestamp: Int
            let probability: Int?
            let utcOffset: Int
            let surf: Surf
            let power: Double
            let swells: [Swell]
        }
        struct Surf: Codable {
            let min, max: Double
            let optimalScore: Int
            let plus: Bool
            let humanRelation: String
            let raw: Raw
        }
        struct Raw: Codable {
            let min, max: Double
        }
        struct Swell: Codable {
            let height: Double
            let period: Int
            let impact, power, direction, directionMin: Double
            let optimalScore: Int
        }
    }
}
