//
//  GitIndex.swift
//  GitDiffSwift
//
//  Created by Steven Deutsch on 4/1/18.
//  Copyright © 2018 GitDiffSwift. All rights reserved.
//

import Foundation

public struct GitIndex: Codable {

    public let id: String

    public let commitHead: String

    public let commitTail: String

    internal var description: String {
        return "index " + commitHead + ".." + commitTail + " " + id
    }

}
