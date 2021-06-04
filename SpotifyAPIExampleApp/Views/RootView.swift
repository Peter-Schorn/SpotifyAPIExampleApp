import SwiftUI
import Combine
import SpotifyWebAPI

struct RootView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var alert: AlertItem? = nil
    
    @State private var cancellables: Set<AnyCancellable> = []

    var body: some View {
        NavigationView {
            ExamplesListView()
                .navigationBarTitle("Spotify Example App")
                .disabled(!spotify.isAuthorized)
                .navigationBarItems(trailing: accountsButton)
                .sheet(
                    isPresented: $spotify.accountsListViewIsPresented
                ) {
                    SpotifyAccountsListView()
                        .environmentObject(spotify)
                }
                // Presented if an error occurs during the process of
                // authorizing with the user's Spotify account.
                .alert(item: $alert) { alert in
                    Alert(title: alert.title, message: alert.message)
                }
                .onOpenURL(perform: handleURL(_:))
        }

    }
    
    /**
     Handle the URL that Spotify redirects to after the user Either authorizes
     or denies authorization for the application.

     This method is called by the `onOpenURL(perform:)` view modifier directly
     above.
     */
    func handleURL(_ url: URL) {
        
        self.spotify.requestAccessAndRefreshTokens(
            redirectURIWithQuery: url
        )
        .sink(receiveCompletion: { completion in
            
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
    
    var accountsButton: some View {
        Button(action: {
            self.spotify.accountsListViewIsPresented = true
        }, label: {
            Text("Accounts")
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
