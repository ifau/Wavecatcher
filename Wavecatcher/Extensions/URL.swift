//
//  URL.swift
//  Wavecatcher
//

import Foundation

extension URL {
    static let sharedContainerDirectoryURL = {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.ifau.test.data") else { fatalError() }
        return url
    }()
}
