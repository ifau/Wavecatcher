//
//  AppError.swift
//  Wavecatcher
//

import Foundation

enum AppError: Error {
    case failedLoadAsset
    case failedGetSpotId
    case failedBuildURL(host: String?)
    case receivedErrorResponse(host: String?, response: String?)
    case receivedEmptyResponse
}

extension AppError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .failedLoadAsset:
            return String(localized: "ErrorDescriptionFailedLoadAsset")
        case .failedGetSpotId:
            return String(localized: "ErrorDescriptionFailedGetSpotId")
        case .failedBuildURL(let host):
            return String(localized: "ErrorDescriptionFailedBuildURL \(host ?? "")")
        case .receivedErrorResponse(let host, let response):
            return String(localized: "ErrorDescriptionReceivedErrorResponse \(host ?? "") \(response ?? "")")
        case .receivedEmptyResponse:
            return String(localized: "ErrorDescriptionReceivedEmptyResponse")
        }
    }
}
