import Foundation
import Combine
import UIKit
import SwiftUI
import KeychainAccess
import SpotifyWebAPI

/**
 A helper class that wraps around an instance of `SpotifyAPI` and provides
 convenience methods for authorizing your application.

 Its most important role is to handle changes to the authorization information
 and save them to persistent storage in the keychain.
 */
final class Spotify: NSObject, ObservableObject {
    
    private static let clientId: String = {
        if let clientId = ProcessInfo.processInfo
                .environment["CLIENT_ID"] {
            return clientId
        }
        fatalError("Could not find 'CLIENT_ID' in environment variables")
    }()
    
    private static let clientSecret: String = {
        if let clientSecret = ProcessInfo.processInfo
                .environment["CLIENT_SECRET"] {
            return clientSecret
        }
        fatalError("Could not find 'CLIENT_SECRET' in environment variables")
    }()
    
    private static let tokensURL: URL = {
        if let tokensURLString = ProcessInfo.processInfo
                .environment["TOKENS_URL"] {
            if let tokensURL = URL(string: tokensURLString) {
                return tokensURL
            }
            fatalError("could not convert to URL: '\(tokensURLString)'")
        }
        fatalError("Could not find 'TOKENS_URL' in environment variables")
    }()
    
    private static let tokenRefreshURL: URL = {
        if let tokensURLString = ProcessInfo.processInfo
                .environment["TOKENS_REFRESH_URL"] {
            if let tokensURL = URL(string: tokensURLString) {
                return tokensURL
            }
            fatalError("could not convert to URL: '\(tokensURLString)'")
        }
        fatalError("Could not find 'TOKENS_REFRESH_URL' in environment variables")
    }()
    
    /// The key in the keychain that is used to store the authorization
    /// information: "authorizationManager".
    let authorizationManagerKey = "authorizationManager"
    
    /// The key in the keychain that is used to store the session: "session".
    let sessionKey = "session"
    
    /// The URL that Spotify will redirect to after you connect to the app
    /// remote
    let appRemoteCallbackURL = URL(
        string: "peter-schorn-spotify-sdk-app://app-remote-callback"
    )!
    
    // MARK: Keychain

    /// The keychain to store the authorization information in.
    let keychain = Keychain(service: "com.Peter-Schorn.SpotifyAPIExampleApp")
    
    // MARK: API

