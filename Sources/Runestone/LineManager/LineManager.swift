//
//  LineManager.swift
//  
//
//  Created by Simon Støvring on 08/12/2020.
//

import Foundation
import CoreGraphics

protocol LineManagerDelegate: class {
    func lineManager(_ lineManager: LineManager, characterAtLocation location: Int) -> String
    func lineManager(_ lineManager: LineManager, didInsert line: DocumentLineNode)
    func lineManager(_ lineManager: LineManager, didRemove line: DocumentLineNode)
}

extension LineManagerDelegate {
    func lineManager(_ lineManager: LineManager, didInsert line: DocumentLineNode) {}
    func lineManager(_ lineManager: LineManager, didRemove line: DocumentLineNode) {}
}

//struct DocumentLineNodeID: RedBlackTreeNodeID, Hashable {
//    let id = UUID()
//}
//
//struct LineFrameNodeID: RedBlackTreeNodeID, Hashable {
//    let id = UUID()
//}

//typealias DocumentLineNode = RedBlackTreeNode
typealias DocumentLineNode = RedBlackTreeNode
typealias LineFrameNode = RedBlackTreeNode

struct VisibleLine {
    let documentLine: DocumentLineNode
    let lineFrame: LineFrameNode
}

final class LineManager {
    weak var delegate: LineManagerDelegate?
    var lineCount: Int {
        return documentLineTree.nodeTotalCount
    }
    var contentHeight: CGFloat {
        return 200
//        let rightMost = lineFrameTree.root.rightMost
//        return CGFloat(rightMost.location + rightMost.value)
    }
    var estimatedLineHeight: CGFloat = 12

    private let documentLineTree = RedBlackTree()
    private let lineFrameTree = RedBlackTree()
    private var documentLineNodeMap: [UUID: DocumentLineNode] = [:]
    private var lineFrameNodeMap: [UUID: LineFrameNode] = [:]
    private var documentLineToLineFrameMap: [UUID: UUID] = [:]
    private var lineFrameToDocumentLineMap: [UUID: UUID] = [:]
    private var documentLineNodeContextMap: [UUID: DocumentLineNodeContext] = [:]
    private var currentDelegate: LineManagerDelegate {
        if let delegate = delegate {
            return delegate
        } else {
            fatalError("Attempted to access delegate but it is not available.")
        }
    }

    init() {
        reset()
    }

    func reset() {
//        documentLineTree.reset(rootValue: 0)
        documentLineTree.reset()
//        lineFrameTree.reset(rootValue: 0)
        documentLineNodeMap.removeAll()
        lineFrameNodeMap.removeAll()
        documentLineToLineFrameMap.removeAll()
        lineFrameToDocumentLineMap.removeAll()
        documentLineNodeContextMap.removeAll()
        documentLineNodeMap[documentLineTree.root.id] = documentLineTree.root
        lineFrameNodeMap[lineFrameTree.root.id] = lineFrameTree.root
        documentLineToLineFrameMap[documentLineTree.root.id] = lineFrameTree.root.id
        lineFrameToDocumentLineMap[lineFrameTree.root.id] = documentLineTree.root.id
        let context = DocumentLineNodeContext()
        context.node = documentLineTree.root
        documentLineNodeContextMap[documentLineTree.root.id] = context
    }

