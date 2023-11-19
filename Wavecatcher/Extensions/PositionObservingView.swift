//
//  PositionObservingView.swift
//  Wavecatcher
//

import SwiftUI

struct PositionObservingView<Content: View>: View {
    var coordinateSpace: CoordinateSpace
    @Binding var position: CGPoint
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: PositionPreferenceKey.self,
                    value: geometry.frame(in: coordinateSpace).origin)
            })
            .onPreferenceChange(PositionPreferenceKey.self) { position in
                self.position = position
            }
    }
    
    private struct PositionPreferenceKey: PreferenceKey {
        static var defaultValue: CGPoint { .zero }
        static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
    }
}
