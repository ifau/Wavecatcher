//
//  LocationSettingsFeature.swift
//  Wavecatcher
//

import SwiftUI
import PhotosUI
import ComposableArchitecture

struct LocationSettingsFeature: Reducer {
    
    struct State: Equatable {
        let location: SavedLocation
        var selectedBackground: BackgroundVariant
        var isLoadingPhotosPickerItem: Bool = false
        
        var isSaveActionAvailable: Bool { selectedBackground != location.customBackground }
    }
    
    enum Action: Equatable {
        case selectBackground(BackgroundVariant)
        case selectPhotosPickerItem(PhotosPickerItem?)
        case loadPhotosPickerItemComplete(TaskResult<URL>)
        case saveChanges
    }
    
    @Dependency(\.photosAssetsLoader) var photosAssetsLoader
    @Dependency(\.localStorage) var localStorage
    @Dependency(\.isPresented) var isPresented
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .selectBackground(let background):
                guard !state.isLoadingPhotosPickerItem else { return .none }
                state.selectedBackground = background
                return .none
                
            case .selectPhotosPickerItem(let pickerItem):
                guard let pickerItem else { return .none }
                guard !state.isLoadingPhotosPickerItem else { return .none }
                state.isLoadingPhotosPickerItem = true
                
                return .run { send in
                    await send(.loadPhotosPickerItemComplete(TaskResult {
                        try await photosAssetsLoader.loadPhotosPickerItem(pickerItem)
                    }))
                }
                
            case .loadPhotosPickerItemComplete(.success(let loadedURL)):
                state.isLoadingPhotosPickerItem = false
                return .send(.selectBackground(.video(.init(fileName: loadedURL.lastPathComponent))))
                
            case .loadPhotosPickerItemComplete(.failure(_)):
                state.isLoadingPhotosPickerItem = false
                return .none
                
            case .saveChanges:
                return .run { [location = state.location, newBackground = state.selectedBackground] _ in
                    var mutableLocation = location
                    mutableLocation.customBackground = newBackground
                    
                    try? await localStorage.saveLocations([mutableLocation])
                    
                    guard isPresented else { return }
                    await self.dismiss()
                }
            }
        }
    }
}
