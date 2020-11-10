import SwiftUI
import Combine
import SpotifyWebAPI

struct TrackView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var playRequestCancellable: AnyCancellable? = nil

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    let track: Track
    
    var body: some View {
        HStack {
            Text(trackDisplayName())
            Spacer()
        }
        .frame(maxWidth: .infinity)
        // Ensure the hitbox extends across the entire width
        // of the frame. See https://bit.ly/2HqNk4S
        .contentShape(Rectangle())
        .onTapGesture(perform: playTrack)
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
    }
    
    /// The display name for the track.
    /// E.g., "Eclipse - Pink Floyd".
    func trackDisplayName() -> String {
        var displayName = track.name
        if let artistName = track.artists?.first?.name {
            displayName += " - \(artistName)"
        }
        return displayName
    }
    
    func playTrack() {
        
        guard let trackURI = track.uri else {
            self.alertTitle = "Couldn't Play '\(track.name)'"
            self.alertMessage = "missing URI"
            self.alertIsPresented = true
            return
        }
        
        // A request to play a single track.
        let playbackRequest = PlaybackRequest(trackURI)
        
        // By using a single cancellable rather than a collection
        // of cancellables, the previous request always gets
        // cancelled when a new request to play a track is
        // made.
        // self.playRequestCancellable = self.spotify.api.play(playbackRequest)
        self.playRequestCancellable =
            self.spotify.api.getAvailableDeviceThenPlay(playbackRequest)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.alertTitle = "Couldn't Play '\(track.name)'"
                        self.alertMessage = error.localizedDescription
                        self.alertIsPresented = true
                    }
                })
        
    }
}

struct TrackView_Previews: PreviewProvider {
    static var previews: some View {
        TrackView(track: .because)
            .environmentObject(Spotify())
            .padding()
    }
}
