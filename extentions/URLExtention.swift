//
//  URLExtention.swift
//  imgn
//
//  Created by Joe Buckshin on 1/19/19.
//  Copyright © 2019 Joseph Buckshin. All rights reserved.
//

import UIKit

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    var subDirectories: [URL] {
        guard isDirectory else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter{ $0.isDirectory }) ?? []
    }
}
