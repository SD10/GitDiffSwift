//
//  GitHunk.swift
//  GitDiffSwift
//
//  Created by Steven Deutsch on 4/1/18.
//  Copyright © 2018 GitDiffSwift. All rights reserved.
//

import Foundation

public struct GitHunk: Codable {

    public var oldLineStart = 0

    public var oldLineSpan = 0

    public var newLineStart = 0

    public var newLineSpan = 0
    
    public var changes: [GitDiffLine]? = []

    internal var description: String {
        let header = "@@ -\(oldLineStart),\(oldLineSpan) +\(newLineStart),\(newLineSpan) @@\n\n"
        return changes?.reduce(into: header) {
            $0 += ($1.description + "\n")
        } ?? ""
    }
}
