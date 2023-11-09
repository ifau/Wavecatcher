//
//  View+roundedCorners.swift
//  Wavecatcher
//

import SwiftUI

extension View {
    func roundedCorners(_ corners: UIRectCorner, radius: CGFloat) -> some View {
        clipShape(RoundedCorner(corners: corners, radius: radius))
    }
}

struct RoundedCorner: Shape {
    var corners: UIRectCorner = .allCorners
    var radius: CGFloat = .infinity
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
