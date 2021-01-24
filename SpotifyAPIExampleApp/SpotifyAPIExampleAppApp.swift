import SwiftUI
import Combine
import SpotifyWebAPI

@main
struct SpotifyAPIExampleAppApp: App {

    @StateObject var spotify = Spotify()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(spotify)
        }
    }
    
}
