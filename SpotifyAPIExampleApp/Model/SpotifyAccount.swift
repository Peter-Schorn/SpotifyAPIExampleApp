import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent
import Foundation

/// Contains a `SpotifyUser` and an authorization manager, which are
/// stored together in the keychain.
struct SpotifyAccount: Hashable {
    
    init(
        user: SpotifyUser,
        authorizationManager: AuthorizationCodeFlowManager
    ) {
        self.user = user
        self._authorizationManager = authorizationManager.makeCopy()
    }
    
    private var _authorizationManager: AuthorizationCodeFlowManager

    var user: SpotifyUser

    var authorizationManager: AuthorizationCodeFlowManager {
        mutating get {
            if !isKnownUniquelyReferenced(&self._authorizationManager) {
//                print("\n--- authorization manager is NOT uniquely referenced ---\n")
                self._authorizationManager = self._authorizationManager.makeCopy()
            }
//            print("\n--- authorization manager is uniquely referenced ---\n")
            return self._authorizationManager
        }
        set {
            self._authorizationManager = newValue.makeCopy()
        }
    }

}


extension SpotifyAccount: Identifiable {
    
    /// Returns the uri for the user.
    var id: String {
        self.user.uri
    }

}

extension SpotifyAccount: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case user
        case _authorizationManager = "authorization_manager"
    }
    
}

// MARK: Testing

extension SpotifyAccount {
    
    static let sampleAccounts = SpotifyUser.allSampleUsers
        .map { user -> SpotifyAccount in
            let authManager = AuthorizationCodeFlowManager(
                clientId: "", clientSecret: ""
            )
            return SpotifyAccount(user: user, authorizationManager: authManager)
        }

}
