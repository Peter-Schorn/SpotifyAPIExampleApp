import SwiftUI
import Combine
import SpotifyWebAPI

struct PlaylistsListView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var playlists: [Playlist<PlaylistItemsReference>] = []
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State private var isLoadingPlaylists = false
    @State private var couldntLoadPlaylists = false
    
    @State private var alert: AlertItem? = nil

    init() { }
    
    /// Used only by the preview provider to provide sample data.
    fileprivate init(samplePlaylists: [Playlist<PlaylistItemsReference>]) {
        self._playlists = State(initialValue: samplePlaylists)
    }
    
    var body: some View {
        VStack {
            if playlists.isEmpty {
                if isLoadingPlaylists {
                    HStack {
                        ProgressView()
                            .padding()
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
                else {
                    Text("No Playlists Found")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                Text(
                    """
                    Tap on a playlist to play it. Tap and hold on a Playlist \
                    to remove duplicates.
                    """
                )
                .font(.caption)
                .foregroundColor(.secondary)
                List {
                    ForEach(playlists, id: \.uri) { playlist in
                        PlaylistCellView(spotify: spotify, playlist: playlist)
                    }
                }
                .refreshable(action: retrievePlaylists)
                .listStyle(PlainListStyle())
                .accessibility(identifier: "Playlists List View")
            }
        }
        .navigationTitle("Playlists")
        .modify { view in
            if #available(iOS 15, *) {
                view
            } else {
                view.navigationBarItems(trailing: refreshButton)
            }
        
        }
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .task(retrievePlaylists)
        
    }
    
    var refreshButton: some View {
        Button(action: {
            Task {
                await self.retrievePlaylists()
            }
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoadingPlaylists)
        
    }
    
    func retrievePlaylists() async {
        
        // Don't try to load any playlists if we're in preview mode.
        if ProcessInfo.processInfo.isPreviewing { return }
        
        self.isLoadingPlaylists = true

        do {
//            let playlists = try await spotify.api
//                .currentUserPlaylists(limit: 50)
//                .extendPages(spotify.api)
//                .receive(on: RunLoop.main)
//                .reduce([], { playlists, playlistsPage in
//                    return playlists + playlistsPage.items
//                })
//                .awaitSingleValue() ?? []
//
//
//            self.couldntLoadPlaylists = false
//            self.playlists = playlists
            
            let publisher = spotify.api
                .currentUserPlaylists(limit: 50)
                .extendPages(spotify.api)
                .map(\.items)
            
            for try await playlists in publisher.awaitValues() {
                
            }
            

        } catch {
            self.couldntLoadPlaylists = true
            self.alert = AlertItem(
                title: "Couldn't Retrieve Playlists",
                message: error.localizedDescription
            )
        }
        
        self.isLoadingPlaylists = false
            
    }
    
    func retrievePlaylistsOld() async {
        
        // Don't try to load any playlists if we're in preview mode.
        if ProcessInfo.processInfo.isPreviewing { return }
        
        return await withCheckedContinuation { continuation in
            
            self.isLoadingPlaylists = true
            spotify.api.currentUserPlaylists(limit: 50)
                // Gets all pages of playlists.
                .extendPages(spotify.api)
                .reduce([]) { playlists, playlistsPage in
                    return playlists + playlistsPage.items
                }
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { completion in
                        self.isLoadingPlaylists = false
                        switch completion {
                            case .finished:
                                self.couldntLoadPlaylists = false
                            case .failure(let error):
                                self.couldntLoadPlaylists = true
                                self.alert = AlertItem(
                                    title: "Couldn't Retrieve Playlists",
                                    message: error.localizedDescription
                                )
                        }
                        continuation.resume()
                    },
                    // We will receive a value for each page of playlists. You
                    // could use Combine's `collect()` operator to wait until
                    // all of the pages have been retrieved.
                    receiveValue: { playlists in
                        self.playlists = playlists
                    }
                )
                .store(in: &cancellables)
            
        }  // withCheckedContinuation

    }
    
    
}

struct PlaylistsListView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    
    static let playlists: [Playlist<PlaylistItemsReference>] = [
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
