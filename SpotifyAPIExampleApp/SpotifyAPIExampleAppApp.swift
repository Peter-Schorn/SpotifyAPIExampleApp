import SwiftUI
import Combine
import SpotifyWebAPI

@main
struct SpotifyAPIExampleAppApp: App {

    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var spotify = Spotify()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(spotify)
        }
        // .onChange(of: scenePhase) { newScenePhase in
        //     print("newScenePhase:", newScenePhase)
        //     switch newScenePhase {
        //         case .active:
        //             spotify.appRemote.connect()
        //         case .inactive:
        //             spotify.appRemote.disconnect()
        //         default:
        //             break
        //     }
        // }
        
    }
    
}
