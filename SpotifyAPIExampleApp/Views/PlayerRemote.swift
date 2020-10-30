import SwiftUI
import SpotifyWebAPI

struct PlayerRemote: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var trackURI = ""
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    var body: some View {
        Form {
            Text("Enter a track URI")
            TextField("", text: $trackURI)
            Button("Play Track", action: playTrack)
        }
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
    }
    
    func playTrack() {
        
        if trackURI.isEmpty {
            self.alertTitle = "Track URI must not be empty"
            self.alertIsPresented = true
            return
        }
        
        if spotify.appRemote.isConnected {
            
            self.spotify.appRemote.playerAPI?.pause { _, error in
                if let error = error {
                    print("couldn't pause:", error)
                }
                else {
                    print("successfully paused?")
                }
            }
        }
        
        print("playing track")
        
        if self.spotify.appRemote.authorizeAndPlayURI(trackURI) {
            print("Spotify is installed")
        }
        else {
            print("Spotify is not installed")
        }
        
        if let delegate = self.spotify.appRemote.delegate {
            print("delegate: \(delegate)")
        }
        else {
            print("no delegate")
        }
        
        if let delegate = self.spotify.appRemote.playerAPI?.delegate {
            print("player delegate: '\(delegate)'")
        }
        
    }
    
}

struct PlayerRemote_Previews: PreviewProvider {
    static var previews: some View {
        PlayerRemote()
            .environmentObject(Spotify())
    }
}
