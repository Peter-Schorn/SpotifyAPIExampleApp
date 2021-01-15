import SwiftUI
import Combine
import SpotifyWebAPI

struct SavedAlbumsGridView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var savedAlbums: [Album] = []

    @State private var alert: AlertItem? = nil

    @State private var didRequestAlbums = false
    @State private var isLoadingAlbums = false
    @State private var couldntLoadAlbums = false
    
    @State private var loadAlbumsCancellable: AnyCancellable? = nil
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 200))
    ]

    init() { }
    
    /// Used only by the preview provider to provide sample data.
    fileprivate init(sampleAlbums: [Album]) {
        self._savedAlbums = State(initialValue: sampleAlbums)
    }
    
    var body: some View {
        Group {
            if savedAlbums.isEmpty {
                if isLoadingAlbums {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Loading Albums")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                else if couldntLoadAlbums {
                    Text("Couldn't Load Albums")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        // WARNING: do not use `\.self` for the id.
                        // This is extremely expensive and causes lag when
                        // scrolling because the hash of the entire album
                        // instance must be calculated.
                        ForEach(savedAlbums, id: \.id) { album in
                            AlbumGridItemView(album: album)
                        }
                    }
                    .padding()
                }
            }
            
        }
        .navigationTitle("Saved Albums")
        .navigationBarItems(trailing: refreshButton)
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onAppear {
            if !self.didRequestAlbums {
                self.retrieveSavedAlbums()
            }
        }
    }
    
    var refreshButton: some View {
        Button(action: retrieveSavedAlbums) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoadingAlbums)
        
    }
    
    func retrieveSavedAlbums() {

        // Don't try to load any albums if we're in preview mode.
        if ProcessInfo.processInfo.isPreviewing { return }
        
        self.didRequestAlbums = true
        self.isLoadingAlbums = true
        self.savedAlbums = []
        
        print("retrieveSavedAlbums")
        
        self.loadAlbumsCancellable = spotify.api
            .currentUserSavedAlbums()
            .extendPages(spotify.api)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingAlbums = false
                    switch completion {
                        case .finished:
                            self.couldntLoadAlbums = false
                        case .failure(let error):
                            self.couldntLoadAlbums = true
                            self.alert = AlertItem(
                                title: "Couldn't Retrieve Albums",
                                message: error.localizedDescription
                            )
                    }
                },
                receiveValue: { savedAlbums in
                    let albums = savedAlbums.items
                        .map(\.item)
                        /*
                         Remove albums that have `nil` for Id
                         so that this property can be used as the id for the
                         ForEach above. (The id must be unique, otherwise
                         the app will crash.) In practice, the id should
                         never be `nil` when the albums are retrieved using
                         the `currentUserSavedAlbums()` endpoint.
                         
                         Using \.self in the ForEach is extremely expensive as
                         this involves calculating the hash of the entire `Album`
                         instance, which is very large.
                         */
                        .filter { $0.id != nil }
                    
                    self.savedAlbums.append(contentsOf: albums)
                    
                }
            )
    }

}

struct SavedAlbumsView_Previews: PreviewProvider {
    
    static let spotify = Spotify()

    static let sampleAlbums: [Album] = [
        .jinx, .abbeyRoad, .darkSideOfTheMoon, .meddle, .inRainbows,
        .skiptracing
    ]
    
    static var previews: some View {
        
        NavigationView {
            SavedAlbumsGridView(sampleAlbums: sampleAlbums)
                .environmentObject(spotify)
        }
            
    }
    
}
