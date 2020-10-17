import SwiftUI

struct ExamplesListView: View {
    
    var body: some View {
        /*
         This is the location where you can add your own views to
         test out your application.
         */
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
    
    static let spotify: Spotify = {
        let spotify = Spotify()
        // Don't ever do this in non-testing code.
        spotify.isAuthorized = true
        return spotify
    }()
    
    static var previews: some View {
        ExamplesListView()
            .environmentObject(spotify)
    }
}
