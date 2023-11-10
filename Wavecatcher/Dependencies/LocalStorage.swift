//
//  LocalStorage.swift
//  Wavecatcher
//

import Foundation
import ComposableArchitecture

struct LocalStorage {
    var fetchLocations: () async throws -> [SavedLocation]
    var saveLocation: (_ location: SavedLocation) async throws -> Void
    var deleteLocation: (_ location: SavedLocation) async throws -> Void
    var wasUpdated: @Sendable () async -> AsyncStream<Void>
}

extension DependencyValues {
    var localStorage: LocalStorage {
        get { self[LocalStorage.self] }
        set { self[LocalStorage.self] = newValue }
    }
}

extension LocalStorage: DependencyKey {
    
    static let liveValue: LocalStorage = {
        // FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: <your_app_group>)
        let databaseFileURL = URL.documentsDirectory.appending(component: "db.sqlite")
        let coreDataStorage = CoreDataStorage(storeType: .file(databaseFileURL))

        return LocalStorage(fetchLocations: coreDataStorage.fetchLocations,
                            saveLocation: coreDataStorage.insertOrUpdate(savedLocation:),
                            deleteLocation: coreDataStorage.delete(savedLocation:),
                            wasUpdated: { coreDataStorage.hasChanges }
        )
    }()
    
    static let testValue: LocalStorage = {
        .init(fetchLocations: unimplemented("\(Self.self).fetchLocations"),
              saveLocation: unimplemented("\(Self.self).saveLocation"),
              deleteLocation: unimplemented("\(Self.self).deleteLocation"),
              wasUpdated: unimplemented("\(Self.self).fetchLocations")
        )
    }()
}
