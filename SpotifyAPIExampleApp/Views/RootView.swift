//
//  RootView.swift
//  SpotifyAPIExampleApp
//
//  Created by Peter Schorn on 9/19/20.
//

import SwiftUI
import Combine
@testable import SpotifyWebAPI

struct RootView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State private var alert: AlertItem? = nil

    var body: some View {
        NavigationView {
            ExamplesListView()
                .navigationBarItems(trailing: logoutButton)
                .disabled(!spotify.isAuthorized)
        }
        // The login view is presented if `Spotify.isAuthorized` == `false.
        // When the login button is tapped, `Spotify.authorize()` is called.
        // After the login process sucessfully completes, `Spotify.isAuthorized`
        // will be set to `true` and `LoginView` will be dismissed, allowing
        // the user to interact with the rest of the app.
        .modifier(LoginView())
        // Presented if an error occurs during the process of authorizing
        // with the user's Spotify account.
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        // Called when a redirect is received from Spotify.
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

        print("received redirect from Spotify: '\(url)'")
        
//        guard let parameters = spotify.appRemote
//                .authorizationParameters(from: url) else {
//            self.alert = AlertItem(
//                title: "Couldn't get parameters from redirect URL",
//                message: ""
//            )
//            return
//        }
//
//        if let accessToken = parameters[SPTAppRemoteAccessTokenKey] {
//            self.spotify.api.authorizationManager._accessToken = accessToken
//            // self.spotify.appRemote.del
//            print("authorization process with Spotify succeeded")
//
//        }
//        else {
//            let errorMessage = parameters[SPTAppRemoteErrorDescriptionKey]
//                    ?? "An unknown error occurred"
//            self.alert = AlertItem(
//                title: "Couldn't authenticate with the Spotify App",
//                message: errorMessage
//            )
//
//        }
        
//         This property is used to display an activity indicator in
//         `LoginView` indicating that the access and refresh tokens
//         are being retrieved.
         spotify.isRetrievingTokens = true
        
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
            self.spotify.isRetrievingTokens = false
            
            /*
             After the access and refresh tokens are retrieved,
             `SpotifyAPI.authorizationManagerDidChange` will emit a
             signal, causing `handleChangesToAuthorizationManager()` to be
             called, which will dismiss the loginView if the app was
             successfully authorized by setting the
             @Published `Spotify.isAuthorized` property to `true`.
             
             The only thing we need to do here is handle the error and
             show it to the user if one was received.
             */
            if case .failure(let error) = completion {
                print("couldn't retrieve access and refresh tokens:\n\(error)")
                let alertTitle: String
                let alertMessage: String
                if let authError = error as? SpotifyAuthorizationError,
                   authError.accessWasDenied {
                    alertTitle =
                        "You Denied The Authorization Request :("
                    alertMessage = ""
                }
                else {
                    alertTitle =
                        "Couldn't Authorization With Your Account"
                    alertMessage = error.localizedDescription
                }
                self.alert = AlertItem(
                    title: alertTitle, message: alertMessage
                )
            }
         })
         .store(in: &cancellables)
        
         // MARK: IMPORTANT: generate a new value for the state parameter
         // MARK: after each authorization request. This ensures an incoming
         // MARK: redirect from Spotify was the result of a request made by
         // MARK: this app, and not an attacker.
         self.spotify.authorizationState = String.randomURLSafe(length: 128)
        
    }

    /// Removes the authorization information for the user.
    var logoutButton: some View {
        // Calling `spotify.api.authorizationManager.deauthorize` will
        // cause `SpotifyAPI.authorizationManagerDidDeauthorize` to emit
        // a signal, which will cause
        // `Spotify.removeAuthorizationManagerFromKeychain` to be called.
        Button(action: spotify.api.authorizationManager.deauthorize, label: {
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
