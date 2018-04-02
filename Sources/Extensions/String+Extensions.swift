//
//  String+Extensions.swift
//  GitDiffSwiftPackageDescription
//
//  Created by Steven Deutsch on 4/2/18.
//

import Foundation

extension String {

    internal func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

}
