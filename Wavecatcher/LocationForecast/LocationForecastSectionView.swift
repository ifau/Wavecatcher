//
//  LocationForecastSectionView.swift
//  Wavecatcher
//

import SwiftUI

struct LocationForecastSectionView<Title: View, Content: View>: View {
    
    var titleView: Title
    var contentView: Content
    
    init(@ViewBuilder titleView: @escaping () -> Title,
         @ViewBuilder contentView: @escaping () -> Content) {
        self.titleView = titleView()
        self.contentView = contentView()
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            titleView
            Divider()
            contentView
        }
        .background(.ultraThinMaterial)
    }
}

#Preview {
    LocationForecastSectionView(titleView: { Text("Title") }, contentView: { Text("Content") } )
}
