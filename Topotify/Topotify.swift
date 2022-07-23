import SwiftUI
import Combine
import SpotifyWebAPI

@main
struct Topotify: App {

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
