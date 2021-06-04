import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent

struct AlbumTracksView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var alert: AlertItem? = nil
    
    @State private var loadTracksCancellable: AnyCancellable? = nil
    @State private var playAlbumCancellable: AnyCancellable? = nil
    
    @State private var isLoadingTracks = false
    @State private var couldntLoadTracks = false
    
    @State var allTracks: [Track] = []

    let album: Album
    let image: Image
    
    init(album: Album, image: Image) {
        self.album = album
        self.image = image
    }
    
    /// Used by the preview provider to provide sample data.
    fileprivate init(album: Album, image: Image, tracks: [Track]) {
        self.album = album
        self.image = image
        self._allTracks = State(initialValue: tracks)
    }

    /// The album and artist name; e.g., "Abbey Road - The Beatles".
    var albumAndArtistName: String {
        var title = album.name
        if let artistName = album.artists?.first?.name {
            title += " - \(artistName)"
        }
        return title
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                albumImageWithPlayButton
                    .padding(30)
                Text(albumAndArtistName)
                    .font(.title)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top, -10)
                Text("\(album.tracks?.total ?? 0) Tracks")
                    .foregroundColor(.secondary)
                    .font(.title2)
                    .padding(.vertical, 10)
                if allTracks.isEmpty {
                    Group {
                        if isLoadingTracks {
                            HStack {
                                ProgressView()
                                    .padding()
                                Text("Loading Tracks")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                            }
                        }
                        else if couldntLoadTracks {
                            Text("Couldn't Load Tracks")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                }
                else {
                    ForEach(
                        Array(allTracks.enumerated()),
                        id: \.offset
                    ) { track in
                        AlbumTrackCellView(
                            index: track.offset,
                            track: track.element,
                            album: album,
                            alert: $alert
                        )
                        Divider()
                    }
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onAppear(perform: loadTracks)
    }
    
    var albumImageWithPlayButton: some View {
        ZStack {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(20)
                .shadow(radius: 20)
            Button(action: playAlbum, label: {
                Image(systemName: "play.circle")
                    .resizable()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
                    .frame(width: 100, height: 100)
            })
        }
    }
    
    /// Loads the album tracks.
    func loadTracks() {
        
        // Don't try to load any tracks if we're in preview mode
        if ProcessInfo.processInfo.isPreviewing { return }

        guard let tracks = self.album.tracks else {
            return
        }

        // the `album` already contains the first page of tracks, but we need to
        // load additional pages if they exist. the `extendPages` method
        // immediately republishes the page that was passed in and then requests
        // additional pages.
        
        self.isLoadingTracks = true
        self.allTracks = []
        self.loadTracksCancellable = self.spotify.api.extendPages(tracks)
            .map(\.items)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingTracks = false
                    switch completion {
                        case .finished:
                            self.couldntLoadTracks = false
                        case .failure(let error):
                            self.couldntLoadTracks = true
                            self.alert = AlertItem(
                                title: "Couldn't Load Tracks",
                                message: error.localizedDescription
                            )
                    }
                },
                receiveValue: { tracks in
                    self.allTracks.append(contentsOf: tracks)
                }
            )
        
    }
    
    func playAlbum() {
        guard let albumURI = album.uri else {
            print("missing album uri for '\(album.name)'")
            return
        }
        let playbackRequest = PlaybackRequest(
            context: .contextURI(albumURI), offset: nil
        )
        print("playing album '\(album.name)'")
        self.playAlbumCancellable = spotify.api
            .getAvailableDeviceThenPlay(playbackRequest)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                print("Received play album completion")
                if case .failure(let error) = completion {
                    self.alert = AlertItem(
                        title: "Couldn't Play Album",
                        message: error.localizedDescription
                    )
                }
            })
    }
    
}

struct AlbumTracksView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    static let album = Album.darkSideOfTheMoon
    static let tracks: [Track] = album.tracks!.items
    
    static var previews: some View {
        NavigationView {
            AlbumTracksView(
                album: album,
                image: Image(.spotifyAlbumPlaceholder),
                tracks: tracks
            )
            .environmentObject(spotify)
        }
    }
}
