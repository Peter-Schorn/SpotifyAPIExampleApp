//
//  TopArtistsView.swift
//  Topotify
//
//  Created by Usama Fouad on 23/07/2022.
//

import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent


struct TopArtistsView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var topArtists = [Artist]()

    @State private var alert: AlertItem? = nil

    @State private var nextPageHref: URL? = nil
    @State private var isLoadingPage = false
    @State private var didRequestFirstPage = false
    
    @State private var loadTopArtistsCancellable: AnyCancellable? = nil

    init() {
        self._topArtists = State(initialValue: [])
    }
    
    fileprivate init(topArtists: [Artist]) {
        self._topArtists = State(initialValue: topArtists)
    }

    var body: some View {
        NavigationView {
            List {
                Section(header:
                            DateRangeSegmentedView()
                    .padding(.bottom)
                ) {
                    if topArtists.count < 3 {
                        if isLoadingPage {
                            HStack {
                                ProgressView()
                                    .padding()
                                Text("Loading Artists")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                            }
                        }
                        else {
                            Text("You didn't listen for enough artists")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                    else {
                        ForEach(
                            Array(topArtists.enumerated()),
                            id: \.offset
                        ) { item in

                            ArtistView(artist: item.element, offset: item.offset)
                                .onAppear {
                                    self.loadNextPageIfNeeded(offset: item.offset)
                                }

                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Top Artists")
            .navigationBarItems(trailing: refreshButton)
            .onAppear {
                if ProcessInfo.processInfo.isPreviewing {
                    return
                }

                if !self.didRequestFirstPage {
                    self.didRequestFirstPage = true
                    self.loadTopArtists()
                }
            }
            .alert(item: $alert) { alert in
                Alert(title: alert.title, message: alert.message)
            }
        }
        
        
    }
    
    var refreshButton: some View {
        Button(action: self.loadTopArtists) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoadingPage)
        
    }

}

extension TopArtistsView {
    func loadNextPageIfNeeded(offset: Int) {
        
        let threshold = self.topArtists.count - 5
        
        guard offset == threshold else {
            return
        }
        
        guard topArtists.count < ProcessInfo.MaxCount else {
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
    
//        print("loading next page")
        self.isLoadingPage = true
        
        self.loadTopArtistsCancellable = self.spotify.api
            .getFromHref(
                href,
                responseType: CursorPagingObject<Artist>.self
            )
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: self.receiveTopArtistsCompletion(_:),
                receiveValue: { topArtists in
                    let artists = topArtists.items
//                    print(
//                        "received next page with \(artists.count) items"
//                    )
                    self.nextPageHref = topArtists.next
                    
                    let expectedCount = self.topArtists.count + artists.count
                    
                    guard expectedCount < ProcessInfo.MaxCount else {
                        let remaining = ProcessInfo.MaxCount - self.topArtists.count
                        self.topArtists += artists[0..<remaining]
                        return
                    }
                    
                    self.topArtists += artists
                }
            )

    }

    func loadTopArtists() {
        self.isLoadingPage = true
        self.topArtists = []
        
        self.loadTopArtistsCancellable = self.spotify.api
            .currentUserTopArtists()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: self.receiveTopArtistsCompletion(_:),
                receiveValue: { topArtists in
                    let artists = topArtists.items
                    self.nextPageHref = topArtists.next
                    self.topArtists = artists
                }
            )

    }
    
    func receiveTopArtistsCompletion(
        _ completion: Subscribers.Completion<Error>
    ) {
        if case .failure(let error) = completion {
            let title = "Couldn't retrieve top artists"
            self.alert = AlertItem(
                title: title,
                message: error.localizedDescription
            )
        }
        self.isLoadingPage = false
    }

}


struct TopArtistsView_Previews: PreviewProvider {
    static let artists: [Artist] = [
        .levitationRoom, .theBeatles, .pinkFloyd, .radiohead, .crumb, .skinshape
    ]
    
    static var previews: some View {
        ForEach([artists], id: \.self) { artists in
            NavigationView {
                TopArtistsView(topArtists: artists)
                    .listStyle(PlainListStyle())
            }
        }
        .environmentObject(Spotify())
    }
}
