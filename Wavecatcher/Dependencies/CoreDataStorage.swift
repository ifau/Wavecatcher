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
    private var hasChangesContinuation: AsyncStream<Void>.Continuation?
    lazy var hasChanges: AsyncStream<Void> = {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { [weak self] (continuation: AsyncStream<Void>.Continuation) -> Void in
            self?.hasChangesContinuation = continuation
        }
    }()
    
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
    
    deinit {
        hasChangesContinuation?.finish()
    }
}

// MARK: - Queries

extension CoreDataStorage {
    
    func fetchLocations() async throws -> [SavedLocation] {
        if case .failure(let loadStoreError) = await loadStoreTask.result { throw loadStoreError }
        
        let fetchRequest: NSFetchRequest<SavedLocationMO> = NSFetchRequest(entityName: SavedLocationMO.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: SavedLocationMO.Attributes.dateCreated, ascending: false)]
        
        let result = try mainContext.fetch(fetchRequest).compactMap { $0.plainStruct }
        return result
    }
    
    func insertOrUpdate(savedLocation: SavedLocation) async throws {
        if case .failure(let loadStoreError) = await loadStoreTask.result { throw loadStoreError }
            
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = rootSavingContext
            
        try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<SavedLocationMO> = NSFetchRequest(entityName: SavedLocationMO.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K.%K == %@", argumentArray: [SavedLocationMO.Relationships.location, LocationMO.Attributes.identifier, savedLocation.location.id.rawValue])
            fetchRequest.fetchLimit = 1
            
            var savedLocationMO: SavedLocationMO? = try backgroundContext.fetch(fetchRequest).first
            if case .none = savedLocationMO {
                savedLocationMO = NSEntityDescription.insertNewObject(forEntityName: SavedLocationMO.entityName, into: backgroundContext) as? SavedLocationMO
            }
            guard let savedLocationMO else { return }
            
            var locationMO = savedLocationMO.location
            if case .none = locationMO {
                locationMO = NSEntityDescription.insertNewObject(forEntityName: LocationMO.entityName, into: backgroundContext) as? LocationMO
            }
            locationMO?.fill(from: savedLocation.location)
            
            savedLocationMO.weather?
                .compactMap { $0 as? WeatherDataMO }
                .forEach { backgroundContext.delete($0) }
            
            let weatherMO = savedLocation.weather
                .compactMap { weatherData -> WeatherDataMO? in
                    let weatherDataMO = NSEntityDescription.insertNewObject(forEntityName: WeatherDataMO.entityName, into: backgroundContext) as? WeatherDataMO
                    weatherDataMO?.fill(from: weatherData)
                    return weatherDataMO
                }
            
            savedLocationMO.location = locationMO
            savedLocationMO.weather = NSSet(array: weatherMO)
            savedLocationMO.dateCreated = savedLocation.dateCreated
            savedLocationMO.dateUpdated = savedLocation.dateUpdated
            
            guard backgroundContext.hasChanges else { return }
            try backgroundContext.save()
            backgroundContext.reset()
        }
        
        guard rootSavingContext.hasChanges else { return }
        try rootSavingContext.save()
        hasChangesContinuation?.yield()
    }
    
    func delete(savedLocation: SavedLocation) async throws {
        if case .failure(let loadStoreError) = await loadStoreTask.result { throw loadStoreError }
        
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = rootSavingContext
            
        try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<SavedLocationMO> = NSFetchRequest(entityName: SavedLocationMO.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K.%K == %@", argumentArray: [SavedLocationMO.Relationships.location, LocationMO.Attributes.identifier, savedLocation.location.id.rawValue])
            fetchRequest.fetchLimit = 1
            
            guard let savedLocationMO: SavedLocationMO = try backgroundContext.fetch(fetchRequest).first else { return }
            backgroundContext.delete(savedLocationMO)
            
            guard backgroundContext.hasChanges else { return }
            try backgroundContext.save()
            backgroundContext.reset()
        }
        
        guard rootSavingContext.hasChanges else { return }
        try rootSavingContext.save()
        hasChangesContinuation?.yield()
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
                    LocationMO.Attributes.latitude:.double,
                    LocationMO.Attributes.longitude:.double,
                    LocationMO.Attributes.offshorePerpendicular:.double,
                    LocationMO.Attributes.title:.string
                ])
                
                let weatherDataEntity = NSEntityDescription.description(className: WeatherDataMO.entityName, attributes: [
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
                
                let savedLocationEntity = NSEntityDescription.description(className: SavedLocationMO.entityName, attributes: [
                    SavedLocationMO.Attributes.dateCreated:.date,
                    SavedLocationMO.Attributes.dateUpdated:.date
                ], relationships: [
                    (SavedLocationMO.Relationships.location, entity: locationEntity, maxCount: 1, deleteRule: .cascadeDeleteRule),
                    (SavedLocationMO.Relationships.weather, entity: weatherDataEntity, maxCount: 0, deleteRule: .cascadeDeleteRule)
                ])
                
                let objectModel = NSManagedObjectModel()
                objectModel.entities = [locationEntity, weatherDataEntity, savedLocationEntity]
                return objectModel
            }
        }
    }
    
    @objc(LocationMO)
    class LocationMO: NSManagedObject {
        @NSManaged var identifier: String?
        @NSManaged var latitude: NSNumber?
        @NSManaged var longitude: NSNumber?
        @NSManaged var offshorePerpendicular: NSNumber?
        @NSManaged var title: String?
        
        static var entityName: String { "LocationMO" }
        enum Attributes {
            static let identifier = "identifier"
            static let latitude = "latitude"
            static let longitude = "longitude"
            static let offshorePerpendicular = "offshorePerpendicular"
            static let title = "title"
        }
    }
    
    @objc(WeatherDataMO)
    class WeatherDataMO: NSManagedObject {
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
    
    @objc(SavedLocationMO)
    class SavedLocationMO: NSManagedObject {
        @NSManaged var location: LocationMO?
        @NSManaged var dateCreated: Date?
        @NSManaged var dateUpdated: Date?
        @NSManaged var weather: NSSet?
        
        static var entityName: String { "SavedLocationMO" }
        enum Attributes {
            static let dateCreated = "dateCreated"
            static let dateUpdated = "dateUpdated"
        }
        enum Relationships {
            static let location = "location"
            static let weather = "weather"
        }
    }
}

