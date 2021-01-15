import SwiftUI
import Combine
import SpotifyWebAPI

struct TrackView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var playRequestCancellable: AnyCancellable? = nil

    @State private var alert: AlertItem? = nil
    
    let track: Track
    
    var body: some View {
        Button(action: playTrack) {
            HStack {
                Text(trackDisplayName())
                Spacer()
            }
            // Ensure the hitbox extends across the entire width
            // of the frame. See https://bit.ly/2HqNk4S
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
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
        
        let alertTitle = "Couldn't Play \(track.name)"

        guard let trackURI = track.uri else {
            self.alert = AlertItem(
                title: alertTitle,
                message: "missing URI"
            )
            return
        }
        
        
        // A request to play a single track.
        let playbackRequest = PlaybackRequest(trackURI)
        
        // By using a single cancellable rather than a collection
        // of cancellables, the previous request always gets
        // cancelled when a new request to play a track is
        // made.
        self.playRequestCancellable =
            self.spotify.api.getAvailableDeviceThenPlay(playbackRequest)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.alert = AlertItem(
                            title: alertTitle,
                            message: error.localizedDescription
                        )
                    }
                })
        
    }
}

struct TrackView_Previews: PreviewProvider {
    
    static let tracks: [Track] = [
        .because, .comeTogether, .faces,
        .illWind, .odeToViceroy, .reckoner,
        .theEnd, .time
    ]

    static var previews: some View {
        List(tracks, id: \.id) { track in
            TrackView(track: track)
        }
        .environmentObject(Spotify())
    }
}
