//
//  DiffParser.swift
//  GitDiffSwift
//
//  Created by Steven Deutsch on 2/7/18.
//  Copyright © 2018 GitDiffSwift. All rights reserved.
//

// TODO:
// - Fix double new lines
// - Add remaining text to hunk line
// - Fix line types
// - Fix line numbers
// - Parse index
// - Handle no new line

import Foundation

final class DiffParser {

    private enum GitPrefix {
        internal static let diffHeader = "diff --git"
        internal static let deletedFile = "+++ /dev/null"
        internal static let addedFile = "--- /dev/null"
        internal static let previousFile = "--- a/"
        internal static let updatedFile = "+++ b/"
        internal static let hunk = "@@"
    }

    let input: String
    let state: State

    var currentDiff: GitDiff?
    var currentHunk: GitHunk?

    init(input: String) {
        self.input = input
        self.state = State()
    }

    func diffType(for line: String) -> LineType {
        switch true {
        case line.hasPrefix("+"):
            return .addition
        case line.hasPrefix("-"):
            return .deletion
        case line.hasPrefix(""):
            return .unchanged
        default:
            fatalError("Unexpected prefix for line type: \(line)")
        }
    }

    func parseHunkHeader(_ input: String) -> [String: Int] {
        let trimmed = String(String(input.dropLast(3)).dropFirst(3))
        let hunkText = trimmed.split(separator: " ")

        let oldHunkInfo = hunkText[0].dropFirst(1).split(separator: ",")
        let newHunkInfo = hunkText[1].dropFirst(1).split(separator: ",")

        var hunkInfo: [String: Int] = [:]
        hunkInfo["oldLineStart"] = Int(oldHunkInfo[0])!
        hunkInfo["oldLineSpan"] = Int(oldHunkInfo[1])!
        hunkInfo["newLineStart"] = Int(newHunkInfo[0])!
        hunkInfo["newLineSpan"] = Int(newHunkInfo[1])!

        return hunkInfo
    }

    func parseDiffLine(_ line: String) -> [String: Any?] {
        let type = diffType(for: line)
        let text = line

        state.updateLineNumber(diffType: type)

        let oldLine = state.currentOldLine
        let newLine = state.currentOldLine

        var lineInfo: [String: Any?] = [:]
        lineInfo["type"] = type.rawValue
        lineInfo["text"] = text
        lineInfo["newLine"] = newLine
        lineInfo["oldLine"] = oldLine

        switch type {
        case .addition: lineInfo["oldLine"] = nil
        case .deletion: lineInfo["newLine"] = nil
        default: break
        }

        return lineInfo
    }

    func extractDiffs() -> [GitDiff] {

        let inputLines = input.split(separator: "\n", maxSplits: .max, omittingEmptySubsequences: false)

        var diffs: [GitDiff] = []

        var diffInfo: [String: Any?] = [:]
        var hunks: [[String: Any?]] = []
        var changes: [[String: Any?]] = []

        let createDiff = {
            diffInfo["hunks"] = hunks

            let data = try! JSONSerialization.data(withJSONObject: diffInfo, options: [])
            let decoder = JSONDecoder()

            do {
                let diff = try decoder.decode(GitDiff.self, from: data)
                diffs.append(diff)
                hunks.removeAll()
                changes.removeAll()
                diffInfo.removeAll()
            } catch {
                print(error.localizedDescription)
            }
        }

        let createHunk = {
            var lastHunk = hunks.removeLast()
            lastHunk["changes"] = changes
            hunks.append(lastHunk)
            changes.removeAll()
        }

        for line in inputLines {
            let line = String(line)
            switch true {
            case line.hasPrefix(GitPrefix.diffHeader):
                if !diffInfo.isEmpty {
                    createDiff()
                }
            case line.hasPrefix(GitPrefix.previousFile):
                let previousFilePath = line.removingPrefix(GitPrefix.previousFile)
                diffInfo["previousFilePath"] = previousFilePath
            case line.hasPrefix(GitPrefix.updatedFile):
                let updatedFilePath = line.removingPrefix(GitPrefix.updatedFile)
                diffInfo["updatedFilePath"] = updatedFilePath
            case line.hasPrefix(GitPrefix.hunk):
                if !hunks.isEmpty {
                    createHunk()
                }
                let hunkHeader = parseHunkHeader(line)
                hunks.append(hunkHeader)
            case line.hasPrefix("index"):
                continue
            default:
                let diffLine = parseDiffLine(line)
                changes.append(diffLine)
            }
        }

        createHunk()

        createDiff()

        return diffs
    }
}

internal struct LineState {
    var currentOldLine: Int?
    var currentNewLine: Int?

    func update(for line: LineType) {
        
    }
}

internal class State {
    var isInDiffHeader = false
    var isInHunk = false
    var isHunkFirstLine = false
    var currentOldLine = 0
    var currentNewLine = 0

    func newDiff() {
        isInDiffHeader = true
        isHunkFirstLine = false
        isInHunk = false
        currentOldLine = 0
        currentNewLine = 0
    }

    func newHunk(_ hunk: GitHunk) {
        isInDiffHeader = false
        isInHunk = true
        isHunkFirstLine = true
        currentOldLine = hunk.oldLineStart
        currentNewLine = hunk.newLineStart
    }

    func updateLineNumber(diffType: LineType) {
        guard !isHunkFirstLine else {
            isHunkFirstLine = false
            return
        }
        switch diffType {
        case .unchanged:
            currentOldLine += 1
            currentNewLine += 1
        case .addition:
            currentNewLine += 1
        case .deletion:
            currentOldLine += 1
        }
    }
}

extension String {

    func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

}
