//
//  TopSongsView.swift
//  Topotify
//
//  Created by Usama Fouad on 23/07/2022.
//

import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent


struct TopSongsView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var topSongs: [Track]
    
    @State private var showSettingsView = false

    @State private var alert: AlertItem? = nil

    @State private var nextPageHref: URL? = nil
    @State private var isLoadingPage = false
    @State private var didRequestFirstPage = false
    
    @State private var loadTopSongsCancellable: AnyCancellable? = nil

    init() {
        self._topSongs = State(initialValue: [])
    }
    
    fileprivate init(topSongs: [Track]) {
        self._topSongs = State(initialValue: topSongs)
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: DateRangeSegmentedView().padding(.bottom)) {
                    if topSongs.count < ProcessInfo.MinCount {
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
                            Text("You didn't listen for enough songs")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                    else {
                        ForEach(
                            Array(topSongs.enumerated()),
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
            .listStyle(.insetGrouped)
            .navigationTitle("Top Songs")
            .navigationBarItems(trailing: refreshButton)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    settingsButton
                }
            }
            .disabled(!spotify.isAuthorized)
            .onAppear {
                if ProcessInfo.processInfo.isPreviewing {
                    return
                }
                
                if !self.didRequestFirstPage {
                    self.didRequestFirstPage = true
                    self.loadTopSongs()
                }
            }
            .alert(item: $alert) { alert in
                Alert(title: alert.title, message: alert.message)
            }
        }
        
    }
    
    var refreshButton: some View {
        Button(action: self.loadTopSongs) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoadingPage)
        
    }
    
    var settingsButton: some View {
        HStack {
            Button(action: { showSettingsView = true }) {
                Image(systemName: "gearshape")
                    .foregroundColor(.secondary)
            }
            NavigationLink("", destination:  SettingsView(), isActive: $showSettingsView)
        }
    }

}

extension TopSongsView {
    func loadNextPageIfNeeded(offset: Int) {
        
        let threshold = self.topSongs.count - 5
        
//        print(
//            """
//            loadNextPageIfNeeded threshold: \(threshold); offset: \(offset); \
//            total: \(self.topSongs.count)
//            """
//        )
        guard topSongs.count < ProcessInfo.MaxCount else {
            return
        }
        
        guard offset == threshold else {
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
    
    func loadNextPage(href: URL) {
    
//        print("loading next page")
        self.isLoadingPage = true
        
        self.loadTopSongsCancellable = self.spotify.api
            .getFromHref(
                href,
                responseType: CursorPagingObject<Track>.self
            )
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: self.receiveTopSongsCompletion(_:),
                receiveValue: { songs in
                    let tracks = songs.items
//                    print(
//                        "received next page with \(tracks.count) items"
//                    )
                    self.nextPageHref = songs.next
                    
                    let expectedCount = self.topSongs.count + tracks.count
                    
                    guard expectedCount < ProcessInfo.MaxCount else {
                        let remaining = ProcessInfo.MaxCount - self.topSongs.count
                        self.topSongs += tracks[0..<remaining]
                        return
                    }
                    
                    self.topSongs += tracks
                }
            )

    }

    func loadTopSongs() {
        
//        print("loading first page")
        self.isLoadingPage = true
        self.topSongs = []
        
        self.loadTopSongsCancellable = self.spotify.api
            .currentUserTopTracks()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: self.receiveTopSongsCompletion(_:),
                receiveValue: { songs in
//                    print("Tracks: ", songs)
                    let tracks = songs.items
//                    print(
//                        "received first page with \(tracks.count) items"
//                    )
                    self.nextPageHref = songs.next
                    self.topSongs = tracks
                }
            )

    }
    
    func receiveTopSongsCompletion(
        _ completion: Subscribers.Completion<Error>
    ) {
        if case .failure(let error) = completion {
            let title = "Couldn't retrieve recently played tracks"
//            print("\(title): \(error)")
            self.alert = AlertItem(
                title: title,
                message: error.localizedDescription
            )
        }
        self.isLoadingPage = false
    }

}


struct TopSongsView_Previews: PreviewProvider {
    static let tracks: [Track] = [
        .because, .comeTogether, .faces, .illWind,
        .odeToViceroy, .reckoner, .theEnd, .time
    ]
    
    static var previews: some View {
        ForEach([tracks], id: \.self) { tracks in
            NavigationView {
                TopSongsView(topSongs: tracks)
                    .listStyle(PlainListStyle())
            }
        }
        .environmentObject(Spotify())
    }
}
