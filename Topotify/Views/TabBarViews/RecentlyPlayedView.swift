import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent

struct RecentlyPlayedView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var recentlyPlayed = [Track]()

    @State private var alert: AlertItem? = nil

    @State private var nextPageHref: URL? = nil
    @State private var isLoadingPage = false
    @State private var didRequestFirstPage = false
    
    @State private var loadRecentlyPlayedCancellable: AnyCancellable? = nil

    init() {
        self._recentlyPlayed = State(initialValue: [])
    }
    
    fileprivate init(recentlyPlayed: [Track]) {
        self._recentlyPlayed = State(initialValue: recentlyPlayed)
    }

    var body: some View {
        NavigationView {
            Group {
                if recentlyPlayed.count < ProcessInfo.MinCount {
                    if isLoadingPage {
                        HStack {
                            ProgressView()
                                .padding()
                            Text("Loading Tracks")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                    else {
                        Text("No Recently Played Tracks")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                else {
                    List {
                        ForEach(
                            Array(recentlyPlayed.enumerated()),
                            id: \.offset
                        ) { item in

                            TrackView(track: item.element, offset: item.offset)
                                .onAppear {
                                    self.loadNextPageIfNeeded(offset: item.offset)
                                }

                        }
                    }
                }
            }
            .navigationTitle("Recently Played")
            .navigationBarItems(trailing: refreshButton)
            .onAppear {
                if ProcessInfo.processInfo.isPreviewing {
                    return
                }
                if !self.didRequestFirstPage {
                    self.didRequestFirstPage = true
                    self.loadRecentlyPlayed()
                }
            }
            .alert(item: $alert) { alert in
                Alert(title: alert.title, message: alert.message)
        }
        }
        
        
    }
    
    var refreshButton: some View {
        Button(action: self.loadRecentlyPlayed) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoadingPage)
        
    }

}

extension RecentlyPlayedView {
    
    // Normally, you would extract these methods into a separate model class.
    
    /// Determines whether or not to load the next page based on the offset of
    /// the just-loaded item in the list.
    func loadNextPageIfNeeded(offset: Int) {
        
        let threshold = self.recentlyPlayed.count - 5
        
//        print(
//            """
//            loadNextPageIfNeeded threshold: \(threshold); offset: \(offset); \
//            total: \(self.recentlyPlayed.count)
//            """
//        )
        
        // load the next page if this track is the fifth from the bottom of the
        // list
        guard offset == threshold else {
            return
        }
        
        guard recentlyPlayed.count < ProcessInfo.MaxCount else {
            return
        }
        
        guard let nextPageHref = self.nextPageHref else {
//            print("no more paged to load: nextPageHref was nil")
            return
        }
        
        guard !self.isLoadingPage else {
            return
        }

        self.loadNextPage(href: nextPageHref)

    }
    
    /// Loads the next page of results from the provided URL.
    func loadNextPage(href: URL) {
        self.isLoadingPage = true
        
        self.loadRecentlyPlayedCancellable = self.spotify.api
            .getFromHref(
                href,
                responseType: CursorPagingObject<PlayHistory>.self
            )
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: self.receiveRecentlyPlayedCompletion(_:),
                receiveValue: { playHistory in
                    let tracks = playHistory.items.map(\.track)
//                    print(
//                        "received next page with \(tracks.count) items"
//                    )
                    self.nextPageHref = playHistory.next
                    
                    let expectedCount = self.recentlyPlayed.count + tracks.count
                    
                    guard expectedCount < ProcessInfo.MaxCount else {
                        let remaining = ProcessInfo.MaxCount - self.recentlyPlayed.count
                        self.recentlyPlayed += tracks[0..<remaining]
                        return
                    }
                    
                    self.recentlyPlayed += tracks
                }
            )

    }

    /// Loads the first page. Called when this view appears.
    func loadRecentlyPlayed() {
        
        self.isLoadingPage = true
        self.recentlyPlayed = []
        
        self.loadRecentlyPlayedCancellable = self.spotify.api
            .recentlyPlayed()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: self.receiveRecentlyPlayedCompletion(_:),
                receiveValue: { playHistory in
                    let tracks = playHistory.items.map(\.track)
                    self.nextPageHref = playHistory.next
                    self.recentlyPlayed = tracks
                }
            )

    }
    
    func receiveRecentlyPlayedCompletion(
        _ completion: Subscribers.Completion<Error>
    ) {
        if case .failure(let error) = completion {
            let title = "Couldn't retrieve recently played tracks"
            self.alert = AlertItem(
                title: title,
                message: error.localizedDescription
            )
        }
        self.isLoadingPage = false
    }

}

struct RecentlyPlayedView_Previews: PreviewProvider {
    
    static let tracks: [Track] = [
        .because, .comeTogether, .faces, .illWind,
        .odeToViceroy, .reckoner, .theEnd, .time
    ]
    
    static var previews: some View {
        ForEach([tracks], id: \.self) { tracks in
            NavigationView {
                RecentlyPlayedView(recentlyPlayed: tracks)
                    .listStyle(PlainListStyle())
            }
        }
        .environmentObject(Spotify())
    }
}
