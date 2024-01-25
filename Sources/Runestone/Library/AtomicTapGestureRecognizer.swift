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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        range = nil
        
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: view)
        initialTouchLocation = location
        
        // Fail gesture if not touching a valid token
        guard let view = view as? TextView,
              let textPosition = view.closestPosition(to: location),
              // TODO: this needs to be better
              let range = view.tokenizer.rangeEnclosingPosition(textPosition, with: .word, inDirection: .layout(.right)),
              !range.isEmpty else {
            state = .failed
            return
        }
        
        self.range = range
        state = .recognized
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
