import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent
import Foundation

struct SpotifyAccountView: View {
    
    @EnvironmentObject var spotify: Spotify

    let account: SpotifyAccount
    
    init(account: SpotifyAccount) {
        self.account = account
    }

    var isTheCurrentAccount: Bool {
        return self.spotify.currentAccount?.user.uri == self.account.user.uri
    }
    
    var body: some View {
        // sets this account as the current account
        Button(action: {
            // don't do anything if this is already the current account
            if spotify.currentAccount?.user.uri != account.user.uri {
                spotify.currentAccount = account
            }
        }, label: {
            HStack {
                // Display a checkmark if this is the current account
                Image(systemName: "checkmark")
                    .opacity(isTheCurrentAccount ? 100 : 0)
                Text(account.user.displayName ?? account.user.id)
                    .contextMenu {
                        #if DEBUG
                        Button(action: {
                            print(self.account)
                        }, label: {
                            Text("print to the console")
                        })
                        #endif
                    }
            }
        })

    }
    
}

struct SpotifyAccountView_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyAccountsListView_Previews.previews
    }
}
