import SwiftUI
import Combine
import SpotifyWebAPI

@main
struct SpotifyAPIExampleAppApp: App {

    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var spotify = Spotify()

    init() {
        SpotifyAPILogHandler.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(spotify)
        }
        .onChange(
            of: scenePhase,
            perform: onChangeOfScenePhase(to:)
        )
        
    }
    
    func onChangeOfScenePhase(to newPhase: ScenePhase) {
        print("scene phase changed from \(scenePhase) to \(newPhase)")
        switch newPhase {
            case .active:
                if !self.spotify.appRemote.isConnected {
                    self.spotify.connectToAppRemote()
                }
            default:
                break
        }
        
    }
    
}
