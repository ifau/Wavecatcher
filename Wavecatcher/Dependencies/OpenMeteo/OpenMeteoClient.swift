//
//  OpenMeteoClient.swift
//  Wavecatcher
//

import Foundation

final class OpenMeteoClient {
    
    let urlSession = URLSession(configuration: URLSessionConfiguration.ephemeral)
    
    func getMarineForecast(latitude: Double, longitude: Double) async throws -> MarineResponse {

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "marine-api.open-meteo.com"
        urlComponents.path = "/v1/marine"
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: latitude.formatted(.coordinates(precision: 5))),
            URLQueryItem(name: "longitude", value: longitude.formatted(.coordinates(precision: 5))),
            URLQueryItem(name: "hourly", value: "wave_height,wave_direction,wave_period,swell_wave_height,swell_wave_direction,swell_wave_period"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "3")
        ]
        
        guard let url = urlComponents.url else {
            throw AppError.failedBuildURL(host: urlComponents.host)
        }
        
        let (data, _) = try await urlSession.data(from: url)
        
        do {
            return try JSONDecoder().decode(MarineResponse.self, from: data)
        } catch {
            guard let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) else { throw error }
            throw AppError.receivedErrorResponse(host: urlComponents.host, response: errorResponse.reason)
        }
    }
    
    func getWeatherForecast(latitude: Double, longitude: Double) async throws -> ForecastResponse {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.open-meteo.com"
        urlComponents.path = "/v1/forecast"
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: latitude.formatted(.coordinates(precision: 5))),
            URLQueryItem(name: "longitude", value: longitude.formatted(.coordinates(precision: 5))),
            URLQueryItem(name: "hourly", value: "temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "3")
        ]
        
        guard let url = urlComponents.url else {
            throw AppError.failedBuildURL(host: urlComponents.host)
        }
        
        let (data, _) = try await urlSession.data(from: url)
        do {
            return try JSONDecoder().decode(ForecastResponse.self, from: data)
        }  catch {
            guard let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) else { throw error }
            throw AppError.receivedErrorResponse(host: urlComponents.host, response: errorResponse.reason)
        }
    }
}
