import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    var body: some View {
        List {
            Section(header: Text("Account")) {
                Button(action: spotify.api.authorizationManager.deauthorize) {
                    Text("Logout")
                        .foregroundColor(.red)
                }

            }
        }
    }
}

struct ExamplesListView_Previews: PreviewProvider {
    
    static let spotify: Spotify = {
        let spotify = Spotify()
        spotify.isAuthorized = true
        return spotify
    }()
    
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(spotify)
        }
    }
}
