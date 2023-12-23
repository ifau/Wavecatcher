//
//  AppView.swift
//  Wavecatcher
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    
    let store: StoreOf<AppFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            GeometryReader { geometry in
                IfLetStore(self.store.scope(state: \.$destination, action: { .destination($0) }), then: { destination in
                    SwitchStore(destination) { state in
                        switch state {
                        case .onboarding: CaseLet(/AppFeature.Destination.State.onboarding, action: AppFeature.Destination.Action.onboarding, then: OnboardingView.init(store:))
                        case .locationsList: CaseLet(/AppFeature.Destination.State.locationsList, action: AppFeature.Destination.Action.locationsList, then: LocationsListView.init(store:))
                        }
                    }
                }, else: { Color("LaunchScreenColor", bundle: nil).ignoresSafeArea() })
                .environment(\.safeAreaInsets, geometry.safeAreaInsets)
            }
            .task { await viewStore.send(.task).finish() }
            .onAppear { viewStore.send(.rootViewAppear, animation: .smooth) }
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
