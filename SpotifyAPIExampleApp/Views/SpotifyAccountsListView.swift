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
                        .onDelete(perform: { indexSet in
                            self.spotify.accounts.remove(atOffsets: indexSet)
                            self.spotify.updateAccountsInKeychain()
                        })
                        .onMove(perform: { indices, newOffset in
                            self.spotify.accounts.move(
                                fromOffsets: indices, toOffset: newOffset
                            )
                            self.spotify.updateAccountsInKeychain()
                        })
                    }
                }
            }
            .navigationBarTitle("Choose an Account")
            .navigationBarItems(
                leading: EditButton(),
                trailing: addNewAccountView
            )
            
        }
        .modifier(
            ModalProgressView(
                message: "Authenticating",
                isPresented: $spotify.isRetrievingTokens
            )
        )
        .onAppear {
            // MARK: DEBUG
//            spotify.accounts = SpotifyAccount.sampleAccounts
//            spotify.currentAccount = spotify.accounts.first!

        }
    }
    
    var addNewAccountView: some View {
        Button(action: self.spotify.authorize, label: {
            Text("Add New Account")
        })
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
            .environmentObject(spotify)
    }
}