    /// An instance of `SpotifyAPI` that you use to make requests to
    /// the Spotify web API.
    let api = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowBackendManager(
            backend: AuthorizationCodeFlowProxyBackend(
                clientId: Spotify.clientId,
                tokensURL: Spotify.tokensURL,
                tokenRefreshURL: Spotify.tokenRefreshURL,
                decodeServerError: VaporServerError.decodeFromNetworkResponse(data:response:)
            )
        )
    )

    // MARK: Spotify SDK
    
    var appRemote: SPTAppRemote
    let sessionManager: SPTSessionManager

    // MARK: Published Properties

    /**
     Whether or not the application has been authorized. If `true`, then you can
     begin making requests to the Spotify web API using the `api` property of
     this class, which contains an instance of `SpotifyAPI`.

     When `false`, `LoginView` is presented, which prompts the user to login.
     When this is set to `true`, `LoginView` is dismissed.

     This property provides a convenient way for the user interface to be
     updated based on whether the user has logged in with their Spotify account
     yet. For example, you could use this property disable UI elements that
     require the user to be logged in.

     This property is updated by `authorizationManagerDidChange()`, which is
     called every time the authorization information changes, and
     `authorizationManagerDidDeauthorize()`, which is called every time
     `SpotifyAPI.authorizationManager.deauthorize()` is called.
     */
    @Published var isAuthorized = false

    @Published var appRemoteIsConnected = false

    /// If `true`, then the app is retrieving access and refresh tokens.
    /// Used by `LoginView` to present an activity indicator.
    @Published var isRetrievingTokens = false
    
    @Published var currentUser: SpotifyUser? = nil
    
    // MARK: Publishers

    let appRemoteDidEstablishConnection = PassthroughSubject<Void, Never>()

    let appRemoteDidFailConnectionAttempt = PassthroughSubject<Error?, Never>()

    /// Emits every time `Spotify.sessionManager(manager:didFailWith:)` is
    /// called.
    let sessionManagerDidFailWithError = PassthroughSubject<Error, Never>()

    let playerStateDidChange: AnyPublisher<SPTAppRemotePlayerState, Never>

    // MARK: Private Properties

    private let _playerStateDidChange =
            PassthroughSubject<SPTAppRemotePlayerState, Never>()

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Methods -
    
    override init() {
        
        print("\n--- initializing spotify ---\n")

        // MARK: Configure the App Remote
        
        let configuration = SPTConfiguration(
            clientID: Self.clientId,
            redirectURL: self.appRemoteCallbackURL
        )
        
        configuration.tokenSwapURL = Self.tokensURL
        configuration.tokenRefreshURL = Self.tokenRefreshURL

        self.appRemote = SPTAppRemote(
            configuration: configuration,
            logLevel: .debug
        )
        
        self.sessionManager = SPTSessionManager(
            configuration: configuration,
            delegate: nil
        )
        
        self.playerStateDidChange = self._playerStateDidChange
            .removeDuplicates(by: { $0 == $1 })
            .debounce(for: 0.25, scheduler: RunLoop.main)
            .eraseToAnyPublisher()

        super.init()
        
        if CommandLine.arguments.contains("Xcode-UI-testing") {
            self.configureForUITesting()
        }

        self.sessionManager.delegate = self
        self.appRemote.delegate = self
        print("configured delegates")
        
        // Configure the loggers.
//        self.api.setupDebugging()
        self.api.apiRequestLogger.logLevel = .trace
         self.api.logger.logLevel = .trace
        
        // MARK: Important: Subscribe to `authorizationManagerDidChange` BEFORE
        // MARK: retrieving `authorizationManager` from persistent storage
        self.api.authorizationManagerDidChange
            // We must receive on the main thread because we are updating the
            // @Published `isAuthorized` property.
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidChange)
            .store(in: &cancellables)
        
        self.api.authorizationManagerDidDeauthorize
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidDeauthorize)
            .store(in: &cancellables)
        
        self.$appRemoteIsConnected.sink { isConnected in
            print("appRemoteIsConnected: \(isConnected)")
        }
        .store(in: &self.cancellables)
        
        // MARK: Check to see if the authorization information is saved in
        // MARK: the keychain
        if let authManagerData = self.keychain[data: self.authorizationManagerKey] {
            
            do {
                // Try to decode the data.
                let authorizationManager = try JSONDecoder().decode(
                    AuthorizationCodeFlowBackendManager<AuthorizationCodeFlowProxyBackend>.self,
                    from: authManagerData
                )
                // this property is NOT serialized to data; therefore, it must
                // be assigned after deserialization.
                authorizationManager.backend.decodeServerError =
                    VaporServerError.decodeFromNetworkResponse(data:response:)
                print("found authorization information in keychain")
                
                /*
                 This assignment causes `authorizationManagerDidChange` to emit
                 a signal, meaning that `authorizationManagerDidChange()` will
                 be called.

                 Note that if you had subscribed to
                 `authorizationManagerDidChange` after this line, then
                 `authorizationManagerDidChange()` would not have been called
                 and the @Published `isAuthorized` property would not have been
                 properly updated.

                 We do not need to update `isAuthorized` here because it is
                 already done in `authorizationManagerDidChange()`.
                 */
                self.api.authorizationManager = authorizationManager

            } catch {
                print(
                    "could not decode authorization manager from " +
                    "data:\n\(error)"
                )
            }
        }
        else {
            print("did NOT find authorization information in keychain")
        }
        
        // MARK: Decode the session from the keychain
        if let sessionData = self.keychain[data: self.sessionKey] {
            do {
                
                let object = try NSKeyedUnarchiver
                        .unarchiveTopLevelObjectWithData(sessionData)
                
                if let session = object as? SPTSession {
                    self.sessionManager.session = session
                    print(
                        "decoded session from data and assigned to " +
                        "session manager"
                    )
                }
                else {
                    print(
                        "could not cast unarchived object to `SPTSession`:\n" +
                        "\(object as Any)"
                    )
                }
                

            } catch {
                print("could not decode session from data:\n\(error)")
            }
        }
        
    }
    
    /**
     A convenience method that creates the authorization URL and opens it in the
     browser.

     You could also configure it to accept parameters for the authorization
     scopes.

     This is called when the user taps the "Log in with Spotify" button in
     `LoginView`.
     */
    func authorize() {
        let scopes: SPTScope = [
            .userReadPlaybackState,
            .userModifyPlaybackState,
            .playlistModifyPrivate,
            .playlistModifyPublic,
            .userLibraryRead,
            .userLibraryModify,
            .userReadEmail,
            .appRemoteControl,
            .userReadRecentlyPlayed
        ]
        
        self.sessionManager.initiateSession(with: scopes, options: .default)

    }
    
    /**
     Saves changes to `api.authorizationManager` to the keychain.

     This method is called every time the authorization information changes. For
     example, when the access token gets automatically refreshed, (it expires
     after an hour) this method will be called.

     It will also be called after the access and refresh tokens are retrieved
     using `requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`.

     Read the full documentation for
     [SpotifyAPI.authorizationManagerDidChange][1].

     [1]: https://peter-schorn.github.io/SpotifyAPI/Classes/SpotifyAPI.html#/s:13SpotifyWebAPI0aC0C29authorizationManagerDidChange7Combine18PassthroughSubjectCyyts5NeverOGvp
     */
    func authorizationManagerDidChange() {
        
        withAnimation(LoginView.animation) {
            // Update the @Published `isAuthorized` property. When set to
            // `true`, `LoginView` is dismissed, allowing the user to interact
            // with the rest of the app.
            self.isAuthorized = self.api.authorizationManager.isAuthorized()
        }
        
        print(
            "Spotify.authorizationManagerDidChange: isAuthorized: ",
            self.isAuthorized
        )

        // MARK: Update the Access Token for the App Remote
        self.appRemote.connectionParameters.accessToken =
            self.api.authorizationManager.accessToken

        // MARK: Try to connect to the App Remote
        if !self.appRemote.isConnected {
            print("Spotify.authorizationManagerDidChange: connectToAppRemote")
            self.connectToAppRemote()
        }

        self.retrieveCurrentUser()

        do {
            // encode the authorization information to data
            let authManagerData = try JSONEncoder().encode(
                self.api.authorizationManager
            )
            self.keychain[data: self.authorizationManagerKey] = authManagerData
            print("did save authorization manager to the keychain")
            
            // encode the `SPTSession` to data if it is non-`nil`.
            if let session = self.sessionManager.session {
                let sessionData = try NSKeyedArchiver.archivedData(
                    withRootObject: session,
                    requiringSecureCoding: false
                )
                self.keychain[data: self.sessionKey] = sessionData
                print("did save session to the keychain")
                
            }
            
        } catch {
            print(
                "couldn't encode authorizationManager or session for " +
                "storage in keychain:\n\(error)"
            )
        }
        
    }
 
    /**
     Removes `api.authorizationManager` from the keychain and sets `currentUser`
     to `nil`.

     This method is called every time `api.authorizationManager.deauthorize` is
     called.
     */
    func authorizationManagerDidDeauthorize() {
        
        withAnimation {
            self.isAuthorized = false
        }
        
        self.isRetrievingTokens = false
        self.currentUser = nil

        // MARK: Remove the Access Token from the App Remove
        self.appRemote.connectionParameters.accessToken = nil
        
        do {
            /*
             Remove the authorization information from the keychain.

             If you don't do this, then the authorization information that you
             just removed from memory by calling
             `SpotifyAPI.authorizationManager.deauthorize()` will be retrieved
             again from persistent storage after this app is quit and
             relaunched.
             */
            try self.keychain.remove(self.authorizationManagerKey)
            print("did remove authorization manager from keychain")
            try self.keychain.remove(self.sessionKey)
            print("did remove session from keychain")
            
        } catch {
            print(
                "couldn't remove authorization manager or session from " +
                "keychain:\n\(error)"
            )
        }
    }
    
    /**
     Retrieve the current user.
     
     - Parameter onlyIfNil: Only retrieve the user if `self.currentUser`
           is `nil`.
     */
    func retrieveCurrentUser(onlyIfNil: Bool = true) {
        
        if onlyIfNil && self.currentUser != nil {
            return
        }

        guard self.isAuthorized else { return }

        self.api.currentUserProfile()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("couldn't retrieve current user: \(error)")
                    }
                },
                receiveValue: { user in
                    self.currentUser = user
                }
            )
            .store(in: &cancellables)
        
    }
    
    /// Called in the initializer if this app has been launched for a UI test.
    func configureForUITesting() {
        
        if CommandLine.arguments.contains("reset-authorization") {
            do {
                print("will remove all keychain items")
                // remove the authorization information and make the user
                // log in again
                try self.keychain.removeAll()
                
            } catch {
                // don't continue the UI tests if we catch an error here
                fatalError("could not remove all items from keychain: \(error)")
            }
        }

        self.sessionManager.alwaysShowAuthorizationDialog = true

    }

}

