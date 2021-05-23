import SwiftUI

struct DebugMenuView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var alert: AlertItem? = nil

    var body: some View {
        List {
            Button("Renew SPTSession") {
                guard self.spotify.sessionManager.session != nil else {
                    self.alert = AlertItem(
                        title: "Cannot Renew the Session Because no Session Exists",
                        message: ""
                    )
                    return
                }
                // If `sessionManager.session` is `nil`, then calling this
                // method will cause a crash.
                self.spotify.sessionManager.renewSession()
            }
            Button("Print Authorization Manager and SPTSession") {
                let sessionString = self.spotify.sessionManager.session
                    .map(String.init) ?? "nil"
                print(
                    """
                    --- spotify.api.authorizationManager ---
                    \(self.spotify.api.authorizationManager)
                    --- spotify.sessionManager.session ---
                    \(sessionString)
                    """
                )
            }
        }
        .navigationBarTitle("Debug Menu")
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onReceive(spotify.sessionManagerDidFailWithError) { error in
            let message: String
            if let sptError = error as? SPTError {
                message = sptError.underlyingErrorLocalizedDescription
            }
            else {
                message = error.localizedDescription
            }
            self.alert = AlertItem(
                title: "Couldn't Initiate or Renew the Session",
                message: message
            )
        }
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
