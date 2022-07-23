//
//  ArtistView.swift
//  Topotify
//
//  Created by Usama Fouad on 23/07/2022.
//

import SwiftUI
import Combine
import SpotifyWebAPI

struct ArtistView: View {
    
    @EnvironmentObject var spotify: Spotify
        
    let artist: Artist
    var offset: Int?
    
    @State private var alert: AlertItem? = nil
    
    @State private var image = Image(.spotifyAlbumPlaceholder)

    @State private var didRequestImage = false
    
    // MARK: Cancellables
    @State private var loadImageCancellable: AnyCancellable? = nil
    
    var body: some View {
        HStack {
            if let offset = offset {
                Text("\(offset+1)")
                    .fontWeight(.bold)
            }
            
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .shadow(color: .secondary, radius: 2, x: 0, y: 0)
                .padding(5)
            
            VStack(alignment: .leading) {
                Text(artist.name)
                    .font(.system(.title2))
            }
            .lineLimit(1)

            Spacer()
        }
        .onAppear(perform: loadImage)
        .contentShape(Rectangle())
    }
    
    func loadImage() {
        if self.didRequestImage {
            // print("already requested image for '\(playlist.name)'")
            return
        }
        self.didRequestImage = true
        
        guard let spotifyImage = artist.images?.largest else {
            // print("no image found for '\(playlist.name)'")
            return
        }
        self.loadImageCancellable = spotifyImage.load()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { image in
                    // print("received image for '\(playlist.name)'")
                    self.image = image
                }
            )
    }
}

struct ArtistView_Previews: PreviewProvider {
    
    static let artists: [Artist] = [
        .levitationRoom, .theBeatles, .pinkFloyd, .radiohead, .crumb, .skinshape
    ]

    static var previews: some View {
        List(artists, id: \.id) { artist in
            ArtistView(artist: artist)
        }
        .environmentObject(Spotify())
    }
}
