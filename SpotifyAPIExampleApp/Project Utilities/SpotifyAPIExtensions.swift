import Foundation
import Combine
import SpotifyWebAPI

extension SpotifyAPI where AuthorizationManager: SpotifyScopeAuthorizationManager {

    /**
     Makes a call to `availableDevices()` and plays the content on the active
     device if one exists. Else, plays content on the first available device.
     
     See [Using the Player Endpoints][1].

     - Parameter playbackRequest: A request to play content.

     [1]: https://github.com/Peter-Schorn/SpotifyAPI/wiki/Using-the-Player-Endpoints
     */
    func getAvailableDeviceThenPlay(
        _ playbackRequest: PlaybackRequest
    ) -> AnyPublisher<Void, Error> {
        
        return self.availableDevices().flatMap {
            devices -> AnyPublisher<Void, Error> in
    
            // A device must have an id and must not be restricted in order to
            // accept web API commands.
            let usableDevices = devices.filter { device in
                !device.isRestricted && device.id != nil
            }

            // If there is an active device, then it's usually a good idea to
            // use that one. For example, if content is already playing, then it
            // will be playing on the active device. If not, then just use the
            // first available device.
            let device = usableDevices.first(where: \.isActive)
                    ?? usableDevices.first
            
            if let deviceId = device?.id {
                return self.play(playbackRequest, deviceId: deviceId)
            }
            else {
                return SpotifyGeneralError.other(
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
    
    /// Returns `true` if this playlist item is probably the same as `other` by
    /// comparing the name, artist/show name, and duration.
    func isProbablyTheSameAs(_ other: Self) -> Bool {
        
        // don't return true if both URIs are `nil`.
        if let uri = self.uri, uri == other.uri {
            return true
        }
        
        switch (self, other) {
            case (.track(let track), .track(let otherTrack)):
                return track.isProbablyTheSameAs(otherTrack)
            case (.episode(let episode), .episode(let otherEpisode)):
                return episode.isProbablyTheSameAs(otherEpisode)
            default:
                return false
        }
        
    }
    
}

extension Track {
    
    
    /// Returns `true` if this track is probably the same as `other` by
    /// comparing the name, artist name, and duration.
    func isProbablyTheSameAs(_ other: Self) -> Bool {
        
        if self.name != other.name ||
                self.artists?.first?.name != other.artists?.first?.name {
            return false
        }
        
        switch (self.durationMS, other.durationMS) {
            case (.some(let durationMS), .some(let otherDurationMS)):
                // use a relative tolerance of 10% and an absolute tolerance of
                // ten seconds
                return durationMS.isApproximatelyEqual(
                    to: otherDurationMS,
                    absoluteTolerance: 10_000,  // 10 seconds
                    relativeTolerance: 0.1,
                    norm: { Double($0) }
                )
            case (nil, nil):
                return true
            default:
                return false
        }
        
    }

}

extension Episode {
    
    /// Returns `true` if this episode is probably the same as `other` by
    /// comparing the name, show name, and duration.
    func isProbablyTheSameAs(_ other: Self) -> Bool {
        
        return self.name == other.name &&
                self.show?.name == other.show?.name &&
                // use a relative tolerance of 10% and an absolute tolerance of
                // ten seconds
                self.durationMS.isApproximatelyEqual(
                    to: other.durationMS,
                    absoluteTolerance: 10_000,  // 10 seconds
                    relativeTolerance: 0.1,
                    norm: { Double($0) }
                )
        
    }
    

}
