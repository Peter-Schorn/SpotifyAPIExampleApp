import Foundation
import Combine
import UIKit
import SwiftUI
import KeychainAccess
import SpotifyWebAPI

/**
 A helper class that wraps around an instance of `SpotifyAPI`
 and provides convenience methods for authorizing your application.
 
 Its most important role is to handle changes to the authorzation
 information and save them to persistent storage in the keychain.
 */
final class Spotify: NSObject, ObservableObject {
    
    private static let clientId: String = {
        if let clientId = ProcessInfo.processInfo
                .environment["client_id"] {
            return clientId
        }
        fatalError("Could not find 'client_id' in environment variables")
    }()
    
    private static let clientSecret: String = {
        if let clientSecret = ProcessInfo.processInfo
                .environment["client_secret"] {
            return clientSecret
        }
        fatalError("Could not find 'client_secret' in environment variables")
    }()
    
    /// The key in the keychain that is used to store the authorization
    /// information: "authorizationManager".
    static let authorizationManagerKey = "authorizationManager"
    
    /// The URL that Spotify will redirect to after the user either
    /// authorizes or denies authorization for your application.
    static let loginCallbackURL = URL(
        string: "spotify-api-example-app://login-callback"
    )!
    
    /// A cryptographically-secure random string used to ensure
    /// than an incoming redirect from Spotify was the result of a request
    /// made by this app, and not an attacker. **This value is regenerated**
    /// **after each authorization process completes.**
    var authorizationState = String.randomURLSafe(length: 128)
 
    /// The keychain to store the authorization information in.
    let keychain = Keychain(service: "com.Peter-Schorn.SpotifyAPIExampleApp")
    
