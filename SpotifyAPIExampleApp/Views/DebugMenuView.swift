import SwiftUI
import Combine

struct DebugMenuView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var cancellables: Set<AnyCancellable> = []

    var body: some View {
        List {
            Button("Make Access Token Expired") {
                self.spotify.api.authorizationManager.setExpirationDate(
                    to: Date()
                )
            }
            Button("Refresh Access Token") {
                self.spotify.api.authorizationManager.refreshTokens(
                    onlyIfExpired: false
                )
                .sink(receiveCompletion: { completion in
                    print("refresh tokens completion: \(completion)")
                    
                })
                .store(in: &self.cancellables)
            }
            Button("Print Current Account", action: printCurrentAccount)
        }
    }
    
    func printCurrentAccount() {
        
        if let account = self.spotify.currentAccount {
            print(
                """
                --- current account ---
                \(account)
                -----------------------
                """
            )
        }
        else {
            print("current account is nil")
        }
        
        self.spotify.api.currentUserProfile()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print(
                            "couldn't retrieve current user " +
                            "profile: \(error)"
                        )
                    }
                },
                receiveValue: { currentUser in
                    print(
                        """
                        --- current user profile ---
                        \(currentUser)
                        ----------------------------
                        """
                    )

                }
            )
            .store(in: &self.cancellables)
        
    }

}

struct DebugMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DebugMenuView()
        }
        .environmentObject(Spotify())
    }
}
