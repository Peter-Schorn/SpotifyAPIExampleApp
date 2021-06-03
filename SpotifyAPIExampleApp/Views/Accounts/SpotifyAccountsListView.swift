import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent
import Combine
import Foundation

struct SpotifyAccountsListView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var alert: AlertItem? = nil

    @State private var cancellables: Set<AnyCancellable> = []

    var body: some View {
        
        NavigationView {
            Group {
                if spotify.accounts.isEmpty {
                    Text("No Accounts")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                else {
                    List {
                        ForEach(
                            spotify.accounts,
                            content: SpotifyAccountView.init(account:)
                        )
                        .onDelete(perform: self.onDeleteAccounts(indexSet:))
                        .onMove { indices, newOffset in
                            self.spotify.accounts.move(
                                fromOffsets: indices, toOffset: newOffset
                            )
                            self.spotify.updateAccountsInKeychain()
                        }
                    }
                }
            }
            .navigationBarTitle("Choose an Account")
            .navigationBarItems(
                leading: EditButton(),
                trailing: addNewAccountView
            )
            
        }
        .modalProgressView(
            message: "Authenticating",
            isPresented: $spotify.isRetrievingTokens
        )
    }
    
    func onDeleteAccounts(indexSet: IndexSet) {
        
        // This is a computed property, so even if it was non-optional, it's
        // important to bind it to a local variable to avoid repeated access in
        // each iteration of the loop.
        if let currentAccount = self.spotify.currentAccount {
            for index in indexSet {
                // if we are deleting the current account, then make sure to set
                // `spotify.currentAccount` to `nil` and deauthorize the
                // authorization manager, because it's always authorized for the
                // current account
                if self.spotify.accounts[index].user.uri ==
                        currentAccount.user.uri {
                    print(
                        "deleted current account: " +
                        "\(currentAccount.user.displayName ?? "nil")"
                    )
                    self.spotify.currentAccount = nil
                    self.spotify.api.authorizationManager.deauthorize()
                    break
                }
            }
        }
        
        self.spotify.accounts.remove(atOffsets: indexSet)
        self.spotify.updateAccountsInKeychain()

    }

    var addNewAccountView: some View {
        Button(action: self.spotify.authorize, label: {
            Text("Add New Account")
        })
        // for debugging purposes
        .contextMenu {
            Button("Print Current Account") {
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
            }
        }
    }

}

struct SpotifyAccountsListView_Previews: PreviewProvider {
    
    static let spotify: Spotify = {
        let spotify = Spotify()
        
        // use separate storage of the sample accounts
        spotify.spotifyAccountsKey = "spotifyAccountsPreview"
        spotify.currentAccountKey = "currentSpotifyAccountPreview"
        spotify.accounts = SpotifyAccount.sampleAccounts
        
        return spotify
    }()

    static var previews: some View {
        
        SpotifyAccountsListView()
            // this style is implicitly applied when this view is presented in a
            // sheet, which is how it is presented in this app
            .listStyle(PlainListStyle())
            .environmentObject(spotify)
        
    }
    
}
