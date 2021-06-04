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
    
    static let clientId: String = {
        if let clientId = ProcessInfo.processInfo
                .environment["CLIENT_ID"] {
            return clientId
        }
        fatalError("Could not find 'CLIENT_ID' in environment variables")
    }()
    
    static let clientSecret: String = {
        if let clientSecret = ProcessInfo.processInfo
                .environment["CLIENT_SECRET"] {
            return clientSecret
        }
        fatalError("Could not find 'CLIENT_SECRET' in environment variables")
    }()
    
    // MARK: Keychain keys
    var spotifyAccountsKey = "spotifyAccounts"
    
    var currentAccountKey = "currentSpotifyAccount"
    
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
    
<<<<<<< HEAD
    @Published var accountsListViewIsPresented = true

    /// If `true`, then the app is retrieving access and refresh tokens.
    /// Used by `LoginView` to present an activity indicator.
=======
    /// If `true`, then the app is retrieving access and refresh tokens. Used by
    /// `LoginView` to present an activity indicator.
>>>>>>> 4f98519... Reformatted comments to 80 characters per line in Spotify, RootView, LoginView, and ExamplesListView.
    @Published var isRetrievingTokens = false
    
    /// The keychain to store the authorization information in.
    let keychain = Keychain(service: "com.Peter-Schorn.SpotifyAPIExampleApp")
<<<<<<< HEAD

    /// An instance of `SpotifyAPI` that you use to make requests to
    /// the Spotify web API.
=======
    
    /// An instance of `SpotifyAPI` that you use to make requests to the Spotify
    /// web API.
