//
//  RootView.swift
//  SpotifyAPIExampleApp
//
//  Created by Peter Schorn on 9/19/20.
//

import SwiftUI
import Combine
import SpotifyWebAPI

struct RootView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    /// If `true`, then the app is retrieving access and refresh tokens.
    @State private var isRetrievingTokens = false
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    var body: some View {
        NavigationView {
            ExamplesListView()
                .navigationBarTitle("Spotify Example App")
                .navigationBarItems(trailing: logoutButton)
                .disabled(!spotify.isAuthorized)
        }
        // The login view is presented if `spotify.isAuthorized` == `false.
        // When the login button is tapped, `spotify.authorize()` is called.
        .modifier(
            LoginView(
                isAuthorized: $spotify.isAuthorized,
                isRetrievingTokens: $isRetrievingTokens
            )
        )
        // Presented if an error occurs during the process of authorizing
        // with the user's Spotify account.
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
        .onOpenURL(perform: handleURL(_:))
        
    }
    
    /**
     Handle the URL that Spotify redirects to after the user
     Either authorizes or denies authorizaion for the application.
     
     This method is called by the `onOpenURL(perform:)` view modifier
     directly above.
     */
    func handleURL(_ url: URL) {
        
        // **Always** validate URLs; they offer a potential attack
        // vector into your app.
        guard url.scheme == Spotify.loginCallbackURL.scheme else {
            print("not handling URL: unexpected scheme: '\(url)'")
            return
        }

        // This property is used to display an activity indicator in
        // `LoginView` indicating that the access and refresh tokens
        // are being retrieved.
        self.isRetrievingTokens = true
        
        // Complete the authorization process by requesting the
        // access and refresh tokens.
        spotify.api.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: url,
            // This value must be the same as the one used to create the
            // authorization URL. Otherwise, an error will be thrown.
            state: spotify.authorizationState
        )
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
            // Whether the request succeeded or not, we need to remove
            // the activity indicator.
            self.isRetrievingTokens = false
            
            /*
             After the access and refresh tokens are retrieved,
             `SpotifyAPI.authorizationManagerDidChange` will emit a
             signal, causing `handleChangesToAuthorizationManager()` to be
             called, which will dismiss the loginView if the app was
             successfully authorized by setting the
             @Published `spotify.isAuthorized` property to `true`.

             The only thing we need to do here is handle the error and
             show it to the user if one was received.
             */
            if case .failure(let error) = completion {
                if let authError = error as? SpotifyAuthorizationError,
                        authError.accessWasDenied {
                    self.alertTitle =
                        "You Denied The Authorization Request :("
                }
                else {
                    self.alertTitle =
                        "Couldn't Authorization With Your Account"
                    self.alertMessage = error.localizedDescription
                }
                self.alertIsPresented = true
            }
        })
        .store(in: &cancellables)
        
        // MARK: IMPORTANT: generate a new value for the state parameter
        // MARK: after each authorization request. This ensures an incoming
        // MARK: redirect from Spotify was the result of a request made by
        // MARK: this app, and not an attacker.
        self.spotify.authorizationState = String.randomURLSafe(length: 32)
        
    }

    /// Removes the authorization information for the user.
    var logoutButton: some View {
        Button(action: {
            // Calling this method will also cause
            // `SpotifyAPI.authorizationManagerDidChange` to emit
            // a signal.
            spotify.api.authorizationManager.deauthorize()
            
            do {
                /*
                 Remove the authorization information from the keychain.
                 
                 If you don't do this, then the authorization information
                 that you just removed from memory by calling `deauthorize()`
                 will be retrieved again from persistent storage after this
                 app is quit and relaunched.
                 */
                try spotify.keychain.remove(KeychainKeys.authorizationManager)
                
            } catch {
                print(
                    "couldn't remove authorization manager " +
                    "from keychain: \(error)"
                )
            }
            
        }, label: {
            Text("Logout")
                .foregroundColor(.white)
                .padding(7)
                .background(Color(#colorLiteral(red: 0.3923448698, green: 0.7200681584, blue: 0.19703095, alpha: 1)))
                .cornerRadius(10)
                .shadow(radius: 3)
        
        })
    }
}

struct RootView_Previews: PreviewProvider {
    
    static let spotify: Spotify = {
        let spotify = Spotify()
        spotify.isAuthorized = true
        return spotify
    }()
    
    static var previews: some View {
        RootView()
            .environmentObject(spotify)
    }
}
