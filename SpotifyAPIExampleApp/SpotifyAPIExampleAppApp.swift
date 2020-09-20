//
//  SpotifyAPIExampleAppApp.swift
//  SpotifyAPIExampleApp
//
//  Created by Peter Schorn on 9/19/20.
//

import SwiftUI
import Combine
import SpotifyWebAPI

@main
struct SpotifyAPIExampleAppApp: App {
    
    let spotify = Spotify()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(spotify)
        }
    }
    
}
