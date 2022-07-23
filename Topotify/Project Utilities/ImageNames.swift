import Foundation
import SwiftUI

/// The names of the image assets.
enum ImageName: String {
    
    case spotifyLogoGreen = "spotify logo green"
    case spotifyLogoWhite = "spotify logo white"
    case spotifyLogoBlack = "spotify logo black"
    case spotifyAlbumPlaceholder = "spotify album placeholder"
}

extension Image {
    
    /// Creates an image using `ImageName`, an enum which contains the names of
    /// all the image assets.
    init(_ name: ImageName) {
        self.init(name.rawValue)
    }
    
}

extension UIImage {
    
    /// Creates an image using `ImageName`, an enum which contains the names of
    /// all the image assets.
    convenience init?(_ name: ImageName) {
        self.init(named: name.rawValue)
    }
    
}

