//
//  CoreDataStorage.swift
//  Wavecatcher
//

import Foundation
import CoreData

final class CoreDataStorage {
    
    private let coordinator: NSPersistentStoreCoordinator
    private let rootSavingContext: NSManagedObjectContext
    private let mainContext: NSManagedObjectContext
    
    private var loadStoreTask: Task<Void, Error>
    
    init(storeType: CoreDataStorage.PersistentStoreType, modelVersion: CoreDataStorage.ModelVersion = .actual) {

        coordinator = NSPersistentStoreCoordinator(managedObjectModel: modelVersion.model)
        
        rootSavingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        rootSavingContext.persistentStoreCoordinator = coordinator
        
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.parent = rootSavingContext
        mainContext.automaticallyMergesChangesFromParent = true
        
        let storeDescription: NSPersistentStoreDescription
        switch storeType {
        case .file(let fileURL):
            storeDescription = NSPersistentStoreDescription(url: fileURL)
        case .inMemory:
            storeDescription = NSPersistentStoreDescription()
            storeDescription.type = NSInMemoryStoreType
            storeDescription.configuration = "Default"
        }
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        
        loadStoreTask = Task<Void, Error> { [unowned coordinator] in
            try await withUnsafeThrowingContinuation { continuation in
                coordinator.addPersistentStore(with: storeDescription) { (storeDescription, storeDescriptionError) in
                    switch storeDescriptionError {
                    case .none: continuation.resume()
                    case .some(let error): continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

// MARK: - Queries

extension CoreDataStorage {
    
    func fetchLocations() async throws -> [Location] {
        if case .failure(let loadStoreError) = await loadStoreTask.result { throw loadStoreError }
        
        let fetchRequest: NSFetchRequest<LocationMO> = NSFetchRequest(entityName: LocationMO.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: LocationMO.Attributes.dateCreated, ascending: false)]
        
        let result = try mainContext.fetch(fetchRequest).compactMap { $0.plainStruct }
        return result
    }
    
    func insertOrUpdate(location: Location) async throws {
        if case .failure(let loadStoreError) = await loadStoreTask.result { throw loadStoreError }
            
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = rootSavingContext
            
        try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<LocationMO> = NSFetchRequest(entityName: LocationMO.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == %@", argumentArray: [LocationMO.Attributes.identifier, location.id.rawValue])
            fetchRequest.fetchLimit = 1
            
            var locationMO: LocationMO? = try backgroundContext.fetch(fetchRequest).first
            if case .none = locationMO {
                locationMO = NSEntityDescription.insertNewObject(forEntityName: LocationMO.entityName, into: backgroundContext) as? LocationMO
                locationMO?.dateCreated = Date.now
            }
            guard let locationMO else { return }
            locationMO.fill(from: location)
            
            guard backgroundContext.hasChanges else { return }
            try backgroundContext.save()
            backgroundContext.reset()
        }
        
        guard rootSavingContext.hasChanges else { return }
        try rootSavingContext.save()
    }
    
    func delete(location: Location) async throws {
        if case .failure(let loadStoreError) = await loadStoreTask.result { throw loadStoreError }
        
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = rootSavingContext
            
        try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<LocationMO> = NSFetchRequest(entityName: LocationMO.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == %@", argumentArray: [LocationMO.Attributes.identifier, location.id.rawValue])
            fetchRequest.fetchLimit = 1
            
            guard let locationMO: LocationMO = try backgroundContext.fetch(fetchRequest).first else { return }
            backgroundContext.delete(locationMO)
            
            guard backgroundContext.hasChanges else { return }
            try backgroundContext.save()
            backgroundContext.reset()
        }
        
        guard rootSavingContext.hasChanges else { return }
        try rootSavingContext.save()
    }
    
    func fetchWeather(for location: Location) async throws -> [WeatherData] {
        if case .failure(let loadStoreError) = await loadStoreTask.result { throw loadStoreError }
        
        let fetchRequest: NSFetchRequest<WeatherDataMO> = NSFetchRequest(entityName: WeatherDataMO.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", argumentArray: [WeatherDataMO.Attributes.locationId, location.id.rawValue])
        
        let result = try mainContext.fetch(fetchRequest).compactMap { $0.plainStruct }
        return result
    }
    
    func deleteAndInsertWeather(_ weatherData: [WeatherData], for location: Location) async throws {
        if case .failure(let loadStoreError) = await loadStoreTask.result { throw loadStoreError }
        
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = rootSavingContext
            
        try await backgroundContext.perform {
            
            let deleteFetchRequest: NSFetchRequest<WeatherDataMO> = NSFetchRequest(entityName: WeatherDataMO.entityName)
            deleteFetchRequest.predicate = NSPredicate(format: "%K == %@", argumentArray: [WeatherDataMO.Attributes.locationId, location.id.rawValue])
            
            // Doesn't work for .inMemory store type
            // try backgroundContext.execute(NSBatchDeleteRequest(fetchRequest: deleteFetchRequest))
            let objectsForDelete = try backgroundContext.fetch(deleteFetchRequest)
            objectsForDelete.forEach { backgroundContext.delete($0) }
            
            weatherData.forEach { weather in
                let weatherDataMO = NSEntityDescription.insertNewObject(forEntityName: WeatherDataMO.entityName, into: backgroundContext) as? WeatherDataMO
                weatherDataMO?.fill(from: weather)
            }
            
            guard backgroundContext.hasChanges else { return }
            try backgroundContext.save()
            backgroundContext.reset()
        }
        
        guard rootSavingContext.hasChanges else { return }
        try rootSavingContext.save()
    }
}

// MARK: - Model Configuration

extension CoreDataStorage {
    
    enum PersistentStoreType {
        case inMemory
        case file(URL)
    }
    
    enum ModelVersion {
        case v1
        static var actual: Self { .v1 }
        
        var model: NSManagedObjectModel {
            switch self {
            case .v1:
                let locationEntity = NSEntityDescription.description(className: LocationMO.entityName, attributes: [
                    LocationMO.Attributes.identifier:.string,
                    LocationMO.Attributes.dateCreated:.date,
                    LocationMO.Attributes.latitude:.double,
                    LocationMO.Attributes.longitude:.double,
                    LocationMO.Attributes.title:.string
                ])
                
                let weatherDataEntity = NSEntityDescription.description(className: WeatherDataMO.entityName, attributes: [
                    WeatherDataMO.Attributes.locationId:.string,
                    WeatherDataMO.Attributes.date:.date,
                    WeatherDataMO.Attributes.airTemperature:.double,
                    WeatherDataMO.Attributes.windDirection:.double,
                    WeatherDataMO.Attributes.windSpeed:.double,
                    WeatherDataMO.Attributes.windGust:.double,
                    WeatherDataMO.Attributes.swellDirection:.double,
                    WeatherDataMO.Attributes.swellPeriod:.double,
                    WeatherDataMO.Attributes.swellHeight:.double,
                    WeatherDataMO.Attributes.tideHeight:.double
                ])
                
                let objectModel = NSManagedObjectModel()
                objectModel.entities = [locationEntity, weatherDataEntity]
                return objectModel
            }
        }
    }
    
    @objc(LocationMO)
    class LocationMO: NSManagedObject {
        @NSManaged var identifier: String?
        @NSManaged var dateCreated: Date?
        
        @NSManaged var latitude: NSNumber?
        @NSManaged var longitude: NSNumber?
        @NSManaged var title: String?
        
        static var entityName: String { "LocationMO" }
        enum Attributes {
            static let identifier = "identifier"
            static let dateCreated = "dateCreated"
            static let latitude = "latitude"
            static let longitude = "longitude"
            static let title = "title"
        }
    }
    
    @objc(WeatherDataMO)
    class WeatherDataMO: NSManagedObject {
        @NSManaged var locationId: String?
        @NSManaged var date: Date?
        
        @NSManaged var airTemperature: NSNumber?
        @NSManaged var windDirection: NSNumber?
        @NSManaged var windSpeed: NSNumber?
        @NSManaged var windGust: NSNumber?
        
        @NSManaged var swellDirection: NSNumber?
        @NSManaged var swellPeriod: NSNumber?
        @NSManaged var swellHeight: NSNumber?
        
        @NSManaged var tideHeight: NSNumber?
        
        static var entityName: String { "WeatherDataMO" }
        enum Attributes {
            static let locationId = "locationId"
            static let date = "date"
            static let airTemperature = "airTemperature"
            static let windDirection = "windDirection"
            static let windSpeed = "windSpeed"
            static let windGust = "windGust"
            static let swellDirection = "swellDirection"
            static let swellPeriod = "swellPeriod"
            static let swellHeight = "swellHeight"
            static let tideHeight = "tideHeight"
        }
    }
}

// MARK: - Helpers

extension NSEntityDescription {
    
    static func description(className: String, attributes: [String:NSAttributeDescription.AttributeType]) -> NSEntityDescription {
        
        let entity = NSEntityDescription()
        entity.name = className
        entity.managedObjectClassName = className
        
        attributes.forEach { attribute in
            let attributeDescription = NSAttributeDescription()
            attributeDescription.name = attribute.key
            attributeDescription.type = attribute.value
            entity.properties.append(attributeDescription)
        }
        
        return entity
    }
}

extension CoreDataStorage.LocationMO {
    
    var plainStruct: Location? {
        guard let identifier else { return nil }
        guard let latitude else { return nil }
        guard let longitude else { return nil }
        guard let title else { return nil }
        return Location(id: Location.Id(rawValue: identifier), latitude: latitude.doubleValue, longitude: longitude.doubleValue, title: title)
    }
    
    func fill(from location: Location) {
        identifier = location.id.rawValue
        latitude = NSNumber(value: location.latitude)
        longitude = NSNumber(value: location.longitude)
        title = location.title
    }
}

extension CoreDataStorage.WeatherDataMO {
    
    var plainStruct: WeatherData? {
        guard let locationId else { return nil }
        guard let date else { return nil }
        
        return WeatherData(locationId: Location.ID(rawValue: locationId), date: date, airTemperature: airTemperature?.doubleValue, windDirection: windDirection?.doubleValue, windSpeed: windSpeed?.doubleValue, windGust: windGust?.doubleValue, swellDirection: swellDirection?.doubleValue, swellPeriod: swellPeriod?.doubleValue, swellHeight: swellHeight?.doubleValue, tideHeight: tideHeight?.doubleValue)
    }
    
    func fill(from weatherData: WeatherData) {
        locationId = weatherData.locationId.rawValue
        date = weatherData.date
        
        if let value = weatherData.airTemperature {
            airTemperature = NSNumber(value: value)
        } else {
            airTemperature = nil
        }
        
        if let value = weatherData.windDirection {
            windDirection = NSNumber(value: value)
        } else {
            windDirection = nil
        }
        
        if let value = weatherData.windSpeed {
            windSpeed = NSNumber(value: value)
        } else {
            windSpeed = nil
        }
        
        if let value = weatherData.windGust {
            windGust = NSNumber(value: value)
        } else {
            windGust = nil
        }
        
        if let value = weatherData.swellDirection {
            swellDirection = NSNumber(value: value)
        } else {
            swellDirection = nil
        }
        
        if let value = weatherData.swellPeriod {
            swellPeriod = NSNumber(value: value)
        } else {
            swellPeriod = nil
        }
        
        if let value = weatherData.swellHeight {
            swellHeight = NSNumber(value: value)
        } else {
            swellHeight = nil
        }
        
        if let value = weatherData.tideHeight {
            tideHeight = NSNumber(value: value)
        } else {
            tideHeight = nil
        }
    }
}
