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

//extension SpotifyAccount {
//
//    private struct AuthManagerStorage: Hashable, Codable {
//
//        init(
//            clientId: String,
//            clientSecret: String,
//            accessToken: String?,
//            refreshToken: String?,
//            expirationDate: Date?,
//            scopes: Set<Scope>?
//        ) {
//            self.clientId = clientId
//            self.clientSecret = clientSecret
//            self.accessToken = accessToken
//            self.refreshToken = refreshToken
//            self.expirationDate = expirationDate
//            self.scopes = scopes ?? []
//        }
//
//        init(_ authorizationManager: AuthorizationCodeFlowManager) {
//            self.init(
//                clientId: authorizationManager.clientId,
//                clientSecret: authorizationManager.clientSecret,
//                accessToken: authorizationManager.accessToken,
//                refreshToken: authorizationManager.refreshToken,
//                expirationDate: authorizationManager.expirationDate,
//                scopes: authorizationManager.scopes
//            )
//        }
//
//        let clientId: String
//        let clientSecret: String
//        let accessToken: String?
//        let refreshToken: String?
//        let expirationDate: Date?
//        let scopes: Set<Scope>
//
//        func makeAuthorizationManager() -> AuthorizationCodeFlowManager {
//            
//            if let accessToken = self.accessToken,
//                    let refreshToken = self.refreshToken,
//                    let expirationDate = self.expirationDate {
//                
//                return AuthorizationCodeFlowManager(
//                    clientId: self.clientId,
//                    clientSecret: self.clientSecret,
//                    accessToken: accessToken,
//                    expirationDate: expirationDate,
//                    refreshToken: refreshToken,
//                    scopes: self.scopes
//                )
//            }
//            
//            return AuthorizationCodeFlowManager(
//                clientId: self.clientId,
//                clientSecret: self.clientSecret
//            )
//            
//
//        }
//    }
//
//}

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
