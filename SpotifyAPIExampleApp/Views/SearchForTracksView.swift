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
    
    @State var tracks: [Track] = []

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    @State private var searchText = ""
    @State private var searchCancellable: AnyCancellable? = nil
    
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
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
    }
    
    /// A search bar. Essentially a textfield with a magnifying glass
    /// and an "x" button overlayed in front of it.
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
                        // Clear the search text when the user taps
                        // the "x" button.
                        Button(action: { self.searchText = "" }, label: {
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
    
}

struct SearchView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    
    static var previews: some View {
        NavigationView {
            SearchForTracksView()
                .environmentObject(spotify)
        }
        .preferredColorScheme(.light)
    }
    
}

