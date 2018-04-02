//
//  LineState.swift
//  GitDiffSwift
//
//  Created by Steven Deutsch on 4/2/18.
//

import Foundation

internal struct LineState {
    internal var isFirstLine = true
    internal var currentOldLine = 0
    internal var currentNewLine = 0

    internal mutating func updateForLine(type: LineType) {
        guard !isFirstLine else {
            isFirstLine = false
            return
        }
        switch type {
        case .unchanged:
            currentOldLine += 1
            currentNewLine += 1
        case .addition:
            currentNewLine += 1
        case .deletion:
            currentOldLine += 1
        }
    }

    internal mutating func reset(newLineStart: Int, oldLineStart: Int) {
        self.isFirstLine = true
        self.currentNewLine = newLineStart
        self.currentOldLine = oldLineStart
    }
}
