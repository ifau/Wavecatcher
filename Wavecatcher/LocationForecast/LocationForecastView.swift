//
//  LocationForecastView.swift
//  Wavecatcher
//

import SwiftUI
import ComposableArchitecture

struct LocationForecastView: View {
    
    let store: StoreOf<LocationForecastFeature>
    
    init(store: StoreOf<LocationForecastFeature>) {
        self.store = store
    }
    
    init(state: LocationForecastFeature.State) {
        self.store = Store(initialState: state, reducer: { LocationForecastFeature() })
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    switch viewStore.displayState {
                    case .notRequested:
                        Rectangle()
                            .hidden()
                            .onAppear { viewStore.send(.viewAppear) }
                        
                    case .failed(_):
                        errorHeader(viewStore.state)
                        errorView(viewStore.state)
                    case .loading:
                        loadingHeader(viewStore.state)
                    case .loaded:
                        header(viewStore.state)
                        content(viewStore.state)
                    }
                }
                .padding(.top, 32)
                .padding([.horizontal, .bottom])
            }
        }
    }
    
    // MARK: - Headers
    
    private func header(_ state: LocationForecastFeature.State) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Text(state.location.title)
                .font(.system(size: 30))
                .foregroundStyle(.white)
                .shadow(radius: 8)
            
            Text((state.location.weather.nowData()?.swellHeight ?? 0.0).formatted(.number.precision(.fractionLength(0...1))) + "m")
                .font(.system(size: 64))
                .foregroundStyle(.white)
                .shadow(radius: 8)
            
            HStack {
                if let nowData = state.location.weather.nowData(),
                   let swellHeight = nowData.swellHeight,
                   let swellPeriod = nowData.swellPeriod,
                   let swellDirection = nowData.swellDirection {
                    HStack(spacing: 4.0) {
                        Text(swellHeight.formatted(.number.precision(.fractionLength(0...1))) + "m")
                            .foregroundStyle(.primary)
                            .shadow(radius: 8)
                        Text(swellPeriod.formatted(.number.precision(.fractionLength(0))) + "s")
                            .foregroundStyle(.primary)
                            .shadow(radius: 8)
                    }
                    
                    Image(systemName: "location.north.fill")
                        .rotationEffect(.degrees(swellDirection))
                        .foregroundStyle(.primary)
                        .shadow(radius: 8)
                
                    HStack(spacing: 4.0) {
                        Text(swellDirection.formatted(.cardinalDirection))
                            .foregroundStyle(.primary)
                            .shadow(radius: 8)
                        Text(swellDirection.formatted(.number.precision(.fractionLength(0))) + "°")
                            .foregroundStyle(.secondary)
                            .shadow(radius: 8)
                    }
                }
            }
            .font(.system(size: 22))
            .foregroundStyle(.white)
        }
        .bold()
    }
    
    private func loadingHeader(_ state: LocationForecastFeature.State) -> some View {
        VStack(alignment: .center, spacing: 32) {
            Text(state.location.title)
                .font(.system(size: 30))
                .foregroundStyle(.white)
                .shadow(radius: 8)
            
            VStack(spacing: 8.0) {
                Text("Loading...")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
                
                Text("Last updated \(state.location.dateUpdated.formatted(.relative(presentation: .named, unitsStyle: .spellOut)))")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
            }
        }
        .bold()
    }
    
    private func errorHeader(_ state: LocationForecastFeature.State) -> some View {
        VStack(alignment: .center, spacing: 32) {
            Text(state.location.title)
                .font(.system(size: 30))
                .foregroundStyle(.white)
                .shadow(radius: 8)
        }
        .bold()
    }
    
    // MARK: - Content
    
    private func content(_ state: LocationForecastFeature.State) -> some View {
        VStack {
            LocationForecastSectionView(titleView: { sectionHeader(title: "Hourly forecast", systemImageName: "clock")}, contentView: {
                HourlyForecastView(weatherData: state.location.weather)
                    .padding([.horizontal, .bottom])
            })
            HStack {
                LocationForecastSectionView(titleView: { sectionHeader(title: "Tide", systemImageName: "water.waves")}, contentView: {
                    TideForecastView(weatherData: state.location.weather)
                        .padding(.bottom)
                })
                LocationForecastSectionView(titleView: { sectionHeader(title: "Wind", systemImageName: "wind")}, contentView: {
                    WindForecastView(weatherData: state.location.weather)
                        .padding(.bottom)
                })
            }
        }
    }
    
    private func sectionHeader(title: String, systemImageName: String) -> some View {
        HStack {
            Label(
                title: { Text(title) },
                icon: { Image(systemName: systemImageName) }
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    private func errorView(_ state: LocationForecastFeature.State) -> some View {
        VStack(alignment: .leading) {
            Text("An error has occured")
                .font(.callout)
                .foregroundStyle(.secondary)
            Divider()
            if case .failed(let error) = state.displayState {
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            
            Button(action: { store.send(.tryAgainButtonPressed) }, label: {
                Text("Try again")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
            })
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}


struct LocationForecastView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LocationForecastView(state: .init(location: SavedLocation.previewData.first!, displayState: .loading))
                .previewDisplayName("Loading")
            LocationForecastView(state: .init(location: SavedLocation.previewData.first!, displayState: .loaded))
                .previewDisplayName("Loaded")
            LocationForecastView(state: .init(location: SavedLocation.previewData.first!, displayState: .failed(URLError(URLError.notConnectedToInternet))))
                .previewDisplayName("Error")
        }
    }
}
