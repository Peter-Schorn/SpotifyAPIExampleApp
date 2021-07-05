import SwiftUI
import Combine
import SpotifyWebAPI

struct PlaylistCellView: View {
    
    @ObservedObject var spotify: Spotify

    @ObservedObject var playlistDeduplicator: PlaylistDeduplicator

    let playlist: Playlist<PlaylistItemsReference>

    /// The cover image for the playlist.
    @State private var image = Image(.spotifyAlbumPlaceholder)

    @State private var didRequestImage = false
    
    @State private var alert: AlertItem? = nil
    
    // MARK: Cancellables
    @State private var loadImageCancellable: AnyCancellable? = nil
    @State private var playPlaylistCancellable: AnyCancellable? = nil
    
    init(spotify: Spotify, playlist: Playlist<PlaylistItemsReference>) {
        self.spotify = spotify
        self.playlist = playlist
        self.playlistDeduplicator = PlaylistDeduplicator(
            spotify: spotify, playlist: playlist
        )
    }
    
    var body: some View {
        Button(action: playPlaylist) {
            HStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .padding(.trailing, 5)
                Text("\(playlist.name) - \(playlistDeduplicator.totalItems) items")
                if playlistDeduplicator.isDeduplicating {
                    ProgressView()
                        .padding(.leading, 5)
                }
                Spacer()
            }
            // Ensure the hit box extends across the entire width of the frame.
            // See https://bit.ly/2HqNk4S
            .contentShape(Rectangle())
            .contextMenu {
                // you can only remove duplicates from a playlist you own
                if let currentUserId = spotify.currentUser?.id,
                        playlist.owner?.id == currentUserId {
                    
                    Button("Remove Duplicates") {
                        playlistDeduplicator.findAndRemoveDuplicates()
                    }
                    .disabled(playlistDeduplicator.isDeduplicating)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onAppear(perform: loadImage)
        .onReceive(playlistDeduplicator.alertPublisher) { alert in
            self.alert = alert
        }
    }
    
    /// Loads the image for the playlist.
    func loadImage() {
        
        // Return early if the image has already been requested. We can't just
        // check if `self.image == nil` because the image might have already
        // been requested, but not loaded yet.
        if self.didRequestImage {
            // print("already requested image for '\(playlist.name)'")
            return
        }
        self.didRequestImage = true
        
        guard let spotifyImage = playlist.images.largest else {
            // print("no image found for '\(playlist.name)'")
            return
        }

        // print("loading image for '\(playlist.name)'")
        
        // Note that a `Set<AnyCancellable>` is NOT being used so that each time
        // a request to load the image is made, the previous cancellable
        // assigned to `loadImageCancellable` is deallocated, which cancels the
        // publisher.
        self.loadImageCancellable = spotifyImage.load()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { image in
                    // print("received image for '\(playlist.name)'")
                    self.image = image
                }
            )
    }
    
    func playPlaylist() {
        
        let playbackRequest = PlaybackRequest(
            context: .contextURI(playlist), offset: nil
        )
        self.playPlaylistCancellable = self.spotify.api
            .getAvailableDeviceThenPlay(playbackRequest)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.alert = AlertItem(
                        title: "Couldn't Play Playlist \(playlist.name)",
                        message: error.localizedDescription
                    )
                }
            })
        
    }
    
}

struct PlaylistCellView_Previews: PreviewProvider {

    static let spotify = Spotify()
    
    static var previews: some View {
        List {
            PlaylistCellView(spotify: spotify, playlist: .thisIsMildHighClub)
            PlaylistCellView(spotify: spotify, playlist: .thisIsRadiohead)
            PlaylistCellView(spotify: spotify, playlist: .modernPsychedelia)
            PlaylistCellView(spotify: spotify, playlist: .rockClassics)
            PlaylistCellView(spotify: spotify, playlist: .menITrust)
        }
        .environmentObject(spotify)
    }
    
}
