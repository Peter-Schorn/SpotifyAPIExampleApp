//
//  SearchView.swift
//  SpotifyAPIExampleApp
//
//  Created by Peter Schorn on 9/19/20.
//

import SwiftUI
import SpotifyWebAPI
import Combine

struct SearchForTracksView: View {

    @EnvironmentObject var spotify: Spotify
    
    @State private var isSearching = false
    
    @State private var tracks: [Track] = []

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    @State private var searchText = ""
    @State private var searchCancellable: AnyCancellable? = nil


    @State private var playRequestCancellables: Set<AnyCancellable> = []
    
    var body: some View {
        VStack {
            searchBar
                .padding([.top, .horizontal])
            Text(
                "Enter a query to search for tracks. " +
                "Tap on a track to play it on your active device."
            )
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            List {
                ForEach(tracks, id: \.self) { track in
                    Button(self.trackDisplayName(track)) {
                        self.playTrack(track)
                    }
                }
            }
            .overlay(
                Group {
                    if tracks.isEmpty {
                        if isSearching {
                            HStack {
                                ActivityIndicator(
                                    isAnimating: .constant(true),
                                    style: .medium
                                )
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
                }
            )
            
        }
        .navigationTitle("Search For Tracks")
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
    }
    
    var searchBar: some View {
        // Every time the user presses the return key, perform a search.
        TextField("Search", text: $searchText, onCommit: search)
            .padding(.leading, 22)
            .overlay(
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary),
                alignment: .leading
            )
            .padding(.vertical, 7)
            .padding(.horizontal, 7)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
    }
    
    /// Includes the name of the track and the artist.
    func trackDisplayName(_ track: Track) -> String {
        var displayName = track.name
        if let artistName = track.artists?.first?.name {
            displayName += " - \(artistName)"
        }
        return displayName
    }
    
    /// Performs a search for tracks based on `searchText`.
    func search() {

        print("searching with query '\(searchText)'")
        self.isSearching = true
        self.tracks = []
        
        self.searchCancellable = spotify.api.search(
            query: searchText, categories: [.track]
        )
        .receive(on: RunLoop.main)
        .sink(
            receiveCompletion: { completion in
                self.isSearching = false
                if case .failure(let error) = completion {
                    self.alertTitle = "Couldn't Perform Search"
                    self.alertMessage = error.localizedDescription
                    self.alertIsPresented = true
                }
            },
            receiveValue: { searchResults in
                self.tracks = searchResults.tracks?.items ?? []
                print("received \(self.tracks.count) tracks")
            }
        )
    }
    
    /// Plays a track on the user's active device.
    func playTrack(_ track: Track) {
        
        guard let trackURI = track.uri else {
            self.alertTitle = "Couldn't Play '\(track.name)'"
            self.alertMessage = "missing URI"
            self.alertIsPresented = true
            return
        }
        
        // A request to play a single track.
        let playbackRequest = PlaybackRequest(trackURI)
        
        self.spotify.api.play(playbackRequest)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.alertTitle = "Couldn't Play '\(track.name)'"
                    self.alertMessage = error.localizedDescription
                    self.alertIsPresented = true
                }
            })
            .store(in: &playRequestCancellables)
    }
    
}

struct SearchView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    
    static var previews: some View {
        NavigationView {
            SearchForTracksView()
                .environmentObject(spotify)
        }
    }
}

