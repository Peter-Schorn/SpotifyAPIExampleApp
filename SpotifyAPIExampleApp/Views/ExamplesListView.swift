//
//  ExamplesListView.swift
//  SpotifyAPIExampleApp
//
//  Created by Peter Schorn on 9/19/20.
//

import SwiftUI

struct ExamplesListView: View {
    
    var body: some View {
        List {
            NavigationLink(
                "Playlists", destination: PlaylistsListView()
            )
            NavigationLink(
                "Saved Albums", destination: SavedAlbumsGridView()
            )
            NavigationLink(
                "Search For Tracks", destination: SearchForTracksView()
            )
            
        }
        .listStyle(PlainListStyle())
    }
}

struct ExamplesListView_Previews: PreviewProvider {
    static var previews: some View {
        ExamplesListView()
    }
}
