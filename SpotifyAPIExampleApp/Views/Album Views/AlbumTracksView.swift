//
//  AlbumTracksView.swift
//  SpotifyAPIExampleApp
//
//  Created by Peter Schorn on 9/19/20.
//

import SwiftUI
import Combine
import SpotifyWebAPI

struct AlbumTracksView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    @State private var loadTracksCancellable: AnyCancellable? = nil
    @State private var playAlbumCancellable: AnyCancellable? = nil
    
    @State private var isLoadingTracks = false
    @State private var couldntLoadTracks = false
    
    @State var albumTracks: [Track] = []

    var album: Album
    var image: Image
    
    /// The album and artist name; e.g., "Abbey Road - The Beatles".
    var albumAndArtistName: String {
        var title = album.name
        if let artistName = album.artists?.first?.name {
            title += " - \(artistName)"
        }
        return title
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ZStack {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(20)
                        .shadow(radius: 20)
                    playButton
                }
                .padding(30)
                Text(albumAndArtistName)
                    .font(.title)
                    .bold()
                    .padding(.horizontal)
                Text("\(album.tracks?.total ?? 0) Tracks")
                    .foregroundColor(.secondary)
                    .font(.title2)
                    .padding(.top, 2)
                if albumTracks.isEmpty {
                    Group {
                        if isLoadingTracks {
                            HStack {
                                ProgressView()
                                    .padding()
                                Text("Loading Tracks")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                            }
                        }
                        else if couldntLoadTracks {
                            Text("Couldn't Load Tracks")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                }
                else {
                    ForEach(albumTracks.enumeratedArray(), id: \.index) { track in
                        HStack {
                            Text("\(track.index + 1). \(track.element.name)")
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
        .onAppear(perform: loadTracks)
    }
    
    /// Plays the album when tapped.
    var playButton: some View {
        Button(action: {
            guard let albumURI = album.uri else {
                print("missing album uri for '\(album.name)'")
                return
            }
            let playbackRequest = PlaybackRequest(
                context: .contextURI(albumURI), offset: nil
            )
            print("playing album '\(album.name)'")
            self.playAlbumCancellable = spotify.api
                .play(playbackRequest)
                .print("play album sink")
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    print("Received play album completion")
                    if case .failure(let error) = completion {
                        self.alertTitle = "Couldn't Play Album"
                        self.alertMessage = error.localizedDescription
                        self.alertIsPresented = true
                    }
                })
        }, label: {
            Image(systemName: "play.circle")
                .resizable()
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
                .frame(width: 100, height: 100)
                
        })
    }
    
    /// Loads the album tracks.
    func loadTracks() {
        
        guard let albumURI = album.uri else {
            return
        }
        
        self.isLoadingTracks = true
        self.albumTracks = []
        self.loadTracksCancellable = spotify.api.albumTracks(
            albumURI, limit: 50
        )
        .extendPages(spotify.api)
        .sink(
            receiveCompletion: { completion in
                self.isLoadingTracks = false
                switch completion {
                    case .finished:
                        self.couldntLoadTracks = false
                    case .failure(let error):
                        self.couldntLoadTracks = true
                        self.alertTitle = "Couldn't Load Tracks"
                        self.alertMessage = error.localizedDescription
                        self.alertIsPresented = true
                }
            },
            receiveValue: { albumTracks in
                let tracks = albumTracks.items
                self.albumTracks.append(contentsOf: tracks)
            }
        )
                

    }
    
    
}

struct AlbumTracksView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    static let album = Album.darkSideOfTheMoon
    
    static var previews: some View {
        NavigationView {
            AlbumTracksView(
                album: album, image: Image(.spotifyAlbumPlaceholder)
            )
            .environmentObject(spotify)
        }
    }
}
