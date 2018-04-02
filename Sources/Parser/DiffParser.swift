//
//  DiffParser.swift
//  GitDiffSwift
//
//  Created by Steven Deutsch on 2/7/18.
//  Copyright © 2018 GitDiffSwift. All rights reserved.
//

import Foundation

final class DiffParser {

    internal enum GitPrefix {
        internal static let diffHeader = "diff --git"
        internal static let deletedFile = "+++ /dev/null"
        internal static let addedFile = "--- /dev/null"
        internal static let previousFile = "--- a/"
        internal static let updatedFile = "+++ b/"
        internal static let hunk = "@@"
        internal static let newLine = "\\ No newline at end of file"
    }

    internal let input: String
    internal var state: LineState

    public init(input: String) {
        self.input = input
        self.state = LineState()
    }

    public func parseDiffedFiles() -> [GitDiff] {

        let inputLines = input.split(separator: "\n", maxSplits: .max, omittingEmptySubsequences: false)

        var diffs: [GitDiff] = []

        var diffInfo: [String: Any?] = [:]
        var hunks: [[String: Any?]] = []
        var changes: [[String: Any]] = []

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
                    if !hunks.isEmpty {
                        createHunk()
                    }
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
                let indexInfo = parseIndexInfo(line)
                diffInfo["index"] = indexInfo
            case line.hasPrefix(GitPrefix.newLine):
                if !changes.isEmpty {
                    var lastChange = changes.removeLast()
                    lastChange["noNewLine"] = true
                    changes.append(lastChange)
                }
            default:
                let diffLine = parseDiffLine(line)
                changes.append(diffLine)
            }
        }

        createHunk()

        createDiff()

        return diffs
    }

    // MARK: - Helpers

    internal func diffType(for line: String) -> LineType {
        switch true {
        case line.hasPrefix("+"):
            return .addition
        case line.hasPrefix("-"):
            return .deletion
        default:
            return .unchanged
        }
    }

    internal func parseIndexInfo(_ input: String) -> [String: String] {
        let trimmed = input.removingPrefix("index ")
        let components = trimmed.components(separatedBy: " ")
        let id = components.last!
        let commits = components.first!.components(separatedBy: "..")
        var indexInfo: [String: String] = [:]
        indexInfo["id"] = id
        indexInfo["commitHead"] = commits[0]
        indexInfo["commitTail"] = commits[1]
        return indexInfo
    }

    internal func parseHunkHeader(_ input: String) -> [String: Any] {

        let indices = input.indices(where: { $0 == "@" })
        let hunkEndIndex = input.index(input.startIndex, offsetBy: indices[3] + 1)
        let hunkData = input[input.startIndex...hunkEndIndex]
        let remainingText = String(input[hunkEndIndex..<input.endIndex])

        let trimmed = String(String(hunkData.dropFirst(3).dropLast(3)))
        let hunkText = trimmed.split(separator: " ")

        let oldHunkInfo = hunkText[0].dropFirst(1).split(separator: ",")
        let newHunkInfo = hunkText[1].dropFirst(1).split(separator: ",")

        var hunkInfo: [String: Any] = [:]
        hunkInfo["oldLineStart"] = Int(oldHunkInfo[0])!
        hunkInfo["oldLineSpan"] = Int(oldHunkInfo[1])!
        hunkInfo["newLineStart"] = Int(newHunkInfo[0])!
        hunkInfo["newLineSpan"] = Int(newHunkInfo[1])!
        hunkInfo["text"] = remainingText

        return hunkInfo
    }

    internal func parseDiffLine(_ line: String) -> [String: Any] {
        let type = diffType(for: line)

        state.updateForLine(type: type)

        let oldLine = state.currentOldLine
        let newLine = state.currentNewLine

        var lineInfo: [String: Any] = [:]
        lineInfo["type"] = type.rawValue
        lineInfo["text"] = line
        lineInfo["newLine"] = newLine
        lineInfo["oldLine"] = oldLine

        return lineInfo
    }

}
