import SwiftUI
import Combine
import SpotifyWebAPI

struct PlaylistCellView: View {
    
    @EnvironmentObject var spotify: Spotify

    /// The cover image for the playlist.
    @State private var image = Image(.spotifyAlbumPlaceholder)

    @State private var loadImageCancellable: AnyCancellable? = nil
    @State private var didRequestImage = false

    @State private var playPlaylistCancellable: AnyCancellable? = nil
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    var playlist: Playlist<PlaylistsItemsReference>
    
    init(_ playlist: Playlist<PlaylistsItemsReference>) {
        self.playlist = playlist
        // print("PlaylistCellView init for '\(playlist.name)'")
    }
    
    var body: some View {
        Button(action: playPlaylist, label: {
            HStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                Text("\(playlist.name) - \(playlist.items.total) items")
                Spacer()
            }
        })
        .buttonStyle(PlainButtonStyle())
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
        .onAppear(perform: loadImage)
    }
    
    /// Loads the image for the playlist.
    func loadImage() {
        
        // Return early if the image has already been requested.
        // We can't just check if `self.image == nil` because the image
        // might have already been requested, but not loaded yet.
        if self.didRequestImage {
            // print("didRequestImage image for '\(playlist.name)'")
            return
        }
        self.didRequestImage = true
        
        guard let spotifyImage = playlist.images.largest else {
            // print("no image found for '\(playlist.name)'")
            return
        }

        // print("loading image for '\(playlist.name)'")
        
        // Note that a `Set<AnyCancellable>` is NOT being used
        // so that each time a request to load the image is made,
        // the previous cancellable assigned to `loadImageCancellable`
        // is deallocated, which cancels the publisher.
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
    
    /// Plays the playlist on the user's active device.
    func playPlaylist() {
        let playbackRequest = PlaybackRequest(
            context: .contextURI(playlist), offset: nil
        )
        self.playPlaylistCancellable = self.spotify.api.play(playbackRequest)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.alertTitle = "Couldn't Play Playlist '\(playlist.name)'"
                    self.alertMessage = error.localizedDescription
                    self.alertIsPresented = true
                }
            })
            
    }
    
}

struct PlaylistCellView_Previews: PreviewProvider {

    static let spotify = Spotify()
    static let playlist = Playlist.rockClassics
    
    static var previews: some View {
        PlaylistCellView(playlist)
    }
}
