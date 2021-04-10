import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent
import Combine
import Foundation

struct DebugView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var cancellables: Set<AnyCancellable> = []

    var body: some View {
        List {
            Button("Refresh Access Token") {
                self.spotify.api.authorizationManager.refreshTokens(
                    onlyIfExpired: false
                )
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("couldn't refresh tokens: \(error)")
                    }
                })
                .store(in: &self.cancellables)
            }
            Button("Make Access Token Expired") {
                self.spotify.api.authorizationManager.setExpirationDate(
                    to: Date()
                )
            }
        }
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
            .environmentObject(Spotify())
    }
}
