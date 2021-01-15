import Foundation
import Combine
import SwiftUI

struct PlayerControlsView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var alert: AlertItem? = nil
    
    @State private var playerState: SPTAppRemotePlayerState? = nil
    @State private var previousAlbumURI: String? = nil
    @State private var albumImage = Image(.spotifyAlbumPlaceholder)

    var isPaused: Bool {
        self.playerState?.isPaused ?? true
    }
    
    var playerAPI: SPTAppRemotePlayerAPI? {
        if let playerAPI = self.spotify.appRemote.playerAPI {
            return playerAPI
        }
        print("\nWARNING: PlayerControlsView: playerAPI is nil\n")
        return nil
    }

    var body: some View {
        VStack {
            
            albumImage
            
            VStack(spacing: 10) {
                Text(playerState?.track.name ?? "track")
                Text(playerState?.track.artist.name ?? "artist")
            }
            .frame(height: 50)
            .padding(.vertical, 5)
            .padding(.horizontal, 15)
            
            HStack(spacing: 30) {
                Button(action: skipToPreviousTrack, label: {
                    Image(systemName: "backward.fill")
                })
                Button(action: playPause, label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                })
                Button(action: skipToNextTrack, label: {
                    Image(systemName: "forward.fill")
                })
            }
            .buttonStyle(PlainButtonStyle())
            .font(.largeTitle)
            .padding()

            Text(
                verbatim: "App Remote is connected: " +
                           "\(self.spotify.appRemoteIsConnected)"
            )
            .padding(5)
            
        }
        .navigationBarTitle("", displayMode: .inline)
        .modifier(ConnectToSpotifyModal(action: authorizeAndPlay))
        .onAppear {
            if self.spotify.appRemote.isConnected {
                self.getPlayerState()
            }
        }
        .onReceive(spotify.playerStateDidChange) { playerState in
            print(
                "received playerStateDidChange: " +
                "\(playerState.track.name)"
            )
            self.playerState = playerState
            self.loadAlbumImageIfNedded()
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
    
    func getPlayerState() {
        print("will get player state")
        self.playerAPI?.getPlayerState { result, error in
            if let error = error {
                print("couldn't get player state: \(error)")
            }
            else {
                let playerState = result as! SPTAppRemotePlayerState
                print("got player state: \(playerState)")
                self.playerState = playerState
                self.loadAlbumImageIfNedded()
            }
            
        }
    }
    
    func loadAlbumImageIfNedded() {
        guard let track = self.playerState?.track else {
            return
        }
        let albumURI = track.album.uri
        if albumURI == self.previousAlbumURI {
            print("album URI is the same")
            return
        }
        self.previousAlbumURI = albumURI
        self.spotify.appRemote.imageAPI?.fetchImage(
            forItem: track,
            with: CGSize(width: 300, height: 300)
        ) { image, error in
            
            if let error = error {
                print("couldn't fetch image: \(error)")
                self.albumImage = Image(.spotifyAlbumPlaceholder)
                self.previousAlbumURI = nil
            }
            else {
                let image = image as! UIImage
                self.albumImage = Image(uiImage: image)
            }

        }
    }

    func playPause() {
        
        if self.isPaused {
            self.playerAPI?.resume(nil)
        }
        else {
            self.playerAPI?.pause(nil)
        }
        
    }

    func skipToPreviousTrack() {
        self.playerAPI?.skip(toPrevious: nil)
    }

    func skipToNextTrack() {
        self.playerAPI?.skip(toNext: nil)
    }

    func authorizeAndPlay() {
        self.spotify.appRemote.authorizeAndPlayURI("")
    }

}

struct PlayerControlsView_Previews: PreviewProvider {
    
    static let spotify = Spotify()

    static var previews: some View {
        NavigationView {
            PlayerControlsView()
                .environmentObject(spotify)
                .onAppear(perform: onAppear)
        }
    }
    
    static func onAppear() {
        spotify.appRemoteIsConnected = true
    }

}
