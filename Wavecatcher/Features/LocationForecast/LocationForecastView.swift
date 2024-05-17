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
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) var locationTitleFontSize = 30.0
    
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
                .font(.system(size: 30 * locationTitleScaleFactor))
                .foregroundStyle(.white)
                .shadow(radius: 8)
                .offset(y: locationTitleOffset)
                .accessibilityAddTraits(.isHeader)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text((state.location.weather.nowData()?.waveHeightMax ?? 0.0).formatted(.number.precision(.fractionLength(0...1))))
                    .font(.system(size: 64 * locationTitleScaleFactor))
                Text("m")
                    .font(.system(size: 42 * locationTitleScaleFactor))
            }
            .foregroundStyle(.white)
            .shadow(radius: 8)
            .opacity(waveHeightOpacity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("locationForecast.text.waveHeight")
            .accessibilityValue(Text(verbatim: "\((state.location.weather.nowData()?.waveHeightMax ?? 0.0).formatted(.number.precision(.fractionLength(0...1))))") + Text("m"))
            
            if let nowData = state.location.weather.nowData(),
               let swellHeight = nowData.swellHeight,
               let swellPeriod = nowData.swellPeriod,
               let swellDirection = nowData.swellDirection {
                HStack {
                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        Text(swellHeight.formatted(.number.precision(.fractionLength(0...1))))
                            .font(.system(size: 22 * locationTitleScaleFactor))
                        Text("m")
                            .font(.system(size: 20 * locationTitleScaleFactor))
                    }
                    .foregroundStyle(.primary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("locationForecast.text.swellHeight")
                    .accessibilityValue(Text(verbatim: "\(swellHeight.formatted(.number.precision(.fractionLength(0...1))))") + Text("m"))
                    
                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        Text(swellPeriod.formatted(.number.precision(.fractionLength(0))))
                            .font(.system(size: 22 * locationTitleScaleFactor))
                        Text("s")
                            .font(.system(size: 20 * locationTitleScaleFactor))
                    }
                    .foregroundStyle(.primary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("locationForecast.text.swellPeriod")
                    .accessibilityValue("\(swellPeriod.formatted(.number.precision(.fractionLength(0))))sec")
                    
                    DirectionIndicatorView(degrees: swellDirection)
                        .foregroundStyle(.primary)
                
                    HStack(spacing: 4.0) {
                        Text(swellDirection.formatted(.cardinalDirection))
                            .foregroundStyle(.primary)
                        Text(verbatim: "\(swellDirection.formatted(.number.precision(.fractionLength(0))))°")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("locationForecast.text.swellDirection")
                    .accessibilityValue(Text(verbatim: "\(swellDirection.formatted(.number.precision(.fractionLength(0))))°"))
                }
                .font(.system(size: 22 * locationTitleScaleFactor))
                .foregroundStyle(.white)
                .shadow(radius: 8)
                .opacity(swellDescriptionOpacity)
            }
        }
        .bold()
        .offset(y: headerOffset)
    }
    
    private func loadingHeader(_ state: LocationForecastFeature.State) -> some View {
        VStack(alignment: .center, spacing: 32) {
            Text(state.location.title)
                .font(.system(size: 30 * locationTitleScaleFactor))
                .foregroundStyle(.white)
                .shadow(radius: 8)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: 8.0) {
                Text("locationForecast.text.loading")
                    .font(.system(size: 22 * locationTitleScaleFactor))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
                
                Text("locationForecast.text.lastUpdated \(state.location.dateUpdated.formatted(.relative(presentation: .named, unitsStyle: .spellOut)))")
                    .font(.system(size: 16 * locationTitleScaleFactor))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
            }
        }
        .bold()
    }
    
    private func errorHeader(_ state: LocationForecastFeature.State) -> some View {
        VStack(alignment: .center, spacing: 32) {
            Text(state.location.title)
                .font(.system(size: 30 * locationTitleScaleFactor))
                .foregroundStyle(.white)
                .shadow(radius: 8)
                .accessibilityAddTraits(.isHeader)
        }
        .bold()
    }
    
    // MARK: - Content
    
    private func content(_ state: LocationForecastFeature.State) -> some View {
        VStack {
            LocationForecastSectionView(titleView: { sectionHeader(title: "locationForecast.text.hourlyForecast", systemImageName: "clock")}, contentView: {
                HourlyForecastView(weatherData: state.location.weather)
                    .padding([.horizontal, .bottom])
            }, globalYStopperCoordinate: safeAreaInsets.top + distanceToStartCollapseSectionHeaders)
            if horizontalSizeClass == .compact && dynamicTypeSize > .xxLarge {
                LocationForecastSectionView(titleView: { sectionHeader(title: "locationForecast.text.tide", systemImageName: "water.waves")}, contentView: {
                    TideForecastView(weatherData: state.location.weather)
                        .padding([.horizontal, .bottom])
                }, globalYStopperCoordinate: safeAreaInsets.top + distanceToStartCollapseSectionHeaders)
                LocationForecastSectionView(titleView: { sectionHeader(title: "locationForecast.text.wind", systemImageName: "wind")}, contentView: {
                    WindForecastView(weatherData: state.location.weather, offshorePerpendicular: state.location.offshorePerpendicular)
                        .padding([.horizontal, .bottom])
                }, globalYStopperCoordinate: safeAreaInsets.top + distanceToStartCollapseSectionHeaders)
            } else {
                HStack {
                    LocationForecastSectionView(titleView: { sectionHeader(title: "locationForecast.text.tide", systemImageName: "water.waves")}, contentView: {
                        TideForecastView(weatherData: state.location.weather)
                            .padding(.bottom)
                    }, globalYStopperCoordinate: safeAreaInsets.top + distanceToStartCollapseSectionHeaders)
                    LocationForecastSectionView(titleView: { sectionHeader(title: "locationForecast.text.wind", systemImageName: "wind")}, contentView: {
                        WindForecastView(weatherData: state.location.weather, offshorePerpendicular: state.location.offshorePerpendicular)
                            .padding(.bottom)
                    }, globalYStopperCoordinate: safeAreaInsets.top + distanceToStartCollapseSectionHeaders)
                }
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
            .accessibilityAddTraits(.isHeader)
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
    private var locationTitleScaleFactor: CGFloat { locationTitleFontSize / 30 }
    private var distanceToStartCollapseSectionHeaders: CGFloat { 64.0 * locationTitleScaleFactor }
    private var maximumAllowedDragDistanceForLocationTitle: CGFloat { 16.0 * locationTitleScaleFactor }
    private var dragDistanceToCompletelyHideWaveHeight: CGFloat { 48.0 * locationTitleScaleFactor }
    private var dragDistanceToCompletelyHideSwellDescription: CGFloat { 128.0 * locationTitleScaleFactor }
    
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
