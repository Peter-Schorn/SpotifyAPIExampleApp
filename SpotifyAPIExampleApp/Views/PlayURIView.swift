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
        }
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }

    }
    
    func playURI() {
        
        if uri.isEmpty {
            self.alert = AlertItem(
                title: "Track URI must not be empty",
                message: ""
            )
            return
        }
        
        print("app remote is connected: \(self.spotify.appRemote.isConnected)")
        
        self.spotify.appRemote.authorizeIfNeededAndPlay(uri: uri)

//        if self.spotify.appRemote.isConnected {
//            print("app remote is already connected")
//
//            self.spotify.appRemote.playerAPI?.play(
//                trackURI
//            ) { result, error in
//                if let error = error {
//                    print("error playing '\(trackURI)':\n\(error)")
//                }
//            }
//
//        }
//        else {
//            if self.spotify.appRemote.authorizeAndPlayURI(trackURI) {
//                print("Spotify is installed")
//            }
//            else {
//                print("Spotify is not installed")
//            }
//        }
        
    }
    
}

struct PlayerRemote_Previews: PreviewProvider {
    static var previews: some View {
        PlayURIView()
            .environmentObject(Spotify())
    }
}


