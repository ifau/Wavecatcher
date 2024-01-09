//
//  LocationForecastView.swift
//  Wavecatcher
//

import SwiftUI
import ComposableArchitecture

struct LocationForecastView: View {
    
    let store: StoreOf<LocationForecastFeature>
    @State private var scrollViewOffset: CGPoint = .zero
    @Environment(\.safeAreaInsets) var safeAreaInsets
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(store: StoreOf<LocationForecastFeature>) {
        self.store = store
    }
    
    init(state: LocationForecastFeature.State) {
        self.store = Store(initialState: state, reducer: { LocationForecastFeature() })
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            OffsetObservingScrollView(axes: .vertical, showsIndicators: false, offset: $scrollViewOffset) {
                VStack {
                    switch viewStore.displayState {
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
                .onAppear {
                    viewStore.send(.viewAppear)
                }
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
                .offset(y: locationTitleOffset)
            
            Text((state.location.weather.nowData()?.waveHeightMax ?? 0.0).formatted(.number.precision(.fractionLength(0...1))) + "m")
                .font(.system(size: 64))
                .foregroundStyle(.white)
                .shadow(radius: 8)
                .opacity(waveHeightOpacity)
            
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
            .opacity(swellDescriptionOpacity)
        }
        .bold()
        .offset(y: headerOffset)
    }
    
    private func loadingHeader(_ state: LocationForecastFeature.State) -> some View {
        VStack(alignment: .center, spacing: 32) {
            Text(state.location.title)
                .font(.system(size: 30))
                .foregroundStyle(.white)
                .shadow(radius: 8)
            
            VStack(spacing: 8.0) {
                Text("locationForecast.text.loading")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
                
                Text("locationForecast.text.lastUpdated \(state.location.dateUpdated.formatted(.relative(presentation: .named, unitsStyle: .spellOut)))")
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
            LocationForecastSectionView(titleView: { sectionHeader(title: "locationForecast.text.hourlyForecast", systemImageName: "clock")}, contentView: {
                HourlyForecastView(weatherData: state.location.weather)
                    .padding([.horizontal, .bottom])
            })
            HStack {
                LocationForecastSectionView(titleView: { sectionHeader(title: "locationForecast.text.tide", systemImageName: "water.waves")}, contentView: {
                    TideForecastView(weatherData: state.location.weather)
                        .padding(.bottom)
                })
                LocationForecastSectionView(titleView: { sectionHeader(title: "locationForecast.text.wind", systemImageName: "wind")}, contentView: {
                    WindForecastView(weatherData: state.location.weather, offshorePerpendicular: state.location.offshorePerpendicular)
                        .padding(.bottom)
                })
            }
        }
    }
    
    private func sectionHeader(title: LocalizedStringKey, systemImageName: String) -> some View {
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
            Text("locationForecast.text.anErrorHasOccured")
                .font(.callout)
                .foregroundStyle(.secondary)
            Divider()
                .frame(maxWidth: horizontalSizeClass == .compact ? .infinity : 320)
            if case .failed(let error) = state.displayState {
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            
            Button(action: { store.send(.tryAgainButtonPressed) }, label: {
                Text("locationForecast.button.tryAgain")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: horizontalSizeClass == .compact ? .infinity : 320)
                    .padding()
                    .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
            })
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

extension LocationForecastView {
    static let distanceToStartCollapseSectionHeaders: CGFloat = 64.0
    private var maximumAllowedDragDistanceForLocationTitle: CGFloat { 16.0 }
    private var dragDistanceToCompletelyHideWaveHeight: CGFloat { 48.0 }
    private var dragDistanceToCompletelyHideSwellDescription: CGFloat { 128.0 }
    
    private var headerOffset: CGFloat {
        guard scrollViewOffset.y < 0 else { return 0.0 } // affect only drag from top to bottom
        let progress = scrollViewOffset.y / 128
        let offset = (progress <= 1 ? progress : 1) * 64
        return offset
    }
    
    private var locationTitleOffset: Double {
        guard scrollViewOffset.y > maximumAllowedDragDistanceForLocationTitle else { return 0.0 }
        return scrollViewOffset.y - maximumAllowedDragDistanceForLocationTitle
    }
    
    private var waveHeightOpacity: Double {
        guard scrollViewOffset.y > 0 else { return 1.0 }
        let value = 1 - scrollViewOffset.y / dragDistanceToCompletelyHideWaveHeight
        return value < 0 ? 0 : value
    }
    
    private var swellDescriptionOpacity: Double {
        guard scrollViewOffset.y > 0 else { return 1.0 }
        let value = 1 - scrollViewOffset.y / dragDistanceToCompletelyHideSwellDescription
        return value < 0 ? 0 : value
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
