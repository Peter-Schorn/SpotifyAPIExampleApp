import Foundation
import Combine
import SpotifyWebAPI

extension SpotifyAPI where AuthorizationManager: SpotifyScopeAuthorizationManager {

    /**
     Makes a call to `availableDevices()` and plays the content on the
     active device if one exists. Else, plays content on the first available
     device.
     
     See [Using the Player Endpints][1].

     - Parameter playbackRequest: A request to play content.

     [1]: https://github.com/Peter-Schorn/SpotifyAPI/wiki/Using-the-Player-Endpoints
     */
    func getAvailableDeviceThenPlay(
        _ playbackRequest: PlaybackRequest
    ) -> AnyPublisher<Void, Error> {
        
        return self.availableDevices().flatMap {
            devices -> AnyPublisher<Void, Error> in
    
            // A device must have an id and must not be restricted
            // in order to accept web API commands.
            let usableDevices = devices.filter { device in
                !device.isRestricted && device.id != nil
            }

            // If there is an actice device, then it's usually a good idea
            // to use that one. For example, if content is already playing,
            // then it will be playing on the actice device. If not, then
            // just use the first available device.
            let device = usableDevices.first(where: \.isActive)
                    ?? usableDevices.first
            
            if let deviceId = device?.id {
                return self.play(playbackRequest, deviceId: deviceId)
            }
            else {
                return SpotifyLocalError.other(
                    "no active or available devices",
                    localizedDescription:
                    "There are no devices available to play content on. " +
                    "Try opening the Spotify app on one of your devices."
                )
                .anyFailingPublisher()
            }
            
        }
        .eraseToAnyPublisher()
        
    }

}

extension PlaylistItem {
    
    /// Returns `true` if this playlist item is probably the same as
    /// `other` by comparing the name and artist/show name.
    func isProbablyTheSameAs(_ other: Self) -> Bool {
        
        // don't return true if both URIs are `nil`.
        if let uri = self.uri, uri == other.uri {
            return true
        }
        
        switch (self, other) {
            case (.track(let track), .track(let otherTrack)):
                // if the name of the tracks and the name of the artists
                // are the same, then the tracks are probably the same
                return track.name == otherTrack.name &&
                        track.artists?.first?.name ==
                        otherTrack.artists?.first?.name
                
            case (.episode(let episode), .episode(let otherEpisode)):
                // if the name of the episodes and the names of the
                // shows they appear on are the same, then the episodes
                // are probably the same.
                return episode.name == otherEpisode.name &&
                        episode.show?.name == otherEpisode.show?.name
            default:
                return false
        }
        
    }
    
}
