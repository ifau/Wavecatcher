//
//  OpenMeteoClient+ErrorResponse.swift
//  Wavecatcher
//

import Foundation

extension OpenMeteoClient {
    
    struct ErrorResponse: Codable {
        let error: Bool
        let reason: String
        
        enum CodingKeys: String, CodingKey {
            case error = "error"
            case reason = "reason"
        }
    }
}