// MARK: - SPTAppRemoteDelegate -

extension Spotify: SPTAppRemoteDelegate {
    
    func appRemoteDidEstablishConnection(
        _ appRemote: SPTAppRemote
    ) {
        print("appRemoteDidEstablishConnection")
        self.appRemote.playerAPI?.delegate = self
        assert(self.appRemote.playerAPI != nil)
        
        self.subscribeToPlayerState()
        self.appRemoteIsConnected = self.appRemote.isConnected
        self.appRemoteDidEstablishConnection.send()
        
        
    }
    
    func appRemote(
        _ appRemote: SPTAppRemote,
        didFailConnectionAttemptWithError error: Error?
    ) {
        print("appRemote didFailConnectionAttemptWithError: \(error as Any)")
        self.appRemoteIsConnected = self.appRemote.isConnected
        self.appRemoteDidFailConnectionAttempt.send(error)
    }
    
    func appRemote(
        _ appRemote: SPTAppRemote,
        didDisconnectWithError error: Error?
    ) {
        print("appRemove didDisconnectWithError: \(error as Any)")
        self.appRemoteIsConnected = self.appRemote.isConnected

        // the documentation says that the error will be `nil` if
        // the disconnect was explicitly initiated, in which case
        // we shouldn't try to reconnect.
        if error != nil {
            self.connectToAppRemote()
        }

    }
    