    /// An instance of `SpotifyAPI` that you use to make requests to
    /// the Spotify web API.
    let api = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowManager(
            clientId: Spotify.clientId, clientSecret: Spotify.clientSecret
        )
    )

    // MARK: Spotify App Remote
    var appRemote: SPTAppRemote

    // MARK: Published Properties

    /**
     Whether or not the application has been authorized. If `true`,
     then you can begin making requests to the Spotify web API
     using the `api` property of this class, which contains an instance
     of `SpotifyAPI`.
     
     When `false`, `LoginView` is presented, which prompts the user to
     login. When this is set to `true`, `LoginView` is dismissed.
     
     This property provides a convenient way for the user interface
     to be updated based on whether the user has logged in with their
     Spotify account yet. For example, you could use this property disable
     UI elements that require the user to be logged in.
     
     This property is updated by `handleChangesToAuthorizationManager()`,
     which is called every time the authorization information changes,
     and `removeAuthorizationManagerFromKeychain()`, which is called
     everytime `SpotifyAPI.authorizationManager.deauthorize()` is called.
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
            redirectURL: Self.loginCallbackURL
        )
        
        self.appRemote = SPTAppRemote(
            configuration: configuration,
            logLevel: .debug
        )
        
        self.playerStateDidChange = self._playerStateDidChange
            .removeDuplicates(by: { $0 == $1 })
            .debounce(for: 0.25, scheduler: RunLoop.main)
            .eraseToAnyPublisher()

        super.init()

//        #warning("debug")
//        self.authorizationManagerDidDeauthorize()

        self.appRemote.delegate = self
//        self.appRemote.playerAPI?.delegate = self
        print("configured delegates")
        
        // Configure the loggers.
        self.api.apiRequestLogger.logLevel = .trace
        // self.api.logger.logLevel = .trace
        
        // MARK: Important: Subscribe to `authorizationManagerDidChange` BEFORE
        // MARK: retrieving `authorizationManager` from persistent storage
        self.api.authorizationManagerDidChange
            // We must receive on the main thread because we are
            // updating the @Published `isAuthorized` property.
            .receive(on: RunLoop.main)
            .sink(receiveValue: handleChangesToAuthorizationManager)
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
        // MARK: the keychain.
        if let authManagerData = keychain[data: Self.authorizationManagerKey] {
            
            do {
                // Try to decode the data.
                let authorizationManager = try JSONDecoder().decode(
                    AuthorizationCodeFlowManager.self,
                    from: authManagerData
                )
                print("found authorization information in keychain")
                
                /*
                 This assignment causes `authorizationManagerDidChange`
                 to emit a signal, meaning that
                 `handleChangesToAuthorizationManager()` will be called.
                 
                 Note that if you had subscribed to
                 `authorizationManagerDidChange` after this line,
                 then `handleChangesToAuthorizationManager()` would not
                 have been called and the @Published `isAuthorized` property
                 would not have been properly updated.
                 
                 We do not need to update `isAuthorized` here because it
                 is already done in `handleChangesToAuthorizationManager()`.
                 */
                self.api.authorizationManager = authorizationManager
                
            } catch {
                print("could not decode authorizationManager from data:\n\(error)")
            }
        }
        else {
            print("did NOT find authorization information in keychain")
        }
        
        
    }
    
    /**
     A convenience method that creates the authorization URL and opens it
     in the browser.
     
     You could also configure it to accept parameters for the authorization
     scopes.
     
     This is called when the user taps the "Log in with Spotify" button
     in `LoginView`.
     */
    func authorize() {

        let url = api.authorizationManager.makeAuthorizationURL(
            redirectURI: Self.loginCallbackURL,
            showDialog: true,
            // This same value **MUST** be provided for the state parameter of
            // `authorizationManager.requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`.
            // Otherwise, an error will be thrown.
            state: authorizationState,
            scopes: [
                .userReadPlaybackState,
                .userModifyPlaybackState,
                .playlistModifyPrivate,
                .playlistModifyPublic,
                .userLibraryRead,
                .userLibraryModify,
                .userReadEmail,
                .appRemoteControl
            ]
        )!
        
        // You can open the URL however you like. For example, you could open
        // it in a web view instead of the browser.
        // See https://developer.apple.com/documentation/webkit/wkwebview
        UIApplication.shared.open(url)
        
    }
    
    /**
     Saves changes to `api.authorizationManager` to the keychain.
     
     This method is called every time the authorization information changes. For
     example, when the access token gets automatically refreshed, (it expires after
     an hour) this method will be called.
     
     It will also be called after the access and refresh tokens are retrieved using
     `requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`.
     
     Read the full documentation for [SpotifyAPI.authorizationManagerDidChange][1].
     
     [1]: https://peter-schorn.github.io/SpotifyAPI/Classes/SpotifyAPI.html#/s:13SpotifyWebAPI0aC0C29authorizationManagerDidChange7Combine18PassthroughSubjectCyyts5NeverOGvp
     */
    func handleChangesToAuthorizationManager() {
        
        withAnimation(LoginView.animation) {
            // Update the @Published `isAuthorized` property.
            // When set to `true`, `LoginView` is dismissed, allowing the
            // user to interact with the rest of the app.
            self.isAuthorized = self.api.authorizationManager.isAuthorized()
        }
        
        print(
            "Spotify.handleChangesToAuthorizationManager: isAuthorized:",
            self.isAuthorized
        )

        // MARK: Update the Access Token for the App Remote
        self.appRemote.connectionParameters.accessToken =
            self.api.authorizationManager.accessToken

        // MARK: Try to connect to the App Remote
        if !self.appRemote.isConnected {
            print("handleChangesToAuthorizationManager: reconnectToAppRemote")
            self.connectToAppRemote()
        }

        self.retrieveCurrentUser()

        
        do {
            // Encode the authorization information to data.
            let authManagerData = try JSONEncoder().encode(
                self.api.authorizationManager
            )
            
            // Save the data to the keychain.
            keychain[data: Self.authorizationManagerKey] = authManagerData
            print("did save authorization manager to keychain")
            
        } catch {
            print(
                "couldn't encode authorizationManager for storage " +
                "in keychain:\n\(error)"
            )
        }
        
    }
 
    /**
     Removes `api.authorizationManager` from the keychain.
     
     This method is called everytime `api.authorizationManager.deauthorize` is
     called.
     */
    func authorizationManagerDidDeauthorize() {
        
        withAnimation {
            self.isAuthorized = false
        }
        
        self.currentUser = nil

        // MARK: Remove the Access Token from the App Remove
        self.appRemote.connectionParameters.accessToken = nil
        
        do {
            /*
             Remove the authorization information from the keychain.
             
             If you don't do this, then the authorization information
             that you just removed from memory by calling `deauthorize()`
             will be retrieved again from persistent storage after this
             app is quit and relaunched.
             */
            try keychain.remove(Self.authorizationManagerKey)
            print("did remove authorization manager from keychain")
            
        } catch {
            print(
                "couldn't remove authorization manager " +
                "from keychain: \(error)"
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
                        print("couldn't retrieve current use: \(error)")
                    }
                },
                receiveValue: { user in
                    self.currentUser = user
                }
            )
            .store(in: &cancellables)
        
    }
    
}

extension Spotify: SPTAppRemoteDelegate {
    
    // MARK: - SPTAppRemoteDelegate -
    
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
        // the disconnect was explicity initiated, in which case
        // we shouldn't try to reconnect.
        if error != nil {
            self.connectToAppRemote()
        }

    }
    
    func shouldTryToReconnectToAppRemote() -> Future<Bool, Never> {
        return Future { promise in
            
            if self.api.authorizationManager.accessToken == nil {
                print(
                    """
                    shouldTryToReconnectToAppRemote: \
                    acccess token is nil
                    """
                )
                promise(.success(false))
            }

            SPTAppRemote.checkIfSpotifyAppIsActive { isActive in
                print(
                    """
                    shouldTryToReconnectToAppRemote: \
                    Spotify App is active: \(isActive)
                    """
                )
                promise(.success(isActive))
            }
        }
        
    }
    
    func connectToAppRemote() {
        self.shouldTryToReconnectToAppRemote()
            .sink { shouldTry in
                print("reconnectToAppRemote: will connect: \(shouldTry)")
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
                // trying to re-subscribe to the player API after receiving
                // an error seems to never work, but connecting to the app
                // remote again does.
                self.connectToAppRemote()
            }
        }
    }
    
}

extension Spotify: SPTAppRemotePlayerStateDelegate {
    
    // MARK: - SPTAppRemotePlayerStateDelegate -

    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("playerStateDidChange: '\(playerState.track.name)'")
        self._playerStateDidChange.send(playerState)
    }

}
