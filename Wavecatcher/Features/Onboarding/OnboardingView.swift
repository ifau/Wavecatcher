//
//  OnboardingView.swift
//  Wavecatcher
//

import SwiftUI
import ComposableArchitecture

struct OnboardingView: View {
    
    @State var store: StoreOf<OnboardingFeature>
    
    init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }
    
    init(state: OnboardingFeature.State) {
        self.store = Store(initialState: state, reducer: { OnboardingFeature() })
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                TabView(selection: viewStore.binding(get: \.selectedPage, send: OnboardingFeature.Action.selectPage).animation(.smooth)) {
                    ForEach(Array(viewStore.state.visiblePages.enumerated()), id:\.offset) { _, page in
                        onboardingPageView(for: page)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .overlay {
                    VStack {
                        Spacer()
                        Button(action: { viewStore.send(.addLocation) }, label: {
                            Text("onboarding.button.addLocation")
                                .font(.headline)
                                .bold()
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        })
                        .disabled(!viewStore.addLocationsButtonVisible)
                        .opacity(viewStore.addLocationsButtonVisible ? 1 : 0)
                        .padding()
                        
                        Spacer()
                            .frame(height: 36)
                    }
                }
            }
            .background {
                AuroraBackgroundView(variant: .variant1).ignoresSafeArea()
            }
            .fullScreenCover(store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                   state: /OnboardingFeature.Destination.State.addLocation,
                   action: OnboardingFeature.Destination.Action.addLocation) { addLocationStore in
                AddLocationView(store: addLocationStore)
            }
        }
    }
    
    @ViewBuilder
    private func onboardingPageView(for page: OnboardingFeature.State.OnboardingPage) -> some View {
        switch page {
        case .welcome: welcomePage.tag(OnboardingFeature.State.OnboardingPage.welcome)
        case .getStarted: getStartedPage.tag(OnboardingFeature.State.OnboardingPage.getStarted)
        }
    }
    
    private var welcomePage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("onboarding.text.discoverTheBestConditionsWith \(Text("appName"))")
                .font(.largeTitle)
                .bold()
                .blendMode(.overlay)
            
            Text("onboarding.text.getRealTimeForecastForSwellWindTide")
                .font(.headline)
                .bold()
                .blendMode(.overlay)
        }
        .padding()
    }
    
    private var getStartedPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("onboarding.text.getStartedBySelectingSurfingSpots")
                .font(.largeTitle)
                .bold()
                .blendMode(.overlay)
            
            Text("onboarding.text.toGetStartedYouHaveToAddAtLeastOneLocation")
                .font(.headline)
                .bold()
                .blendMode(.overlay)
        }
        .padding()
    }
}

#Preview {
    OnboardingView(state: .firstLaunchState)
}