    func shouldTryToConnectToAppRemote() -> Future<Bool, Never> {
        return Future { promise in
            
            if self.appRemote.connectionParameters.accessToken == nil {
                print(
                    "shouldTryToConnectToAppRemote: access token is nil"
                )
                promise(.success(false))
            }

            SPTAppRemote.checkIfSpotifyAppIsActive { isActive in
                print(
                    """
                    shouldTryToConnectToAppRemote: \
                    Spotify App is active: \(isActive)
                    """
                )
                promise(.success(isActive))
            }
        }
        
    }
    
    func connectToAppRemote() {
        self.shouldTryToConnectToAppRemote()
            .sink { shouldTry in
                print("connectToAppRemote: will connect: \(shouldTry)")
                if shouldTry {
                    self.appRemote.connect()
                }
            }
            .store(in: &self.cancellables)
    }

    func subscribeToPlayerState() {
        self.appRemote.playerAPI?.subscribe { _, error in
            if let error = error {
                print(
                    """
                    received error from appRemote.playerAPI?.subscribe:
                    \(error)
                    """
                )
                // trying to re-subscribe to the player API after receiving an
                // error seems to never work, but connecting to the app remote
                // again usually does.
                self.connectToAppRemote()
            }
        }
    }
    
}

// MARK: - SPTAppRemotePlayerStateDelegate -

extension Spotify: SPTAppRemotePlayerStateDelegate {
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        DispatchQueue.main.async {
            print("playerStateDidChange: '\(playerState.track.name)'")
            self._playerStateDidChange.send(playerState)
        }
    }

}

// MARK: - SPTSessionManagerDelegate -

extension Spotify: SPTSessionManagerDelegate {
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        let currentDate = Date()
        DispatchQueue.main.async {
            
            print("Spotify.sessionManager(manager:didInitiate:) \(session)")
            
            self.isRetrievingTokens = false

            let actualExpirationDate: Date

            let currentTimestamp = currentDate.timeIntervalSince1970
            let sessionExpirationTimestamp =
                    session.expirationDate.timeIntervalSince1970
            
            /*
             There is a bug with the Spotify iOS SDK in which
             `session.expirationDate` (the expiration date of the access token)
             is set to the date that the access token was retrieved, when it
             should be set to one hour after the access token was retrieved.
             
             If `session.expirationDate` is equal to the current date within a
             tolerance of 5 minutes, then we assume it's wrong and use the
             current date + one hour as the expiration date.
             */
            if abs(sessionExpirationTimestamp - currentTimestamp) <= 300 {
                actualExpirationDate = currentDate.addingTimeInterval(3_600)
            }
            else {
                actualExpirationDate = session.expirationDate
            }
            
            // assigning a new authorization manager to this property causes
            // `authorizationManagerDidChange` to be called, which will assign
            // the new access token to the app remote and make sure the new
            // authorization manager gets saved to persistent storage
            self.api.authorizationManager = .init(
                backend: self.api.authorizationManager.backend,
                accessToken: session.accessToken,
                expirationDate: actualExpirationDate,
                refreshToken: session.refreshToken,
                scopes: Scope.fromSPTScope(session.scope)
            )
            
        }
        
    }
 
    /// Called after the access token has been refreshed.
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        DispatchQueue.main.async {
            print("Spotify.sessionManager(manager:didRenew:) \(session)")
            
            // assigning a new authorization manager to this property causes
            // `authorizationManagerDidChange` to be called, which will assign
            // the new access token to the app remote and make sure the new
            // authorization manager gets saved to persistent storage
            self.api.authorizationManager = .init(
                backend: self.api.authorizationManager.backend,
                accessToken: session.accessToken,
                expirationDate: session.expirationDate,
                refreshToken: session.refreshToken,
                scopes: Scope.fromSPTScope(session.scope)
            )
            
        }
    }

    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        DispatchQueue.main.async {
            print("Spotify.sessionManager(manager:didFailWith:) \(error)")
            self.api.authorizationManager.deauthorize()
            self.sessionManagerDidFailWithError.send(error)
        }
    }

    func sessionManager(
        manager: SPTSessionManager,
        shouldRequestAccessTokenWith code: String
    ) -> Bool {
        // We only use this method to be notified of when the authorization code
        // is received. The Spotify iOS SDK can request the access token.
        DispatchQueue.main.async {
            self.isRetrievingTokens = true
        }
        return true
    }

}
