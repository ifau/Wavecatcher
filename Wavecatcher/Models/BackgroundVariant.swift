//
//  BackgroundVariant.swift
//  Wavecatcher
//

import Foundation
import SwiftUI

enum BackgroundVariant: Equatable, Codable {
    
    case aurora(AuroraVariant)
    case video(VideoVariant)
    
    enum AuroraVariant: Equatable, Codable { case variant1, variant2, variant3, variant4 }
    struct VideoVariant: Equatable, Codable { let fileName: String }
}

extension BackgroundVariant.AuroraVariant {
    
    var backgroundColor: Color {
        switch self {
        case .variant1:
            return Color(hex: 0x0487D9)
        case .variant2:
            return Color(hex: 0x76789F)
        case .variant3:
            return Color(hex: 0xF2ACAC)
        case .variant4:
            return Color(hex: 0x1F7334)
        }
    }
    
    var motionColors: [Color] {
        switch self {
        case .variant1:
            return [Color(hex: 0x0367A6), Color(hex: 0x0378A6), Color(hex: 0x049DBF), Color(hex: 0x80DDF2)]
        case .variant2:
            return [Color(hex: 0xF39EB5), Color(hex: 0x7B6CAD), Color(hex: 0x413877), Color(hex: 0x50BCAF)]
        case .variant3:
            return [Color(hex: 0xF26D6D), Color(hex: 0xF2CA99), Color(hex: 0xF2DC6B), Color(hex: 0xF2CECE)]
        case .variant4:
            return [Color(hex: 0x115923), Color(hex: 0x2B8C44), Color(hex: 0x658C6F), Color(hex: 0xA8BFAA)]
        }
    }
}

extension BackgroundVariant.VideoVariant {
    var fileURL: URL { URL.documentsDirectory.appendingPathComponent(fileName) }
}
