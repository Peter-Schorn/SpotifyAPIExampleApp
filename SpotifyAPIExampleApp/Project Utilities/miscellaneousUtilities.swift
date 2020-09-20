import Foundation
import SwiftUI

enum KeychainKeys {
    
    static let authorizationManager = "authorizationManager"

}

extension Sequence {
    
    /// Creates an array of tuples in which the first item
    /// is the index of the element and the second is the element.
    func enumeratedArray() -> [(index: Int, element: Element)] {
        
        return self.enumerated().map { item in
            (index: item.0, element: item.1)
        }
        
    }
    
}

extension View {
    
    /// Type erases self to `AnyView`.
    /// Equivalent to `AnyView(self)`.
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }

}

