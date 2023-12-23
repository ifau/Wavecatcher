//
//  WavecatcherApp.swift
//  Wavecatcher
//

import SwiftUI
import ComposableArchitecture

@main
struct WavecatcherApp: App {
    
    var body: some Scene {
        WindowGroup {
            if _XCTIsTesting {
                EmptyView()
            } else {
                AppView(store: Store(initialState: AppFeature.State(), reducer: { AppFeature() }))
            }
        }
    }
}

