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
        .modifier(LoginView(isRetrievingTokens: $isRetrievingTokens))
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
        .onOpenURL(perform: handleURL(_:))
        
    }
    
    var logoutButton: some View {
        Button(action: {
            // calling this method will also cause
            // `SpotifyAPI.authorizationManagerDidChange` to emit
            // a signal.
            spotify.api.authorizationManager.deauthorize()
        }, label: {
            Text("Logout")
                .foregroundColor(.white)
                .padding(7)
                .background(Color(#colorLiteral(red: 0.3923448698, green: 0.7200681584, blue: 0.19703095, alpha: 1)))
                .cornerRadius(10)
                .shadow(radius: 3)
        
        })
    }

    /// Handle the URL that Spotify redirects to after the user
    /// Either authorizes or denies authorizaion for your application.
    func handleURL(_ url: URL) {
        
        // **Always** validate URLs; they offer a potential attack
        // vector into your app.
        guard url.scheme == Spotify.loginCallbackURL.scheme else {
            print("Not opening URL: unexpected scheme:", url.scheme ?? "nil")
            return
        }

        // This property is used to display an activity indicator in
        // `LoginView` indicating that the access and refresh tokens
        // are being retrieved.
        self.isRetrievingTokens = true
        
        spotify.api.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: url,
            state: Spotify.authorizationState
        )
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
            // whether the request succeeded or not, we need to remove
            // the activity indicator.
            self.isRetrievingTokens = false
            
            /*
             After the access and refresh tokens are retrieved,
             `SpotifyAPI.authorizationManagerDidChange` will emit a
             signal, causing `handleChangesToAuthorizationManager` to be
             called, which will dismiss the loginView if the app was
             successfully authorized by setting `spotify.isAuthorized` to
             `true`.

             The only thing we need to do here is handle the error and
             show it to the user.
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
        
    }

}

struct RootView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    
    static var previews: some View {
        RootView()
            .environmentObject(spotify)
    }
}
