import Foundation
import SwiftUI
import SpotifyWebAPI

extension Sequence {
    
    /// Creates an array of tuples in which the first item
    /// is the index of the element and the second is the element.
    func enumeratedArray() -> [(index: Int, element: Element)] {
        
        return self.enumerated().map { item in
            (index: item.0, element: item.1)
        }
        
    }
    
}

extension View {
    
    /// Type erases self to `AnyView`. Equivalent to `AnyView(self)`.
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }

}

extension PlaylistItem {
    
    /// Returns `true` if this playlist item is probably the same as
    /// `other` by comparing the name and artist/show name.
    func isProbablyTheSameAs(_ other: Self) -> Bool {
        
        if let uri = self.uri, let otherURI = other.uri {
            return uri == otherURI
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
