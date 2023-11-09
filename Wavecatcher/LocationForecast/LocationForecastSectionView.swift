//
//  LocationForecastSectionView.swift
//  Wavecatcher
//

import SwiftUI

struct LocationForecastSectionView<Title: View, Content: View>: View {
    
    var titleView: Title
    var contentView: Content
    
    var globalYStopperCoordinate: CGFloat = 120.0
    @State private var topOffset: CGFloat = 0.0
    @State private var bottomOffset: CGFloat = 0.0
    
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
        .overlay {
            GeometryReader { proxy -> Color in
                let minY = proxy.frame(in: .global).minY
                let maxY = proxy.frame(in: .global).maxY
                DispatchQueue.main.async {
                    self.topOffset = minY
                    self.bottomOffset = maxY - globalYStopperCoordinate
                }
                return Color.clear
            }
        }
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
