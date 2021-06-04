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
            NavigationLink(
                "Recently Played Tracks", destination: RecentlyPlayedView()
            )
            NavigationLink(
<<<<<<< HEAD
                "Debug", destination: DebugView()
=======
                "Debug Menu", destination: DebugMenuView()
>>>>>>> 4f98519... Reformatted comments to 80 characters per line in Spotify, RootView, LoginView, and ExamplesListView.
            )
            
            // This is the location where you can add your own views to test out
            // your application. Each view receives an instance of `Spotify`
            // from the environment.
            
        }
        .listStyle(PlainListStyle())
        
    }
}

struct ExamplesListView_Previews: PreviewProvider {
    
    static let spotify: Spotify = {
        let spotify = Spotify()
        spotify.isAuthorized = true
        return spotify
    }()
    
    static var previews: some View {
        NavigationView {
            ExamplesListView()
                .environmentObject(spotify)
        }
    }
}
