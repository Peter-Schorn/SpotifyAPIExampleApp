import SwiftUI
import Combine
import SpotifyWebAPI

struct PlaylistCellView: View {
    
    @EnvironmentObject var spotify: Spotify

    /// The cover image for the playlist.
    @State private var image = Image(.spotifyAlbumPlaceholder)

    /// The total number of items in the playlist.
    @State private var totalItems: Int
    
    @State private var didRequestImage = false
    @State private var isDeduplicating = false

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    // MARK: Cancellables
    @State private var loadImageCancellable: AnyCancellable? = nil
    @State private var playPlaylistCancellable: AnyCancellable? = nil
    @State private var cancellables: Set<AnyCancellable> = []
    
    var playlist: Playlist<PlaylistsItemsReference>
    
    init(_ playlist: Playlist<PlaylistsItemsReference>) {
        self.playlist = playlist
        self._totalItems = State(initialValue: playlist.items.total)
    }
    
    var body: some View {
        Button(action: playPlaylist, label: {
            HStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .padding(.trailing, 5)
                Text("\(playlist.name) - \(totalItems) items")
                if isDeduplicating {
                    ProgressView()
                        .padding(.leading, 5)
                }
                Spacer()
            }
            // Ensure the hitbox extends across the entire width
            // of the frame. See https://bit.ly/2HqNk4S
            .contentShape(Rectangle())
            .contextMenu {
                Button("Remove Duplicates", action: findDuplicates)
                    .disabled(isDeduplicating)
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
            // print("already requested image for '\(playlist.name)'")
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
        self.playPlaylistCancellable =
            self.spotify.api.getAvailableDeviceThenPlay(playbackRequest)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.alertTitle = "Couldn't Play Playlist \(playlist.name)"
                        self.alertMessage = error.localizedDescription
                        self.alertIsPresented = true
                    }
                })
            
    }
    
    /// Find the duplicates in the playlist.
    func findDuplicates() {
        
        self.isDeduplicating = true
        
        var seenPlaylists: Set<PlaylistItem> = []
        
        // The uri of an item in the playlist, along with its position in
        // the playlist.
        var duplicates: [(uri: SpotifyURIConvertible, position: Int)] = []
        
        spotify.api.playlistItems(playlist.uri)
            .extendPages(spotify.api)
            .sink(
                receiveCompletion: { completion in
                    print("received compltion:", completion)
                    switch completion {
                        case .finished:
                            // We've finished finding the duplicates;
                            // now we need to remove them if there are any.
                            if duplicates.isEmpty {
                                DispatchQueue.main.async {
                                    self.isDeduplicating = false
                                    self.alertTitle =
                                        "\(playlist.name) does not have any duplicates"
                                    self.alertIsPresented = true
                                }
                                return
                            }
                            DispatchQueue.global().async {
                                self.removeDuplicates(duplicates)
                            }
                        case .failure(let error):
                            print("couldn't check for duplicates:\n\(error)")
                            DispatchQueue.main.async {
                                self.isDeduplicating = false
                                self.alertTitle =
                                "Couldn't check for duplicates for \(playlist.name)"
                                self.alertMessage = error.localizedDescription
                                self.alertIsPresented = true
                            }
                    }
                },
                receiveValue: { playlistItemsPage in
                    print("received page at offset \(playlistItemsPage.offset)")
                    
                    let playlistItems = playlistItemsPage.items
                        .map(\.item)
                        .enumerated()
                    
                    for (index, playlistItem) in playlistItems {
                        
                        guard let playlistItem = playlistItem else {
                            continue
                        }
                        
                        // skip local tracks
                        if case .track(let track) = playlistItem {
                            if track.isLocal { continue }
                        }
                        
                        for seenPlaylist in seenPlaylists {
                            guard let uri = playlistItem.uri else {
                                continue
                            }
                            
                            if playlistItem.isProbablyTheSameAs(seenPlaylist) {
                                // To determine the actual index of the item in the
                                // playlist, we must take into account the offset of
                                // the current page
                                let playlistIndex = index + playlistItemsPage.offset
                                duplicates.append(
                                    (uri: uri, position: playlistIndex)
                                )
                            }
                        }
                        seenPlaylists.insert(playlistItem)

                    }
                    

                }
            )
            .store(in: &cancellables)
                
    }
    
    /// Remove the duplicates in the playlist.
    func removeDuplicates(
        _ duplicates: [(uri: SpotifyURIConvertible, position: Int)]
    ) {
        
        print("will remove \(duplicates.count) duplicates for \(playlist.name)")
        
        let urisWithPositionsContainers = URIsWithPositionsContainer.chunked(
            urisWithSinglePosition: duplicates
        )
        
        let sempahore = DispatchSemaphore(value: 0)
        for (index, container) in urisWithPositionsContainers.enumerated() {
            spotify.api.removeSpecificOccurencesFromPlaylist(
                playlist.uri, of: container
            )
            .sink(
                receiveCompletion: { completion in
                    print("completion for request \(index): \(completion)")
                    switch completion {
                        case .finished:
                            sempahore.signal()
                        case .failure(let error):
                            print(
                                "\(index): couldn't remove duplicates\n\(error)"
                            )
                            DispatchQueue.main.async {
                                self.alertTitle =
                                    "Couldn't Remove Duplicates from \(playlist.name)"
                                self.alertMessage = error.localizedDescription
                                self.alertIsPresented = true
                            }
                            // Do not try to remove any more duplicates
                            // from the playlist if we get an error because
                            // the indices of the items may be invalid.
                            break
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
            
            sempahore.wait()
            
        }
        print("finished removing duplicates from playlist")
        DispatchQueue.main.async {
            self.isDeduplicating = false
            self.totalItems = playlist.items.total - duplicates.count
            self.alertTitle =
                "Removed \(duplicates.count) duplicates from \(playlist.name)"
            self.alertIsPresented = true
        }

    }
    
}

struct PlaylistCellView_Previews: PreviewProvider {

    static let spotify = Spotify()
    
    static var previews: some View {
        List {
            PlaylistCellView(.thisIsMildHighClub)
            PlaylistCellView(.thisIsRadiohead)
            PlaylistCellView(.modernPsychedelia)
            PlaylistCellView(.rockClassics)
            PlaylistCellView(.menITrust)
        }
        .environmentObject(spotify)
    }
}
