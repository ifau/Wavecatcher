//
//  SettingsView.swift
//  Wavecatcher
//

import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
    
    let store: StoreOf<SettingsFeature>
    
    init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }
    
    init(state: SettingsFeature.State) {
        self.store = Store(initialState: state, reducer: { SettingsFeature() })
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationStack {
                List {
                    Section("Locations settings") {
                        ForEach(viewStore.locations) { location in
                            locationRow(location)
                        }
                        .onMove { viewStore.send(.changeLocationOrder($0, $1)) }
                    }
                }
                .navigationTitle("Settings")
            }
        }
    }
    
    private func locationRow(_ location: SavedLocation) -> some View {
        HStack {
            Text(location.title)
            Spacer()
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView(state: .init(locations: .init(uniqueElements: SavedLocation.previewData)))
}
