//
//  LocationForecastSectionView.swift
//  Wavecatcher
//

import SwiftUI

struct LocationForecastSectionView<Title: View, Content: View>: View {
    
    var titleView: Title
    var contentView: Content
    
    private var globalYStopperCoordinate: CGFloat { safeAreaInsets.top + LocationForecastView.distanceToStartCollapseSectionHeaders }
    private var topOffset: CGFloat { globalFrame.minY }
    private var bottomOffset: CGFloat { globalFrame.maxY - globalYStopperCoordinate }
    @State private var globalFrame: CGRect = .zero
    @Environment(\.safeAreaInsets) var safeAreaInsets
    
    init(@ViewBuilder titleView: @escaping () -> Title,
         @ViewBuilder contentView: @escaping () -> Content) {
        self.titleView = titleView()
        self.contentView = contentView()
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            titleView
                .frame(height: titleViewHeight)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .background(.ultraThinMaterial, in: RoundedCorner(corners: bottomOffset < titleViewHeight ? [.allCorners] : [.topLeft, .topRight], radius: cornerRadius))
                .zIndex(1)
            
            VStack {
                Divider()
                contentView
            }
            .offset(y: topOffset > globalYStopperCoordinate ? 0 : -(-topOffset + globalYStopperCoordinate))
            .background(.ultraThinMaterial)
            .zIndex(0)
            .clipped()
        }
        .offset(y: topOffset > globalYStopperCoordinate ? 0 : -topOffset + globalYStopperCoordinate)
        .readGlobalFrame { globalFrame = $0 }
        .opacity(opacity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    private var titleViewHeight: CGFloat {
        return 38.0
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
