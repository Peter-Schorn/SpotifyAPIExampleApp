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
        
        self.spotify.requestAccessAndRefreshTokens(url: url)
            .sink(receiveCompletion: { completion in
                /*
                 After the access and refresh tokens are retrieved,
                 `SpotifyAPI.authorizationManagerDidChange` will emit a
                 signal, causing `Spotify.handleChangesToAuthorizationManager()`
                 to be called, which will dismiss the loginView if the app was
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
                        alertTitle = "You Denied The Authorization Request :("
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
            .store(in: &self.cancellables)
        
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