    func removeCharacters(in range: NSRange) {
        guard range.length > 0 else {
            return
        }
        let startLine = documentLineTree.node(containgLocation: range.location)
//        let startLineContext = documentLineNodeContextMap[startLine.id]!
        if range.location > Int(startLine.location) + startLine.length {
            // Deleting starting in the middle of a delimiter.
            setLength(of: startLine, to: startLine.totalLength - 1)
            removeCharacters(in: NSRange(location: range.location, length: range.length - 1))
        } else if range.location + range.length < Int(startLine.location) + startLine.totalLength {
            // Removing a part of the start line.
            setLength(of: startLine, to: startLine.totalLength - range.length)
        } else {
            // Merge startLine with another line because the startLine's delimeter was deleted,
            // possibly removing lines in between if multiple delimeters were deleted.
            let charactersRemovedInStartLine = Int(startLine.location) + startLine.totalLength - range.location
            assert(charactersRemovedInStartLine > 0)
            let endLine = documentLineTree.node(containgLocation: range.location + range.length)
            if endLine === startLine {
                // Removing characters in the last line.
                setLength(of: startLine, to: startLine.totalLength - range.length)
            } else {
//                let endLineContext = documentLineNodeContextMap[endLine.id]!
                let charactersLeftInEndLine = Int(endLine.location) + endLine.totalLength - (range.location + range.length)
                // Remove all lines between startLine and endLine, excluding startLine but including endLine.
                var tmp = startLine.next
                var lineToRemove = tmp
                repeat {
                    lineToRemove = tmp
                    tmp = tmp.next
                    remove(lineToRemove)
                } while lineToRemove !== endLine
                let newLength = startLine.totalLength - charactersRemovedInStartLine + charactersLeftInEndLine
                setLength(of: startLine, to: newLength)
            }
        }
    }

    func insert(_ string: NSString, at location: Int) {
        var line = documentLineTree.node(containgLocation: location)
        var lineLocation = Int(line.location)
//        let lineContext = documentLineNodeContextMap[line.id]!
        assert(location <= lineLocation + line.totalLength)
        if location > lineLocation + line.length {
            // Inserting in the middle of a delimiter.
            setLength(of: line, to: line.totalLength - 1)
            // Add new line.
            line = insertLine(ofLength: 1, after: line)
            line = setLength(of: line, to: 1)
        }
        if let rangeOfFirstNewLine = NewLineFinder.rangeOfNextNewLine(in: string, startingAt: 0) {
            var lastDelimiterEnd = 0
            var rangeOfNewLine = rangeOfFirstNewLine
            var hasReachedEnd = false
            while !hasReachedEnd {
                let lineBreakLocation = location + rangeOfNewLine.location + rangeOfNewLine.length
                lineLocation = Int(line.location)
                let lengthAfterInsertionPos = lineLocation + line.totalLength - (location + lastDelimiterEnd)
                line = setLength(of: line, to: lineBreakLocation - lineLocation)
                var newLine = insertLine(ofLength: lengthAfterInsertionPos, after: line)
                newLine = setLength(of: newLine, to: lengthAfterInsertionPos)
                line = newLine
                lastDelimiterEnd = rangeOfNewLine.location + rangeOfNewLine.length
                if let rangeOfNextNewLine = NewLineFinder.rangeOfNextNewLine(in: string, startingAt: lastDelimiterEnd) {
                    rangeOfNewLine = rangeOfNextNewLine
                } else {
                    hasReachedEnd = true
                }
            }
            // Insert rest of last delimiter.
            if lastDelimiterEnd != string.length {
                setLength(of: line, to: line.totalLength + string.length - lastDelimiterEnd)
            }
        } else {
            // No newline is being inserted. All the text is in a single line.
            setLength(of: line, to: line.totalLength + string.length)
        }
    }

    func linePosition(at location: Int) -> LinePosition? {
        if let nodePosition = documentLineTree.nodePosition(at: location) {
            return nodePosition
//            let context = documentLineNodeContextMap[nodePosition.nodeId]!
//            return LinePosition(
//                lineStartLocation: Int(nodePosition.location),
//                lineNumber: nodePosition.index,
//                column: Int(nodePosition.valueOffset),
//                length: Int(nodePosition.value),
//                delimiterLength: context.delimiterLength)
        } else {
            return nil
        }
    }

    func line(containingCharacterAt location: Int) -> DocumentLineNode? {
        if location >= 0 && location <= Int(documentLineTree.nodeTotalLength) {
            return documentLineTree.node(containgLocation: location)
        } else {
            return nil
        }
    }

