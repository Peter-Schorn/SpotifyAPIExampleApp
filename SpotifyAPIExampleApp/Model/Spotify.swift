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
final class Spotify: ObservableObject {
    
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
    
    /// The key in the keychain that is used to store the authorization
    /// information: "authorizationManager".
    let authorizationManagerKey = "authorizationManager"
    
    /// The URL that Spotify will redirect to after the user either authorizes
    /// or denies authorization for your application.
    let loginCallbackURL = URL(
        string: "spotify-api-example-app://login-callback"
    )!
    
    /// A cryptographically-secure random string used to ensure than an incoming
    /// redirect from Spotify was the result of a request made by this app, and
    /// not an attacker. **This value is regenerated after each authorization**
    /// **process completes.**
    var authorizationState = String.randomURLSafe(length: 128)
    
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
    
    /// If `true`, then the app is retrieving access and refresh tokens. Used by
    /// `LoginView` to present an activity indicator.
    @Published var isRetrievingTokens = false
    
    @Published var currentUser: SpotifyUser? = nil
    
    // MARK: Auto-Refresh Tokens
    
    /// The keychain to store the authorization information in.
    let keychain = Keychain(service: "com.Peter-Schorn.SpotifyAPIExampleApp")
    
    /// An instance of `SpotifyAPI` that you use to make requests to the Spotify
    /// web API.
    let api = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowManager(
            clientId: Spotify.clientId,
            clientSecret: Spotify.clientSecret
        )
    )
    
    var cancellables: Set<AnyCancellable> = []

    var refreshTokensCancellable: AnyCancellable? = nil
    
    let refreshTokensQueue = DispatchQueue(label: "refreshTokens")
    
    // MARK: - Methods -
    
    init() {
        
        // Configure the loggers.
        self.api.apiRequestLogger.logLevel = .trace
        // self.api.logger.logLevel = .trace
        
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
        
        
        // MARK: Check to see if the authorization information is saved in
        // MARK: the keychain.
        if let authManagerData = keychain[data: self.authorizationManagerKey] {
            
            do {
                // Try to decode the data.
                let authorizationManager = try JSONDecoder().decode(
                    AuthorizationCodeFlowManager.self,
                    from: authManagerData
                )
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
                
                if !self.api.authorizationManager.accessTokenIsExpired() {
                    self.autoRefreshTokensWhenExpired()
                }
                self.api.authorizationManager.refreshTokens(
                    onlyIfExpired: true
                )
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            print(
                                "Spotify.init: couldn't refresh tokens:\n\(error)"
                            )
                    }
                })
                .store(in: &self.cancellables)
                
            } catch {
                print("could not decode authorizationManager from data:\n\(error)")
            }
        }
        else {
            print("did NOT find authorization information in keychain")
        }
        
    }
    
    private func autoRefreshTokensWhenExpired() {

        guard let expirationDate = self.api.authorizationManager
                .expirationDate else {
            return
        }
        
        // subtract 1 minute and 55 from the expiration date
        let refreshDate = expirationDate.addingTimeInterval(-115)
        
        // the difference between the current date and the date that the
        // tokens should be refreshed, which represents the delay we must
        // add to a timer for it to fire at the `refreshDate`.
        let refreshDelay = refreshDate.timeIntervalSince1970 - Date().timeIntervalSince1970

        self.refreshTokensCancellable = Result.Publisher(())
            .delay(
                for: .seconds(refreshDelay),
                scheduler: self.refreshTokensQueue
            )
            .flatMap {
                // this method should be called 1 minute and 55 seconds before
                // the access token expires.
                return self.api.authorizationManager.refreshTokens(
                    onlyIfExpired: true
                )
            }
            .sink(receiveCompletion: { completion in
                print("autoRefreshTokensWhenExpired completion: \(completion)")
            })

        
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
        
        let url = api.authorizationManager.makeAuthorizationURL(
            redirectURI: self.loginCallbackURL,
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
                .userReadRecentlyPlayed
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
     example, when the access token gets automatically refreshed, (it expires
     after an hour) this method will be called.

     It will also be called after the access and refresh tokens are retrieved
     using `requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`.

     Read the full documentation for
     [SpotifyAPI.authorizationManagerDidChange][1].

     [1]: https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/spotifyapi/authorizationmanagerdidchange
     */
    func authorizationManagerDidChange() {
        
        withAnimation(LoginView.animation) {
            // Update the @Published `isAuthorized` property. When set to
            // `true`, `LoginView` is dismissed, allowing the user to interact
            // with the rest of the app.
            self.isAuthorized = self.api.authorizationManager.isAuthorized()
        }
        
        print(
            "Spotify.authorizationManagerDidChange: isAuthorized:",
            self.isAuthorized
        )
        
        self.autoRefreshTokensWhenExpired()
        
        self.retrieveCurrentUser()
        
        do {
            // Encode the authorization information to data.
            let authManagerData = try JSONEncoder().encode(
                self.api.authorizationManager
            )
            
            // Save the data to the keychain.
            keychain[data: self.authorizationManagerKey] = authManagerData
            print("did save authorization manager to keychain")
            
        } catch {
            print(
                "couldn't encode authorizationManager for storage " +
                    "in keychain:\n\(error)"
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
        
        withAnimation(LoginView.animation) {
            self.isAuthorized = false
        }
        
        self.currentUser = nil
        self.refreshTokensCancellable = nil
        
        do {
            /*
             Remove the authorization information from the keychain.

             If you don't do this, then the authorization information that you
             just removed from memory by calling
             `SpotifyAPI.authorizationManager.deauthorize()` will be retrieved
             again from persistent storage after this app is quit and
             relaunched.
             */
            try keychain.remove(self.authorizationManagerKey)
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
                        print("couldn't retrieve current user: \(error)")
                    }
                },
                receiveValue: { user in
                    self.currentUser = user
                }
            )
            .store(in: &cancellables)
        
    }

}
