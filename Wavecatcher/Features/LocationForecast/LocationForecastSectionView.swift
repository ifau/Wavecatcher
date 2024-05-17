//
//  LocationForecastSectionView.swift
//  Wavecatcher
//

import SwiftUI

struct LocationForecastSectionView<Title: View, Content: View>: View {
    
    var titleView: Title
    var contentView: Content
    var globalYStopperCoordinate: CGFloat
    
    private var topOffset: CGFloat { globalFrame.minY }
    private var bottomOffset: CGFloat { globalFrame.maxY - globalYStopperCoordinate }
    @State private var globalFrame: CGRect = .zero
    @Environment(\.safeAreaInsets) var safeAreaInsets
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @ScaledMetric(relativeTo: .title) var titleViewHeight = 38.0
    
    init(@ViewBuilder titleView: @escaping () -> Title,
         @ViewBuilder contentView: @escaping () -> Content,
         globalYStopperCoordinate: CGFloat = 0.0) {
        self.titleView = titleView()
        self.contentView = contentView()
        self.globalYStopperCoordinate = globalYStopperCoordinate
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            titleView
                .frame(height: titleViewHeight)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .background(reduceTransparency ? .thinMaterial : .ultraThinMaterial, in: RoundedCorner(corners: bottomOffset < titleViewHeight ? [.allCorners] : [.topLeft, .topRight], radius: cornerRadius))
                .zIndex(1)
            
            VStack {
                Divider()
                contentView
            }
            .offset(y: topOffset > globalYStopperCoordinate ? 0 : -(-topOffset + globalYStopperCoordinate))
            .background(reduceTransparency ? .thinMaterial : .ultraThinMaterial)
            .zIndex(0)
            .clipped()
        }
        .offset(y: topOffset > globalYStopperCoordinate ? 0 : -topOffset + globalYStopperCoordinate)
        .readGlobalFrame { globalFrame = $0 }
        .opacity(opacity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    private var opacity: CGFloat {
        guard bottomOffset < titleViewHeight else { return 1.0 }
        return bottomOffset / titleViewHeight
    }
    
    private var cornerRadius: CGFloat {
        return 12.0
    }
}

#Preview {
    LocationForecastSectionView(titleView: { Text("Title") }, contentView: { Text("Content") } )
}