    func line(atIndex index: Int) -> DocumentLineNode {
        return documentLineTree.node(atIndex: index)
    }

//    @discardableResult
//    func setHeight(_ newHeight: CGFloat, of lineFrame: LineFrameNode) -> Bool {
//        if newHeight != CGFloat(lineFrame.value) {
//            lineFrame.value = newHeight
//            lineFrameTree.updateAfterChangingChildren(of: lineFrame)
//            return true
//        } else {
//            return false
//        }
//    }

//    func visibleLines(in rect: CGRect) -> [VisibleLine] {
//        let results = lineFrameTree.searchRange(Float(rect.minY) ... Float(rect.maxY))
//        return results.compactMap { result in
//            if let documentLineId = lineFrameToDocumentLineMap[result.node.id], let documentLine = documentLineNodeMap[documentLineId] {
//                return VisibleLine(documentLine: documentLine, lineFrame: result.node)
//            } else {
//                return nil
//            }
//        }
//    }
}

private extension LineManager {
    @discardableResult
    private func setLength(of line: DocumentLineNode, to newTotalLength: Int) -> DocumentLineNode {
//        let lineContext = documentLineNodeContextMap[line.id]!
        let delta = newTotalLength - line.totalLength
        if delta != 0 {
            line.totalLength = newTotalLength
            documentLineTree.updateAfterChangingChildren(of: line)
        }
        // Determine new delimiter length.
        if newTotalLength == 0 {
            line.delimiterLength = 0
        } else {
            let lastChar = getCharacter(at: Int(line.location) + newTotalLength - 1)
            if lastChar == Symbol.carriageReturn {
                line.delimiterLength = 1
            } else if lastChar == Symbol.lineFeed {
                if newTotalLength >= 2 && getCharacter(at: Int(line.location) + newTotalLength - 2) == Symbol.carriageReturn {
                    line.delimiterLength = 2
                } else if newTotalLength == 1 && line.location > 0 && getCharacter(at: Int(line.location) - 1) == Symbol.carriageReturn {
                    // We need to join this line with the previous line.
                    let previousLine = line.previous
                    let previousline = documentLineNodeContextMap[previousLine.id]!
                    remove(line)
                    return setLength(of: previousLine, to: previousline.totalLength + 1)
                } else {
                    line.delimiterLength = 1
                }
            } else {
                line.delimiterLength = 0
            }
        }
        return line
    }

    @discardableResult
    private func insertLine(ofLength length: Int, after otherLine: DocumentLineNode) -> DocumentLineNode {
        let insertedLine = documentLineTree.insertNode(ofLength: length, after: otherLine)
//        let insertedLineContext = DocumentLineNodeContext()
//        insertedLineContext.node = insertedLine
//        documentLineNodeContextMap[insertedLine.id] = insertedLineContext
//        documentLineNodeMap[insertedLine.id] = insertedLine
//        if let afterLineFrameNodeId = documentLineToLineFrameMap[otherLine.id], let afterLineFrameNode = lineFrameNodeMap[afterLineFrameNodeId] {
//            let insertedFrame = lineFrameTree.insertNode(withValue: estimatedLineHeight, after: afterLineFrameNode)
//            lineFrameNodeMap[insertedFrame.id] = insertedFrame
//            documentLineToLineFrameMap[insertedLine.id] = insertedFrame.id
//            lineFrameToDocumentLineMap[insertedFrame.id] = insertedLine.id
//        }
        delegate?.lineManager(self, didInsert: insertedLine)
        return insertedLine
    }

    private func remove(_ line: DocumentLineNode) {
        documentLineTree.remove(line)
        documentLineNodeMap.removeValue(forKey: line.id)
        if let lineFrameNodeId = documentLineToLineFrameMap[line.id] {
            lineFrameNodeMap.removeValue(forKey: lineFrameNodeId)
            lineFrameToDocumentLineMap.removeValue(forKey: lineFrameNodeId)
        }
        documentLineToLineFrameMap.removeValue(forKey: line.id)
        delegate?.lineManager(self, didRemove: line)
    }

    private func getCharacter(at location: Int) -> String {
        return currentDelegate.lineManager(self, characterAtLocation: location)
    }
}
