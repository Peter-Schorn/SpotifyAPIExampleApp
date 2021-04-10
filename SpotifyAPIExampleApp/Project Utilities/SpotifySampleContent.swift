import Foundation
import SpotifyWebAPI
import UIKit

extension SpotifyUser {
    
    static let nicholas = decodeAsset(
        name: "Nicholas User Profile",
        type: Self.self
    )
    
    static let april = decodeAsset(
        name: "April User Profile",
        type: Self.self
    )
    
    static let allSampleUsers: [Self] = [
        .sampleCurrentUserProfile,
        .nicholas,
        .april
    ]

}

private func decodeAsset<T: Decodable>(name: String, type: T.Type) -> T {
    let asset = NSDataAsset(name: name)!
    return try! JSONDecoder().decode(type, from: asset.data)
}
