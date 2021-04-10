import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent
import Foundation

struct CurrentUserView: View {
    
    @EnvironmentObject var spotify: Spotify

//    @State private var currentUser: SpotifyUser? = nil
    @State private var currentUser: SpotifyUser? = .sampleCurrentUserProfile

    @State private var isLoadingCurrentUser = false
    
    @State private var alert: AlertItem? = nil

    @State private var retrieveCurrentUsercancellable: AnyCancellable? = nil

    var body: some View {
        Group {
            if let currentUser = currentUser {
                VStack(spacing: 20) {
                    Text(currentUser.displayName ?? "nil")
                    Text(currentUser.id)
                    Text(currentUser.product ?? "nil")
                    Text(currentUser.href)
                }
            }
            else {
                ProgressView()
            }
        }
        .navigationBarItems(trailing: refreshButton)
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onAppear(perform: retrieveCurrentUser)
        
    }
    
    var refreshButton: some View {
        Button(action: retrieveCurrentUser) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoadingCurrentUser)
        
    }
    
    func retrieveCurrentUser() {
        self.isLoadingCurrentUser = true
        self.retrieveCurrentUsercancellable =
            self.spotify.api.currentUserProfile()
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { completion in
                        self.isLoadingCurrentUser = false
                        if case .failure(let error) = completion {
                            print(error)
                            self.alert = AlertItem(
                                title: "Couldn't retrieve current user",
                                message: error.localizedDescription
                            )
                        }
                    },
                    receiveValue: { currentUser in
                        self.currentUser = currentUser
                    }
                )
    }
}

struct CurrentUserView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CurrentUserView()
                .environmentObject(Spotify())
        }
    }
}
