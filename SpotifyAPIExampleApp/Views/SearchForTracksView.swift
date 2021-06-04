import SwiftUI
import SpotifyWebAPI
import Combine

struct SearchForTracksView: View {

    @EnvironmentObject var spotify: Spotify
    
    @State private var isSearching = false
    
    @State var tracks: [Track] = []

    @State private var alert: AlertItem? = nil
    
    @State private var searchText = ""
    @State private var searchCancellable: AnyCancellable? = nil
    
    /// Used by the preview provider to provide sample data.
    fileprivate init(sampleTracks: [Track]) {
        self._tracks = State(initialValue: sampleTracks)
    }
    
    init() { }
    
    var body: some View {
        VStack {
            searchBar
                .padding([.top, .horizontal])
            Text("Tap on a track to play it.")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            if tracks.isEmpty {
                if isSearching {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Searching")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                    
                }
                else {
                    Text("No Results")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                List {
                    ForEach(tracks, id: \.self) { track in
                        TrackView(track: track)
                    }
                }
            }
            Spacer()
        }
        .navigationTitle("Search For Tracks")
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
    }
    
    /// A search bar. Essentially a textfield with a magnifying glass and an "x"
    /// button overlayed in front of it.
    var searchBar: some View {
        // `onCommit` is called when the user presses the return key.
        TextField("Search", text: $searchText, onCommit: search)
            .padding(.leading, 22)
            .overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    Spacer()
                    if !searchText.isEmpty {
                        // Clear the search text when the user taps the "x"
                        // button.
                        Button(action: {
                            self.searchText = ""
                            self.tracks = []
                        }, label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        })
                    }
                }
            )
            .padding(.vertical, 7)
            .padding(.horizontal, 7)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
    }
    
    /// Performs a search for tracks based on `searchText`.
    func search() {

        self.tracks = []
        
        if self.searchText.isEmpty { return }

        print("searching with query '\(self.searchText)'")
        self.isSearching = true
        
        self.searchCancellable = spotify.api.search(
            query: self.searchText, categories: [.track]
        )
        .receive(on: RunLoop.main)
        .sink(
            receiveCompletion: { completion in
                self.isSearching = false
                if case .failure(let error) = completion {
                    self.alert = AlertItem(
                        title: "Couldn't Perform Search",
                        message: error.localizedDescription
                    )
                }
            },
            receiveValue: { searchResults in
                self.tracks = searchResults.tracks?.items ?? []
                print("received \(self.tracks.count) tracks")
            }
        )
    }
    
}

struct SearchView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    
    static let tracks: [Track] = [
        .because, .comeTogether, .odeToViceroy, .illWind,
        .faces, .theEnd, .time, .theEnd, .reckoner
    ]
    
    static var previews: some View {
        NavigationView {
            SearchForTracksView(sampleTracks: tracks)
                .listStyle(PlainListStyle())
                .environmentObject(spotify)
                
        }
    }
    
}

