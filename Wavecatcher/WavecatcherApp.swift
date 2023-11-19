//
//  WavecatcherApp.swift
//  Wavecatcher
//

import SwiftUI

@main
struct WavecatcherApp: App {
    
    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
                LocationsListView(state: .init())
                    .environment(\.safeAreaInsets, geometry.safeAreaInsets)
                    .ignoresSafeArea(.all, edges: .top)
            }
        }
    }
}


private struct SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = .init()
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}
