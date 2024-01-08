//
//  OpenMeteoClient+Tides.swift
//  Wavecatcher
//

import Foundation
import CoreLocation

extension OpenMeteoClient {
    
    // Getting tides information using Surfline API
    // This is a temporary solution until OpenMeteo integrates the corresponding API
    // https://github.com/open-meteo/open-meteo/issues/104
    
    func getTidesForecast(latitude: Double, longitude: Double, name: String) async throws -> [Int:Double] {
        
        let spotIdCacheURL = URL.cachesDirectory.appendingPathComponent("spotId_\(name.components(separatedBy: .whitespaces).joined())")
        
        var spotId: String?
        if FileManager.default.fileExists(atPath: spotIdCacheURL.path()) {
            spotId = try? String(contentsOf: spotIdCacheURL)
        }
        if case .none = spotId {
            spotId = try? await retrieveSpotId(latitude: latitude, longitude: longitude, name: name)
        }
        
        guard let spotId else {
            struct GetSpotIdFailed: Error {}
            throw GetSpotIdFailed()
        }
        
        try? spotId.write(to: spotIdCacheURL, atomically: true, encoding: .utf8)
        
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
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15", forHTTPHeaderField: "User-agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await urlSession.data(for: request)
        let tidesResponse = try JSONDecoder().decode(TidesResponse.self, from: data)
        
        var result: [Int:Double] = [:]
        tidesResponse.data.tides.forEach { result[$0.timestamp] = $0.height }
        return result
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
    
    private func retrieveSpotId(latitude: Double, longitude: Double, name: String) async throws -> String? {

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "services.surfline.com"
        urlComponents.path = "/search/site"
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "querySize", value: "10"),
            URLQueryItem(name: "suggestionSize", value: "10"),
            URLQueryItem(name: "newsSearch", value: "false")
        ]
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15", forHTTPHeaderField: "User-agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await urlSession.data(for: request)
        
        let searchResponse = try JSONDecoder().decode([SearchResponse].self, from: data)
        
        let requestedLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        return searchResponse
            .flatMap { $0.hits.hits }
            .map { (id: $0.id, location: CLLocation(latitude: $0.source.location.lat, longitude: $0.source.location.lon)) }
            .sorted { $0.location.distance(from: requestedLocation) < $1.location.distance(from: requestedLocation) }
            .first?.id
    }
    
    private struct SearchResponse: Codable {
        let hits: Hits
        
        struct Hits: Codable {
            let hits: [Hit]
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: SearchResponse.CodingKeys.self)
                var hitsContainer = try container.nestedUnkeyedContainer(forKey: .hits)
                
                // This struct is required to skip invalid Hit element
                struct AnyCodable: Codable {}
                
                var hits = [Hit]()
                while !hitsContainer.isAtEnd {
                    guard let hit = try? hitsContainer.decode(Hit.self) else {
                        let _ = try? hitsContainer.decode(AnyCodable.self)
                        continue
                    }
                    hits.append(hit)
                }
                self.hits = hits
            }
        }
        struct Hit: Codable {
            let id: String
            let source: Source
            enum CodingKeys: String, CodingKey {
                case id = "_id"
                case source = "_source"
            }
        }
        struct Source: Codable {
            let name: String
            let location: SourceLocation
        }
        struct SourceLocation: Codable {
            let lon, lat: Double
        }
    }
    
    func getSurfRating(latitude: Double, longitude: Double, name: String) async throws -> [Int:WeatherData.SurfRating] {
        
        let spotIdCacheURL = URL.cachesDirectory.appendingPathComponent("spotId_\(name.components(separatedBy: .whitespaces).joined())")
        
        var spotId: String?
        if FileManager.default.fileExists(atPath: spotIdCacheURL.path()) {
            spotId = try? String(contentsOf: spotIdCacheURL)
        }
        if case .none = spotId {
            spotId = try? await retrieveSpotId(latitude: latitude, longitude: longitude, name: name)
        }
        
        guard let spotId else {
            struct GetSpotIdFailed: Error {}
            throw GetSpotIdFailed()
        }
        
        try? spotId.write(to: spotIdCacheURL, atomically: true, encoding: .utf8)
        
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
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15", forHTTPHeaderField: "User-agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await urlSession.data(for: request)
        let ratingResponse = try JSONDecoder().decode(RatingResponse.self, from: data)
        
        var result: [Int:WeatherData.SurfRating] = [:]
        ratingResponse.data.rating.forEach { result[$0.timestamp] = WeatherData.SurfRating.init(rawValue: Int($0.rating.value)) }
        return result
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
}
