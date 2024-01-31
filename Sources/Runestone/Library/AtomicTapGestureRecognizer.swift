import UIKit

class AtomicTapGesture: UITapGestureRecognizer {
    private var movementThreshold: CGFloat = 10
    private var initialTouchLocation: CGPoint?
    
    var range: UITextRange?
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }
    
    private func getCharacterPairRange(for character: String, from position: Int, in view: TextView) -> NSRange? {
        for characterPair in view.characterPairs {
            if character == characterPair.leading {
                if let trailingPosition = view.text.findNextOccurrence(of: Character(characterPair.trailing), after: position),
                trailingPosition > position {
                    return NSRange(location: position + 1, length: max(trailingPosition - position - 1, 0))
                }
            }
            
            if character == characterPair.trailing {
                if let leadingPosition = view.text.findPreviousOccurrence(of: Character(characterPair.leading), before: position),
                position > leadingPosition {
                    return NSRange(location: leadingPosition + 1, length: max(position - leadingPosition - 1, 0))
                }
            }
        }
        
        return nil
    }
    
    private func getTokenRange(at position: UITextPosition, in view: TextView) -> UITextRange? {
        if let wordRange = view.tokenizer.rangeEnclosingPosition(position, with: .word, inDirection: .layout(.right)),
           !wordRange.isEmpty {
            let start = view.offset(from: view.beginningOfDocument, to: wordRange.start)
            let end = view.offset(from: view.beginningOfDocument, to: wordRange.end)
            print("word range", wordRange, view.text(in: NSRange(location: start, length: end - start)))
//            return nil
            return wordRange
        }
        
        let startPosition = view.offset(from: view.beginningOfDocument, to: position)
        
        let beforeCursorRange = NSRange(location: startPosition - 1, length: 1)
        if let beforeCursorCharacter = view.text(in: beforeCursorRange),
           !beforeCursorCharacter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("before cursor", beforeCursorCharacter)
            
            if let characterPairRange = getCharacterPairRange(for: beforeCursorCharacter, from: beforeCursorRange.location, in: view),
               let range = view.textRange(from: characterPairRange) {
                return range
            }
            
            if let range = view.textRange(from: beforeCursorRange) {
                return range
            }
            
            print("no ret")
            
            // first check for char pair
            // if char pair, return interior range
            // else return the 1 character since it's not empty
        }
        
        let afterCursorRange = NSRange(location: startPosition, length: 1)
        if let afterCursorCharacter = view.text(in: afterCursorRange),
           !afterCursorCharacter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("after cursor", afterCursorCharacter)
            
            if let characterPairRange = getCharacterPairRange(for: afterCursorCharacter, from: afterCursorRange.location, in: view),
               let range = view.textRange(from: characterPairRange) {
                return range
            }
            
            if let range = view.textRange(from: afterCursorRange) {
                return range
            }
        }
        
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        range = nil
        
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: view)
        initialTouchLocation = location
        
        // Fail gesture if not touching a valid token
        guard let view = view as? TextView,
              let textPosition = view.closestPosition(to: location),
              let range = getTokenRange(at: textPosition, in: view)
        else {
            state = .failed
            return
        }
        
        // Ensure range rect is touchable size
        var rangeRect = view.firstRect(for: range)
        let oldSize = rangeRect.size
        rangeRect.size.width = max(rangeRect.width, 20) + 40
        rangeRect.size.height = max(rangeRect.height, view.estimatedLineHeight) + 30
        rangeRect.origin.x -= (rangeRect.width - oldSize.width) / 2
        rangeRect.origin.y -= (rangeRect.height - oldSize.height) / 2

        // Ensures the touch was actually over the word
        guard rangeRect.contains(location) else {
            state = .failed
            return
        }
        
        self.range = range
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        if let touch = touches.first, let initialLocation = initialTouchLocation {
            let currentLocation = touch.location(in: view)
            let movement = distanceBetweenPoints(currentLocation, initialLocation)
            
            // Fail gesture if touch moves past threshold
            if movement > movementThreshold {
                state = .failed
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        
        initialTouchLocation = nil
    }
    
    private func distanceBetweenPoints(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        return hypot(a.x - b.x, a.y - b.y)
    }
}

extension String {
    func findNextOccurrence(of character: Character, after position: Int) -> Int? {
        guard position < count else {
            return nil // Position is out of bounds
        }
        
        let startSearchIndex = index(startIndex, offsetBy: position)
        let searchRange = startSearchIndex..<endIndex
        
        if let nextPosition = self[searchRange].firstIndex(of: character) {
            return distance(from: startIndex, to: nextPosition)
        } else {
            return nil // Character not found
        }
    }
    
    func findPreviousOccurrence(of character: Character, before position: Int) -> Int? {
        guard position >= 0, position <= count else {
            return nil // Position is out of bounds
        }
        
        let searchEndIndex = index(startIndex, offsetBy: position)
        let searchRange = startIndex..<searchEndIndex
        
        if let previousPosition = self[searchRange].lastIndex(of: character) {
            return distance(from: startIndex, to: previousPosition)
        } else {
            return nil // Character not found
        }
    }
}
