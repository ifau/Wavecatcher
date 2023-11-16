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
                background(viewStore.state).ignoresSafeArea()
            }
            .task {
                await viewStore.send(.task).finish()
            }
            .onAppear {
                viewStore.send(.viewAppear)
            }
            .sheet(store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                   state: /LocationsListFeature.Destination.State.settings,
                   action: LocationsListFeature.Destination.Action.settings) { settingsStore in
                SettingsView(store: settingsStore)
            }
            .sheet(store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                   state: /LocationsListFeature.Destination.State.addLocation,
                   action: LocationsListFeature.Destination.Action.addLocation) { addLocationStore in
                AddLocationView(store: addLocationStore)
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
            pageControl(state)
            Spacer()
            
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
    
    private func pageControl(_ state: LocationsListFeature.State) -> some View {
        HStack {
            ForEach(state.locations) { location in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor((location.id == state.selectedLocationID) ? .white : .secondary)
                    .onTapGesture(perform: { store.send(.selectLocation(location.id)) })
            }
        }
    }
    
    @ViewBuilder
    private func background(_ state: LocationsListFeature.State) -> some View {
        if let selectedLocationID = state.selectedLocationID,
           let selectedLocation = state.locations[id: selectedLocationID] {
            
            switch selectedLocation.customBackground {
            case .aurora(let variant): AuroraBackgroundView(variant: variant)
            case .video(let video): VideoPlayerView(videoURL: video.fileURL)
            }
        } else {
            Color.black
        }
    }
}

struct LocationsListView_Previews: PreviewProvider {
    static var previews: some View {
        LocationsListView(state: .init())
    }
}
