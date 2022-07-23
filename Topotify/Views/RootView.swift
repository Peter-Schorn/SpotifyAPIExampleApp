import SwiftUI
import Combine
import SpotifyWebAPI

struct RootView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var alert: AlertItem? = nil

    @State private var cancellables: Set<AnyCancellable> = []
    
    var body: some View {
        TabView {
            TopSongsView()
                .tabItem {
                    Image("music-note")
                    Text("Top Songs")
                }
            
            TopArtistsView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Top Artists")
                }
            
            RecentlyPlayedView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Recently Played")
                }
        }
        .modifier(LoginView())
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onOpenURL(perform: handleURL(_:))
    }
    func handleURL(_ url: URL) {
        guard url.scheme == self.spotify.loginCallbackURL.scheme else {
            self.alert = AlertItem(
                title: "Cannot Handle Redirect",
                message: "Unexpected URL"
            )
            return
        }
        
        
        spotify.isRetrievingTokens = true
        
        spotify.api.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: url,
            state: spotify.authorizationState
        )
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
            
            self.spotify.isRetrievingTokens = false
            
            if case .failure(let error) = completion {
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
        .store(in: &cancellables)
        
        self.spotify.authorizationState = String.randomURLSafe(length: 128)
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
