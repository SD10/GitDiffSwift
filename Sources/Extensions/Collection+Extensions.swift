//
//  Collection+Extensions.swift
//  GitDiffSwiftPackageDescription
//
//  Created by Steven Deutsch on 4/2/18.
//

import Foundation

extension Collection {

    internal func indices(where condition: (Element) throws -> Bool) rethrows -> [Int] {
        var indices: [Int] = []
        for (index, value) in enumerated() {
            if try condition(value) { indices.append(index) }
        }
        return indices
    }

}
