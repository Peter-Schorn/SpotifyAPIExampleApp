import SwiftUI
import Combine
import SpotifyWebAPI

struct PlaylistsListView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var playlists: [Playlist<PlaylistsItemsReference>] = []
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    @State private var isLoadingPlaylists = false
    @State private var couldntLoadPlaylists = false
    
    let debug: Bool
    
    init() {
        self.debug = false
    }
    
    /// Used only by the preview provider to provide sample data.
    fileprivate init(samplePlaylists: [Playlist<PlaylistsItemsReference>]) {
        self._playlists = State(initialValue: samplePlaylists)
        self.debug = true
    }
    
    var body: some View {
        VStack {
            if playlists.isEmpty {
                if isLoadingPlaylists {
                    HStack {
                        ActivityIndicator(
                            isAnimating: .constant(true),
                            style: .medium
                        )
                        Text("Loading Playlists")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                else if couldntLoadPlaylists {
                    Text("Couldn't Load Playlists")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                Text("Tap on a Playlist to Play it")
                    .font(.caption)
                    .foregroundColor(.secondary)
                List {
                    ForEach(playlists, id: \.uri) { playlist in
                        PlaylistCellView(playlist)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Playlists")
        .navigationBarItems(trailing: refreshButton)
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
        .onAppear(perform: retrievePlaylists)
        
    }
    
    var refreshButton: some View {
        Button(action: retrievePlaylists) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoadingPlaylists)
        
    }
    
    func retrievePlaylists() {
        
        // If `debug` is `true`, then sample albums have been provided
        // for testing purposes, so we shouldn't try to retrieve any from
        // the Spotify web API.
        if self.debug { return }
        
        self.isLoadingPlaylists = true
        self.playlists = []
        spotify.api.currentUserPlaylists()
            // gets all pages of playlists. By default, only 20 are
            // returned per page.
            .extendPages(spotify.api)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingPlaylists = false
                    switch completion {
                        case .finished:
                            self.couldntLoadPlaylists = false
                        case .failure(let error):
                            self.couldntLoadPlaylists = true
                            self.alertTitle = "Couldn't Retrieve Playlists"
                            self.alertMessage = error.localizedDescription
                            self.alertIsPresented = true
                    }
                },
                // We will receive a value for each page of playlists.
                // You could use Combine's `collect()` operator to wait until
                // all of the pages have been retrieved.
                receiveValue: { playlistsPage in
                    let playlists = playlistsPage.items
                    self.playlists.append(contentsOf: playlists)
                }
            )
            .store(in: &cancellables)

    }
    
    
}

struct PlaylistsListView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    
    static let playlists: [Playlist<PlaylistsItemsReference>] = [
        .menITrust, .modernPsychedelia, .menITrust,
        .lucyInTheSkyWithDiamonds, .rockClassics,
        .thisIsMFDoom, .thisIsSonicYouth, .thisIsMildHighClub,
        .thisIsSkinshape
    ]
    
    static var previews: some View {
        NavigationView {
            PlaylistsListView(samplePlaylists: playlists)
                .environmentObject(spotify)
        }
    }
}
