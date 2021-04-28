import SwiftUI
import SpotifyWebAPI

struct PlayURIView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var uri = ""
    
    @State private var alert: AlertItem? = nil

    var body: some View {
        Form {
            Text("Enter a URI")
            TextField("", text: $uri)
            Button("Play Content", action: playURI)
                .disabled(uri.isEmpty)
        }
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onReceive(spotify.appRemoteDidFailConnectionAttempt) { error in
            let errorMessage = error.map { $0.localizedDescription }
                    ?? "An unknown error occurred"
            self.alert = AlertItem(
                title: "Could not connect to the Spotify App",
                message: errorMessage
            )
        }

    }
    
    func playURI() {
        print("app remote is connected: \(self.spotify.appRemote.isConnected)")
        
        self.spotify.appRemote.authorizeIfNeededAndPlay(uri: uri)

    }
    
}

struct PlayerRemote_Previews: PreviewProvider {
    static var previews: some View {
        PlayURIView()
            .environmentObject(Spotify())
    }
}