// MARK: - Helpers

extension NSEntityDescription {
    
    static func description(className: String,
                            attributes: [String:NSAttributeDescription.AttributeType],
                            relationships: [(String, entity: NSEntityDescription, maxCount: Int, deleteRule: NSDeleteRule)] = []) -> NSEntityDescription {
        
        let entity = NSEntityDescription()
        entity.name = className
        entity.managedObjectClassName = className
        
        attributes.forEach { attribute in
            let attributeDescription = NSAttributeDescription()
            attributeDescription.name = attribute.key
            attributeDescription.type = attribute.value
            entity.properties.append(attributeDescription)
        }
        
        relationships.forEach { relationship in
            let relationshipDescription = NSRelationshipDescription()
            relationshipDescription.name = relationship.0
            relationshipDescription.destinationEntity = relationship.entity
            relationshipDescription.maxCount = relationship.maxCount
            relationshipDescription.deleteRule = relationship.deleteRule
            entity.properties.append(relationshipDescription)
        }
        
        return entity
    }
}

extension CoreDataStorage.LocationMO {
    
    var plainStruct: Location? {
        guard let identifier else { return nil }
        guard let latitude else { return nil }
        guard let longitude else { return nil }
        guard let offshorePerpendicular else { return nil }
        guard let title else { return nil }
        return Location(id: Location.Id(rawValue: identifier), latitude: latitude.doubleValue, longitude: longitude.doubleValue, offshorePerpendicular: offshorePerpendicular.doubleValue, title: title)
    }
    
    func fill(from location: Location) {
        identifier = location.id.rawValue
        latitude = NSNumber(value: location.latitude)
        longitude = NSNumber(value: location.longitude)
        offshorePerpendicular = NSNumber(value: location.offshorePerpendicular)
        title = location.title
    }
}

extension CoreDataStorage.WeatherDataMO {
    
    var plainStruct: WeatherData? {
        guard let date else { return nil }
        
        return WeatherData(date: date, airTemperature: airTemperature?.doubleValue, windDirection: windDirection?.doubleValue, windSpeed: windSpeed?.doubleValue, windGust: windGust?.doubleValue, swellDirection: swellDirection?.doubleValue, swellPeriod: swellPeriod?.doubleValue, swellHeight: swellHeight?.doubleValue, tideHeight: tideHeight?.doubleValue)
    }
    
    func fill(from weatherData: WeatherData) {
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

extension CoreDataStorage.SavedLocationMO {
    
    var plainStruct: SavedLocation? {
        guard let location = location?.plainStruct else { return nil }
        guard let dateCreated else { return nil }
        guard let dateUpdated else { return nil }
        
        let weather = (self.weather ?? NSSet())
            .map { $0 as? CoreDataStorage.WeatherDataMO }
            .compactMap { $0?.plainStruct }
        
        return SavedLocation(location: location, dateCreated: dateCreated, dateUpdated: dateUpdated, weather: weather)
    }
}
