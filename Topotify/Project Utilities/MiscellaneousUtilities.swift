import Foundation
import SwiftUI
import SpotifyWebAPI

extension View {
    
    /// Type erases self to `AnyView`. Equivalent to `AnyView(self)`.
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }

}

extension ProcessInfo {
    
    /// Whether or not this process is running within the context of a SwiftUI
    /// preview.
    var isPreviewing: Bool {
        return self.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    static let MinCount = 3
    static let MaxCount = 50

}
