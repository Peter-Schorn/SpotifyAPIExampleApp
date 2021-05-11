import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent

struct RecentlyPlayedView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var recentlyPlayed: [Track]

    @State private var loadRecentlyPlayedCancellable: AnyCancellable? = nil

    @State private var alert: AlertItem? = nil

    @State private var nextPageHref: String? = nil
    @State private var isLoadingPage = false

    init() {
        self._recentlyPlayed = State(initialValue: [])
    }
    
    fileprivate init(recentlyPlayed: [Track]) {
        self._recentlyPlayed = State(initialValue: recentlyPlayed)
    }

    var body: some View {
        GeometryReader { geometry in
            CustomScrollView(
                width: geometry.size.width,
                height: geometry.size.height
            ) {
                LazyVStack {
                    ForEach(
                        Array(recentlyPlayed.enumerated()),
                        id: \.offset
                    ) { item in
                        
                        TrackView(track: item.element)
                            .padding(5)
                            // Each track in the list will be loaded lazily.
                            // We take advantage of this feature in order
                            // to detect when the user has scrolled to the bottom
                            // of the list
                            .onAppear {
                                self.loadNextPageIfNeeded(offset: item.offset)
                            }
                        Divider()
                        
                    }  // ForEach
                }  // LazyVStack
            }  // CustomScrollView
        }  // GeometryReader
        .onAppear(perform: loadRecentlyPlayed)
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        
    }
    
    func offsetDidChange(to offset: CGFloat) {
        print("offset did change to \(offset)")
    }
    
}

extension RecentlyPlayedView {
    
    func loadNextPageIfNeeded(offset: Int) {
        
        let threshold = self.recentlyPlayed.count - 5
        
        print("loadNextPageIfNeeded threshold: \(threshold); offset: \(offset)")
        
        // load the next page if this track is the fifth from the bottom of
        // of list
        guard offset == threshold else {
            return
        }
        
        guard let nextPageHref = self.nextPageHref else {
            // there are no more pages to be retrieved
            print("nextPageHref was nil")
            return
        }
        
        guard !self.isLoadingPage else {
            return
        }

        self.loadNextPage(href: nextPageHref)

    }
    
    func loadNextPage(href: String) {
    
        print("loading next page")
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
                    print("received next page")
                    self.nextPageHref = playHistory.next
                    self.recentlyPlayed += playHistory.items.map(\.track)
                }
            )

    }

    /// Loads the first page. Called when this view appears.
    func loadRecentlyPlayed() {
        
        print("loading first page")
        self.isLoadingPage = true
        
        self.loadRecentlyPlayedCancellable = self.spotify.api
            .recentlyPlayed()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: self.receiveRecentlyPlayedCompletion(_:),
                receiveValue: { playHistory in
                    self.nextPageHref = playHistory.next
                    self.recentlyPlayed = playHistory.items.map(\.track)
                }
            )

    }
    
    func receiveRecentlyPlayedCompletion(
        _ completion: Subscribers.Completion<Error>
    ) {
        if case .failure(let error) = completion {
            self.alert = AlertItem(
                title: "Couldn't retrieve recently played tracks",
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
        RecentlyPlayedView(recentlyPlayed: tracks)
            .environmentObject(Spotify())
    }
}