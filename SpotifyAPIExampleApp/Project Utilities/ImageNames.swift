import Foundation
import SwiftUI

enum ImageName: String {
    
    case spotifyLogoGreen = "spotify logo green"
    case spotifyLogoWhite = "spotify logo white"
    case spotifyLogoBlack = "spotify logo black"
    case spotifyAlbumPlaceholder = "spotify album placeholder"
    case annabelle
    case hubble
}

extension Image {
    
    init(_ name: ImageName) {
        self.init(name.rawValue)
    }
    
}

extension UIImage {
    
    convenience init?(_ name: ImageName) {
        self.init(named: name.rawValue)
    }
    
}
