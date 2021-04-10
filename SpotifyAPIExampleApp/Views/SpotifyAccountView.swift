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

    var body: some View {
        Button(action: {
            #warning("DEBUG")
//            self.spotify.assertAccountsMatchUsers()
//            spotify.currentAccount = account
//            spotify.api.authorizationManager = account.authorizationManager
//            spotify.accountsListViewIsPresented = false
//            self.spotify.assertAccountsMatchUsers()
        }, label: {
            HStack {
                Image(systemName: "checkmark")
                    .opacity(
                        spotify.currentAccount == account ? 100 : 0
                    )
                Text(account.user.displayName ?? account.user.id)
                    .contextMenu {
                        Button(action: {
                            print(self.account)
                        }, label: {
                            Text("print to the console")
                        })
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
