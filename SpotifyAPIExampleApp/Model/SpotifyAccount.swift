import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent
import Foundation

/// Contains a `SpotifyUser` and an authorization manager, which are
/// stored together in the keychain.
struct SpotifyAccount: Hashable {
    
    var user: SpotifyUser
    var authorizationManager: AuthorizationCodeFlowManager

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
        case authorizationManager = "authorization_manager"
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
