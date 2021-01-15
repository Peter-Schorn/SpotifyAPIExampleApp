import Foundation

extension SPTAppRemote {
    
    /**
     Authorizes the app if needed, and then plays the provided content.
     
     If the app remote is connected, then calls
     `SPTAppRemotePlayerAPI.play(_:callback:)` and passes in
     `completionHandler` for the callback and returns `true`.
     
     If the app remote is not connected, then calls
     `authorizeAndPlayURI(_:)` and returns `true` if the Spotify App is
     installed or `false` if it isn't.
     
     - Parameters:
       - uri: The Spotify URI for the content to play.
       - completionHandler: The completion handler to call when the
         request to play content completes. Only called if the app remote
         is connected.
     - Returns: Whether or not the Spotify app is installed.
     */
    @discardableResult
    func authorizeIfNeededAndPlay(
        uri: String, completionHandler: ((Error?) -> Void)? = nil
    ) -> Bool {
        if self.isConnected {
            self.playerAPI?.play(uri) { result, error in
                completionHandler?(error)
            }
            return true
        }
        else {
            return self.authorizeAndPlayURI(uri)
        }

    }

}
