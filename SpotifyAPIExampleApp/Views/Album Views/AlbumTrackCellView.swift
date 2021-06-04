import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent

struct AlbumTrackCellView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var playTrackCancellable: AnyCancellable? = nil

    let index: Int
    let track: Track
    let album: Album
    
    @Binding var alert: AlertItem?

    var body: some View {
        Button(action: playTrack, label: {
            Text("\(index + 1). \(track.name)")
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .contentShape(Rectangle())
        })
        .buttonStyle(PlainButtonStyle())
    }
    
    func playTrack() {
        
        let alertTitle = "Couldn't play \(track.name)"

        guard let trackURI = track.uri else {
            self.alert = AlertItem(
                title: alertTitle,
                message: "Missing data"
            )
            return
        }
        
        let playbackRequest: PlaybackRequest
        
        if let albumURI = self.album.uri {
            // Play the track in the context of its album. Always prefer
            // providing a context; otherwise, the back and forwards buttons may
            // not work.
            playbackRequest = PlaybackRequest(
                context: .contextURI(albumURI),
                offset: .uri(trackURI)
            )
        }
        else {
            playbackRequest = PlaybackRequest(trackURI)
        }

        self.playTrackCancellable = self.spotify.api
            .getAvailableDeviceThenPlay(playbackRequest)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.alert = AlertItem(
                        title: alertTitle,
                        message: error.localizedDescription
                    )
                    print("\(alertTitle): \(error)")
                }
            })
        
    }

}

struct AlbumTrackCellView_Previews: PreviewProvider {

    static let album = Album.abbeyRoad
    static let tracks = Album.abbeyRoad.tracks!.items

    static var previews: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(tracks.enumerated()), id: \.offset) { track in
                    AlbumTrackCellView(
                        index: track.offset,
                        track: track.element,
                        album: album,
                        alert: .constant(nil)
                    )
                    Divider()
                }
            }
        }
    }
}
