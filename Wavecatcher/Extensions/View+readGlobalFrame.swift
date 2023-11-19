//
//  View+readGlobalFrame.swift
//  Wavecatcher
//

import SwiftUI

extension View {
    func readGlobalFrame(onChange: @escaping (CGRect) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear.preference(key: GlobalFramePreferenceKey.self, value: geometry.frame(in: .global))
            }
        )
        .onPreferenceChange(GlobalFramePreferenceKey.self, perform: onChange)
    }
}

struct GlobalFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {}
}
