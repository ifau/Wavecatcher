//
//  AddLocationView.swift
//  Wavecatcher
//

import SwiftUI
import ComposableArchitecture

struct AddLocationView: View {
    
    @State var store: StoreOf<AddLocationFeature>
    
    init(store: StoreOf<AddLocationFeature>) {
        self.store = store
    }
    
    init(state: AddLocationFeature.State) {
        self.store = Store(initialState: state, reducer: { AddLocationFeature() })
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Add location")
        }
    }
    
    private var content: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            
            switch viewStore.displayState {
            case .notRequested:
                Rectangle()
                    .hidden()
                    .onAppear { viewStore.send(.viewAppear) }
                
            case .loading:
                ProgressView()
            
            case .failed(let error):
                ContentUnavailableView {
                    Text("An error has occured")
                        .font(.headline)
                } description: {
                    Text(error.localizedDescription)
                        .font(.subheadline)
                    
                    Button(action: { viewStore.send(.tryAgainButtonPressed) }, label: {
                        Text("Try again")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
                    })
                }
                
            case .loaded:
                List {
                    ForEach(viewStore.searchResults) { location in
                        locationRow(location, state: viewStore.state)
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if !viewStore.searchQuery.isEmpty, viewStore.searchResults.isEmpty {
                        ContentUnavailableView.search(text: viewStore.searchQuery)
                    }
                }
                .searchable(text: viewStore.binding(get: \.searchQuery, send: AddLocationFeature.Action.searchQueryChanged),
                            isPresented: viewStore.binding(get: \.searchIsActive, send: AddLocationFeature.Action.searchStateChanged))
                .toolbar {
                    Button("Add", action: { viewStore.send(.addSelectedLocation) })
                        .bold()
                        .disabled(viewStore.selectedLocationID == nil)
                }
            }
        }
    }
    
    private func locationRow(_ location: Location, state: AddLocationFeature.State) -> some View {
        HStack {
            Text(location.title)
            Spacer()
            if location.id == state.selectedLocationID {
                Image(systemName: "checkmark")
            }
        }
        .listRowBackground((location.id == state.selectedLocationID) ? Color(UIColor.systemGray4) : nil)
        .foregroundStyle((state.savedLocations[id: location.id] == nil) ? .primary : .secondary)
        .contentShape(Rectangle())
        .onTapGesture(perform: { store.send(.locationTap(location.id)) })
    }
}

struct AddLocationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddLocationView(state: .init(displayState: .loading))
                .previewDisplayName("Loading")
            AddLocationView(state: .init(locations: .init(uniqueElements: Location.previewData), displayState: .loaded))
                .previewDisplayName("Loaded")
            AddLocationView(state: .init(displayState: .failed(URLError(URLError.notConnectedToInternet))))
                .previewDisplayName("Error")
        }
    }
}
