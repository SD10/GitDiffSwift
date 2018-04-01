//
//  GitDiffLine.swift
//  GitDiffSwift
//
//  Created by Steven Deutsch on 4/1/18.
//  Copyright © 2018 GitDiffSwift. All rights reserved.
//

import Foundation

public enum LineType: String, Codable {
    case unchanged
    case addition
    case deletion
}

public struct GitDiffLine: Codable {

    public var type: String

    public var text: String

    public var oldLine: Int?

    public var newLine: Int?

    internal var description: String {
        return text
    }

}