>>>>>>> 4f98519... Reformatted comments to 80 characters per line in Spotify, RootView, LoginView, and ExamplesListView.
    let api = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowManager(
            clientId: Spotify.clientId,
            clientSecret: Spotify.clientSecret
        )
    )
    
    @Published var accounts: [SpotifyAccount] = []
    
    /// This will be set when `self.currentAccount` is set and should not be
    /// set directly anywhere else; therefore, its setter is private.
    private(set) var currentAccountURI: String? {
        get {
            self.keychain[self.currentAccountKey]
        }
        set {
            self.keychain[self.currentAccountKey] = newValue
        }
    }

    /// Gets and sets the current Spotify account. Will also
    /// update `self.currentAccountURI` accordingly.
    var currentAccount: SpotifyAccount? {
        get {
            guard let currentAccountURI = self.currentAccountURI else {
                return nil
            }
            return self.accounts.first(where: { account in
                account.user.uri == currentAccountURI
            })
        }
        set(account) {
            self.objectWillChange.send()
            if var accountCopy = account {
                self.api.authorizationManager = accountCopy.authorizationManager
                self.currentAccountURI = accountCopy.user.uri
            }
            else {
                self.currentAccountURI = nil
                
            }
            
        }
    }
    
    var currentUser: SpotifyUser? {
        self.currentAccount?.user
    }
    
    var cancellables: Set<AnyCancellable> = []

    // MARK: - Methods -
    
    init() {
        
        // Configure the loggers.
//        self.api.apiRequestLogger.logLevel = .trace
        self.api.setupDebugging()
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
        
        if let accountsData = self.keychain[data: self.spotifyAccountsKey] {
            do {
                self.accounts = try JSONDecoder().decode(
                    [SpotifyAccount].self,
                    from: accountsData
                )
<<<<<<< HEAD
                if var currentAccount = self.currentAccount {
                    self.api.authorizationManager = currentAccount.authorizationManager
                    self.accountsListViewIsPresented = false
                }
                else {
                    print("Spotify.init: couldn't get current account")
                }
=======
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
>>>>>>> 4f98519... Reformatted comments to 80 characters per line in Spotify, RootView, LoginView, and ExamplesListView.
                
            } catch {
                print("could not decode spotify accounts from data:\n\(error)")
            }
        }
        else {
            print("did not find any accounts in the keychain")
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
    
    func requestAccessAndRefreshTokens(
        redirectURIWithQuery: URL
    ) -> AnyPublisher<Void, Error> {
        
        // **Always** validate URLs; they offer a potential attack
        // vector into your app.
        guard redirectURIWithQuery.scheme == self.loginCallbackURL.scheme else {
            return SpotifyGeneralError.other(
                "unexpected scheme in url: \(redirectURIWithQuery)",
                localizedDescription: "The redirect could not be handled"
            )
            .anyFailingPublisher()
            
        }
        
        print("received redirect from Spotify: '\(redirectURIWithQuery)'")
        
        // This property is used to display an activity indicator in
        // `LoginView` indicating that the access and refresh tokens
        // are being retrieved.
        self.isRetrievingTokens = true
        
        // MARK: IMPORTANT: generate a new value for the state parameter
        // MARK: after each authorization request. This ensures an incoming
        // MARK: redirect from Spotify was the result of a request made by
        // MARK: this app, and not an attacker.
        defer {
            self.authorizationState = String.randomURLSafe(length: 128)
        }
        
        // Complete the authorization process by requesting the
        // access and refresh tokens.
        return self.api.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: redirectURIWithQuery,
            // This value must be the same as the one used to create the
            // authorization URL. Otherwise, an error will be thrown.
            state: self.authorizationState
        )
        .flatMap(self.api.currentUserProfile)
        .receive(on: RunLoop.main)
        .map { (user: SpotifyUser) -> Void in

            let account = SpotifyAccount(
                user: user,
                authorizationManager: self.api.authorizationManager
            )
            
            // remove the account if a prior version already exists
            self.accounts.removeAll(where: { $0.user.uri == user.uri })
            
            self.accounts.append(account)
            self.currentAccount = account
            self.isAuthorized = true
            self.accountsListViewIsPresented = false
            self.updateAccountsInKeychain()

        }
        .handleEvents(receiveCompletion: { completion in
            // Whether the request succeeded or not, we need to remove
            // the activity indicator.
            self.isRetrievingTokens = false
        })
        .eraseToAnyPublisher()
        

    }
    
    /// Saves `self.accounts` to the keychain.
    func updateAccountsInKeychain() {
        do {

            let accountsData = try JSONEncoder().encode(self.accounts)
            self.keychain[data: self.spotifyAccountsKey] = accountsData
            print("did save accounts to keychain")

        } catch {
            print(
                "couldn't encode accounts for storage in keychain:\n\(error)"
            )
        }
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
        
<<<<<<< HEAD
        // Update the @Published `isAuthorized` property.
        // When set to `true`, `LoginView` is dismissed, allowing the
        // user to interact with the rest of the app.
        self.isAuthorized = self.api.authorizationManager.isAuthorized()

=======
        withAnimation(LoginView.animation) {
            // Update the @Published `isAuthorized` property. When set to
            // `true`, `LoginView` is dismissed, allowing the user to interact
            // with the rest of the app.
            self.isAuthorized = self.api.authorizationManager.isAuthorized()
        }
        
>>>>>>> 4f98519... Reformatted comments to 80 characters per line in Spotify, RootView, LoginView, and ExamplesListView.
        print(
            "Spotify.authorizationManagerDidChange: isAuthorized:",
            self.isAuthorized
        )
        
        // Don't save the authorization manager to persistent storage here
        // if we just retrieved the access and refresh tokens. Instead,
        // we'll do that in
        // `Spotify.requestAccessAndRefreshTokens(redirectURIWithQuery:)`
        guard !self.isRetrievingTokens else { return }
        
        print(
            "Spotify.handleChangesToAuthorizationManager: NOT retrieving tokens"
        )

        guard
            let currentAccountURI = self.currentAccountURI,
            let currentAccountIndex = self.accounts.firstIndex(
                where: { $0.user.uri == currentAccountURI }
            )
        else {
            print(
                "handleChangesToAuthorizationManager: couldn't get current account"
            )
            return
        }
        
        self.accounts[currentAccountIndex].authorizationManager =
                self.api.authorizationManager

        self.updateAccountsInKeychain()
        
    }
    
    /**
<<<<<<< HEAD
     Sets `self.isAuthorized` to` `false`.
    
=======
     Removes `api.authorizationManager` from the keychain and sets `currentUser`
     to `nil`.

>>>>>>> 4f98519... Reformatted comments to 80 characters per line in Spotify, RootView, LoginView, and ExamplesListView.
     This method is called every time `api.authorizationManager.deauthorize` is
     called.
     */
    func authorizationManagerDidDeauthorize() {
<<<<<<< HEAD
    
        self.isAuthorized = false
    
=======
        
        withAnimation(LoginView.animation) {
            self.isAuthorized = false
        }
        
        self.currentUser = nil
        
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
        
>>>>>>> 4f98519... Reformatted comments to 80 characters per line in Spotify, RootView, LoginView, and ExamplesListView.
    }

}
