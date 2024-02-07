//
//  DirectionIndicatorView.swift
//  Wavecatcher
//

import SwiftUI

struct DirectionIndicatorView: View {
    
    let degrees: Double
    
    var body: some View {
        Image(systemName: "location.north.fill")
            .rotationEffect(.degrees(degrees + 180.0))
            .accessibilityHidden(true)
    }
}

#Preview {
    DirectionIndicatorView(degrees: 90)
}
