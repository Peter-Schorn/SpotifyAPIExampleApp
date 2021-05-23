import Foundation
import SwiftUI
import SpotifyWebAPI

extension View {
    
    /// Type erases self to `AnyView`. Equivalent to `AnyView(self)`.
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }

}

extension ProcessInfo {
    
    /// Whether or not this process is running within the context of
    /// a SwiftUI preview.
    var isPreviewing: Bool {
        return self.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

}

extension Scope {
    
    /**
     Creates a set of scopes from an instance of `SPTScope`.
     
     Does not support `userReadBirthDate`.

     - Parameter sptScope: The scopes.
     */
    static func fromSPTScope(_ sptScope: SPTScope) -> Set<Scope> {
        return sptScope.elements.reduce(into: []) { scopes, scope in
            switch scope {
                case .playlistReadPrivate:
                    scopes.insert(playlistReadPrivate)
                case .playlistReadCollaborative:
                    scopes.insert(playlistReadCollaborative)
                case .playlistModifyPublic:
                    scopes.insert(.playlistModifyPublic)
                case .playlistModifyPrivate:
                    scopes.insert(.playlistModifyPrivate)
                case .userFollowRead:
                    scopes.insert(.userFollowRead)
                case .userFollowModify:
                    scopes.insert(.userFollowModify)
                case .userLibraryRead:
                    scopes.insert(.userLibraryRead)
                case .userLibraryModify:
                    scopes.insert(.userLibraryModify)
                case .userReadBirthDate:
                    break  // not supported by the Spotify web API
                case .userReadEmail:
                    scopes.insert(.userReadEmail)
                case .userReadPrivate:
                    scopes.insert(.userReadPrivate)
                case .userTopRead:
                    scopes.insert(.userTopRead)
                case .ugcImageUpload:
                    scopes.insert(.ugcImageUpload)
                case .streaming:
                    scopes.insert(.streaming)
                case .appRemoteControl:
                    scopes.insert(.appRemoteControl)
                case .userReadPlaybackState:
                    scopes.insert(.userReadPlaybackState)
                case .userModifyPlaybackState:
                    scopes.insert(.userModifyPlaybackState)
                case .userReadCurrentlyPlaying:
                    scopes.insert(.userReadCurrentlyPlaying)
                case .userReadRecentlyPlayed:
                    scopes.insert(.userReadRecentlyPlayed)
                default:
                    break
            }
        }
    }

}

extension OptionSet where RawValue: FixedWidthInteger {
    
    /// All of the elements in this option set. [Source][1].
    ///
    /// [1]: https://stackoverflow.com/a/32103136/12394554
    var elements: AnySequence<Self> {
        var remainingBits = self.rawValue
        var bitMask: RawValue = 1
        return AnySequence {
            return AnyIterator {
                while remainingBits != 0 {
                    defer { bitMask = bitMask &* 2 }
                    if remainingBits & bitMask != 0 {
                        remainingBits = remainingBits & ~bitMask
                        return Self(rawValue: bitMask)
                    }
                }
                return nil
            }
        }
    }
}

extension SPTError {
    
    var underlyingErrorLocalizedDescription: String {
        (self.userInfo[NSUnderlyingErrorKey] as? Error)?.localizedDescription
            ?? self.localizedDescription
    }
    
}

public struct VaporServerError: Error, Codable {
    
    /// The reason for the error.
    public let reason: String
    
    /// Always set to `true` to indicate that the JSON payload represents an
    /// error response.
    public let error: Bool
}

extension VaporServerError: CustomStringConvertible {
    public var description: String {
        return """
            \(Self.self)(reason: "\(self.reason)")
            """
    }
}

extension VaporServerError {
    
    public static func decodeFromNetworkResponse(
        data: Data, response: HTTPURLResponse
    ) -> Error? {
        
        guard response.statusCode == 400 else {
            return nil
        }
        
        return try? JSONDecoder().decode(
            Self.self, from: data
        )
        
    }
    
}
