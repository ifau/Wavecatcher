//
//  AuroraBackgroundView.swift
//  Wavecatcher
//

import SwiftUI

struct AuroraBackgroundView: View {
    
    let variant: BackgroundVariant.AuroraVariant
    @State private var animate: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                variant.backgroundColor
                
                ZStack {
                    ForEach(Array(variant.motionColors.enumerated()), id: \.offset) { index, color in
                        
                        Circle()
                            .fill(color)
                            .frame(width: size(backgroundSize: geometry.size), height: size(backgroundSize: geometry.size))
                            .offset(offset(backgroundSize: geometry.size))
                            .rotationEffect(self.rotation(at: index))
                            .animation(Animation.linear(duration: animationDuration(at: index)).repeatForever(autoreverses: true), value: animate)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: self.aligment(at: index))
                            .opacity(0.8)
                    }
                }
                .blur(radius: 60)
                
                Color.black
                    .opacity(colorScheme == .dark ? 0.3 : 0.0)
            }
        }
        .onAppear { animate = true }
    }
    
    func size(backgroundSize: CGSize) -> CGFloat {
        guard backgroundSize.width > 0 else { return 0 }
        return max(backgroundSize.width, backgroundSize.height) / CGFloat.random(in: 0.9 ..< 1.4)
    }
    
    func offset(backgroundSize: CGSize) -> CGSize {
        guard backgroundSize.width > 0 else { return .zero }
        let bound = 150.0//min(backgroundSize.width, backgroundSize.height) / 4.0
        let value = CGFloat.random(in: -bound ..< bound)
        return CGSize(width: value, height: value)
    }
    
    func aligment(at index: Int) -> Alignment {
        switch index {
        case 0: return .topLeading
        case 1: return .topTrailing
        case 2: return .bottomLeading
        case 3: return .bottomTrailing
        default: return .center
        }
    }
    
    func rotation(at index: Int) -> Angle {
        return .degrees(Double(index * 40))
    }
    
    func animationDuration(at index: Int) -> TimeInterval {
        return 10.0 + (Double(index) * 5.0)
    }
}

//#Preview {
//    AuroraBackgroundView(variant: .variant1)
//}
