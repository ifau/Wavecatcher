//
//  PhotosAssetsLoader.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture
import CryptoKit
import SwiftUI
import PhotosUI

struct PhotosAssetsLoader {
    var loadPhotosPickerItem: (_ item: PhotosPickerItem) async throws -> URL
}

extension DependencyValues {
    var photosAssetsLoader: PhotosAssetsLoader {
        get { self[PhotosAssetsLoader.self] }
        set { self[PhotosAssetsLoader.self] = newValue }
    }
}

extension PhotosAssetsLoader: DependencyKey {
    
    static let liveValue: PhotosAssetsLoader = {
        
        return PhotosAssetsLoader { pickerItem in
            
            // Convert the identifier to a hash since the identifier can contain prohibited symbols for the filesystem
            let identifierHash = SHA256.hash(data: Data((pickerItem.itemIdentifier ?? "").utf8))
                .map { String(format: "%02hhx", $0) }
                .joined()
            
            let fileURL = URL.documentsDirectory.appending(component: identifierHash + ".mp4")
            guard !FileManager.default.fileExists(atPath: fileURL.path()) else { return fileURL }
            
            guard let movie = try await pickerItem.loadTransferable(type: Movie.self) else {
                throw AppError.failedLoadAsset
            }
            
            try FileManager.default.moveItem(at: movie.url, to: fileURL)
            return fileURL
        }
    }()
    
    static let testValue: PhotosAssetsLoader = {
        .init(loadPhotosPickerItem: unimplemented("\(Self.self).loadPhotosPickerItem"))
    }()
}

struct Movie: Transferable {
    let url: URL
    
    static let tempImportURL: URL = {
        URL.cachesDirectory.appendingPathComponent("movie.import.temp")
    }()
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            
            if FileManager.default.fileExists(atPath: tempImportURL.path()) {
                try FileManager.default.removeItem(at: tempImportURL)
            }

            try FileManager.default.copyItem(at: received.file, to: tempImportURL)
            return Self.init(url: tempImportURL)
        }
    }
}
