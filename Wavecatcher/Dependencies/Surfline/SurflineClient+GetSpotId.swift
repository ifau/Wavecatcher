//
//  SurflineClient+CacheSpotId.swift
//  Wavecatcher
//

import Foundation
import CoreLocation

extension SurflineClient {
    
    func getSpotId(latitude: Double, longitude: Double, name: String) async throws -> String {
        
        let spotIdCacheURL = URL.cachesDirectory.appendingPathComponent("spotId_\(name.components(separatedBy: .whitespaces).joined())")
        
        var spotId: String?
        if FileManager.default.fileExists(atPath: spotIdCacheURL.path()) {
            spotId = try? String(contentsOf: spotIdCacheURL)
        }
        if case .none = spotId {
            spotId = try? await retrieveSpotId(latitude: latitude, longitude: longitude, name: name)
        }
        
        guard let spotId else {
            throw AppError.failedGetSpotId
        }
        
        try? spotId.write(to: spotIdCacheURL, atomically: true, encoding: .utf8)
        return spotId
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
            throw AppError.failedBuildURL(host: urlComponents.host)
        }
        
        let (data, _) = try await urlSession.data(for: urlRequestWithHeaders(url: url))
        
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
}
