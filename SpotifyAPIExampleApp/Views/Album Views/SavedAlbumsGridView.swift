import SwiftUI
import Combine
import SpotifyWebAPI

struct SavedAlbumsGridView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var savedAlbums: [Album] = []
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    @State private var didRequestAlbums = false
    @State private var isLoadingAlbums = false
    @State private var couldntLoadAlbums = false
    
    @State private var loadAlbumsCancellable: AnyCancellable? = nil
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 200))
    ]

    let debug: Bool
    
    init() {
        self.debug = false
    }
    
    /// Used only by the preview provider to provide sample data.
    fileprivate init(sampleAlbums: [Album]) {
        self._savedAlbums = State(initialValue: sampleAlbums)
        self.debug = true
    }
    
    var body: some View {
        Group {
            if savedAlbums.isEmpty {
                if isLoadingAlbums {
                    HStack {
                        ActivityIndicator(
                            isAnimating: .constant(true),
                            style: .medium
                        )
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
                            SavedAlbumView(album: album)
                        }
                    }
                    .padding()
                }
            }
            
        }
        .navigationTitle("Saved Albums")
        .navigationBarItems(trailing: refreshButton)
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
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

        // If `debug` is `true`, then sample albums have been provided
        // for testing purposes, so we shouldn't try to retrieve any from
        // the Spotify web API.
        if self.debug { return }
        
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
                            self.alertTitle = "Couldn't Retrieve Albums"
                            self.alertMessage = error.localizedDescription
                            self.alertIsPresented = true
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
