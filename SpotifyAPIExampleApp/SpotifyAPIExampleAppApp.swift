import SwiftUI
import Combine
import SpotifyWebAPI

@main
struct SpotifyAPIExampleAppApp: App {

    @StateObject var spotify = Spotify()

    init() {
        SpotifyAPILogHandler.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(spotify)
        }
    }
    
}
