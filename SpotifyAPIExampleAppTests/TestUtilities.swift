import Foundation
import XCTest

extension XCUIElement {
    
    /// [Source](https://developer.apple.com/forums/thread/24131).
    func forceTap() {
        if self.isHittable {
            self.tap()
        }
        else {
            self.coordinateTap()
        }
    }
    
    func coordinateTap() {
        let coordinate = self.coordinate(
            withNormalizedOffset: CGVector(dx: 0, dy: 0)
        )
        coordinate.tap()
    }
    
    /// [Source](https://stackoverflow.com/questions/34062872/how-to-hide-keyboard-in-swift-app-during-ui-testing/56601853).
    func dismissKeyboard() {
        self.toolbars.buttons["Done"].tap()
    }
    
    /// Waits until this element is hittable.
    func waitUntilHittable(timeout: TimeInterval) -> Bool {
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        while !self.isHittable {
            if Date() >= timeoutDate {
                print(
                    "waiting for '\(self.label)' to become hittable timed out " +
                    "after \(timeout) seconds"
                )
                return false
            }
            let remainingTime = (timeoutDate - Date().timeIntervalSince1970)
                    .timeIntervalSince1970
            print("\(remainingTime)s waiting for \(self.label) to become hittable")
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        }
        return true
    }
    
    /// Waits for an element to not exist. Useful when this element is blocking
    /// another element that needs to be interacted with.
    func waitUntilDisappears(timeout: TimeInterval) {
        let doesNotExistPredicate = NSPredicate(format: "exists == FALSE")
        
        let doesNotExistExpectation = XCTNSPredicateExpectation(
            predicate: doesNotExistPredicate,
            object: self
        )

        let waiter = XCTWaiter()
        waiter.wait(for: [doesNotExistExpectation], timeout: timeout)

    }
    
}
