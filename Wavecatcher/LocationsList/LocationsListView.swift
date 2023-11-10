//
//  LocationsListView.swift
//  Wavecatcher
//

import SwiftUI
import ComposableArchitecture

struct LocationsListView: View {
    
    @State var store: StoreOf<LocationsListFeature>
    
    init(store: StoreOf<LocationsListFeature>) {
        self.store = store
    }
    
    init(state: LocationsListFeature.State) {
        self.store = Store(initialState: state, reducer: { LocationsListFeature() })
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                TabView(selection: viewStore.binding(get: \.selectedLocationID, send: LocationsListFeature.Action.selectLocation).animation(.smooth) ) {
                    ForEach(viewStore.state.locations) { location in
                        LocationForecastView(state: .init(location: location))
                            .tag((location.id as SavedLocation.ID?))
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                Spacer(minLength: 0.0)
                Divider()
                bottomToolbar(viewStore.state)
            }
            .background {
                Color.blue.ignoresSafeArea()
            }
            .task {
                await viewStore.send(.task).finish()
            }
        }
    }
    
    private func bottomToolbar(_ state: LocationsListFeature.State) -> some View {
        HStack {
            Button(action: { store.send(.openSettings) }, label: {
                Image(systemName: "gear")
            })
            .foregroundStyle(.primary)
            
            Spacer()
            // TODO: - Add page controll
            // Spacer()
            
            Menu(content: {
                Button(role: .destructive, action: { store.send(.deleteSelectedLocation) }, label: { Label("Delete Location", systemImage: "trash")})
                Button(action: { store.send(.addLocation) }, label: { Label("Add Location", systemImage: "plus")})
            }, label: {
                Image(systemName: "ellipsis.circle")
            })
            .foregroundStyle(.primary)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct LocationsListView_Previews: PreviewProvider {
    static var previews: some View {
        LocationsListView(state: .init())
    }
}
