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
    
    @State private var alert: AlertItem? = nil
    
    var body: some View {
        NavigationView {
            ExamplesListView()
                .navigationBarTitle("Spotify Example App")
                .navigationBarItems(trailing: logoutButton)
                .disabled(!spotify.isAuthorized)
        }
        // The login view is presented if `Spotify.isAuthorized` == `false.
        // When the login button is tapped, `Spotify.authorize()` is called.
        // After the login process successfully completes, `Spotify.isAuthorized`
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
        .onReceive(spotify.sessionManagerDidFailWithError) { error in
            let message: String
            if let sptError = error as? SPTError {
                message = sptError.underlyingErrorLocalizedDescription
            }
            else {
                message = error.localizedDescription
            }
            self.alert = AlertItem(
                title: "Couldn't Authorize With Your Account",
                message: message
            )
            print("RootView received alertItem: \(message)")
        }
        
    }
    
    /**
     Handle the URL that Spotify redirects to after the user
     Either authorizes or denies authorization for the application.
     
     This method is called by the `onOpenURL(perform:)` view modifier
     directly above.
     */
    func handleURL(_ url: URL) {
        
        /*
         **Always** validate URLs; they offer a potential attack
         vector into your app.
         The `appRemoteCallbackURL` has the same scheme, so we could
         compare it against that as well.
         */
        guard url.scheme == self.spotify.appRemoteCallbackURL.scheme else {
            print("not handling URL: unexpected scheme: '\(url)'")
            self.alert = AlertItem(
                title: "Cannot Handle Redirect",
                message: "Unexpected URL"
            )
            return
        }
        
        print("received redirect: '\(url)'")

        self.spotify.sessionManager.application(
            UIApplication.shared,
            open: url
        )
        
    }
    
    /// Removes the authorization information for the user.
    var logoutButton: some View {
        // Calling `spotify.api.authorizationManager.deauthorize` will
        // cause `SpotifyAPI.authorizationManagerDidDeauthorize` to emit
        // a signal, which will cause
        // `Spotify.authorizationManagerDidDeauthorize()` to be called.
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
