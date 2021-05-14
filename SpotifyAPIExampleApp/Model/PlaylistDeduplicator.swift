import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

/// Encapsulates the logic for removing duplicates from a playlist.
class PlaylistDeduplicator: ObservableObject {
    
    @Published var isDeduplicating = false
    
    /// The total number of tracks/episodes in the playlist.
    @Published var totalItems: Int

    let playlist: Playlist<PlaylistItemsReference>

    let alertPublisher = PassthroughSubject<AlertItem, Never>()

    private var cancellables: Set<AnyCancellable> = []

    init(playlist: Playlist<PlaylistItemsReference>) {
        self.playlist = playlist
        self._totalItems = Published(initialValue: playlist.items.total)
    }

    /// Find the duplicates in the playlist.
    func findAndRemoveDuplicates(spotify: Spotify) {
        
        self.isDeduplicating = true
        
        var seenPlaylists: Set<PlaylistItem> = []
        
        // The uri of an item in the playlist, along with its position in
        // the playlist.
        var duplicates: [(uri: SpotifyURIConvertible, position: Int)] = []
        
        spotify.api.playlistItems(playlist.uri)
            .extendPages(spotify.api)
            .sink(
                receiveCompletion: { completion in
                    print("received compltion:", completion)
                    switch completion {
                        case .finished:
                            // We've finished finding the duplicates;
                            // now we need to remove them if there are any.
                            if duplicates.isEmpty {
                                DispatchQueue.main.async {
                                    self.isDeduplicating = false
                                    self.alertPublisher.send(.init(
                                        title: "\(self.playlist.name) does not " +
                                               "have any duplicates",
                                        message: ""
                                    ))
                                }
                                return
                            }
                            DispatchQueue.global().async {
                                self.removeDuplicates(spotify: spotify, duplicates)
                            }
                        case .failure(let error):
                            print("couldn't check for duplicates:\n\(error)")
                            DispatchQueue.main.async {
                                self.isDeduplicating = false
                                self.alertPublisher.send(.init(
                                    title: "Couldn't check for duplicates for " +
                                           "\(self.playlist.name)",
                                    message: error.localizedDescription
                                ))
                            }
                    }
                },
                receiveValue: { playlistItemsPage in
                    print("received page at offset \(playlistItemsPage.offset)")
                    
                    let playlistItems = playlistItemsPage.items
                        .map(\.item)
                        .enumerated()
                    
                    for (index, playlistItem) in playlistItems {
                        
                        guard let playlistItem = playlistItem else {
                            continue
                        }
                        
                        // skip local tracks
                        if case .track(let track) = playlistItem {
                            if track.isLocal { continue }
                        }
                        
                        for seenPlaylist in seenPlaylists {
                            guard let uri = playlistItem.uri else {
                                continue
                            }
                            
                            if playlistItem.isProbablyTheSameAs(seenPlaylist) {
                                // To determine the actual index of the item in the
                                // playlist, we must take into account the offset of
                                // the current page
                                let playlistIndex = index + playlistItemsPage.offset
                                duplicates.append(
                                    (uri: uri, position: playlistIndex)
                                )
                            }
                        }
                        seenPlaylists.insert(playlistItem)

                    }
                    

                }
            )
            .store(in: &cancellables)
                
    }
    
    /// Remove the duplicates in the playlist.
    func removeDuplicates(
        spotify: Spotify,
        _ duplicates: [(uri: SpotifyURIConvertible, position: Int)]
    ) {
        
        print("will remove \(duplicates.count) duplicates for \(playlist.name)")
        
        let urisWithPositionsContainers = URIsWithPositionsContainer.chunked(
            urisWithSinglePosition: duplicates
        )
        
        let semaphore = DispatchSemaphore(value: 0)
        for (index, container) in urisWithPositionsContainers.enumerated() {
            spotify.api.removeSpecificOccurrencesFromPlaylist(
                playlist.uri, of: container
            )
            .sink(
                receiveCompletion: { completion in
                    print("completion for request \(index): \(completion)")
                    switch completion {
                        case .finished:
                            semaphore.signal()
                        case .failure(let error):
                            print(
                                "\(index): couldn't remove duplicates\n\(error)"
                            )
                            DispatchQueue.main.async {
                                self.alertPublisher.send(.init(
                                    title: "Couldn't Remove Duplicates from " +
                                           "\(self.playlist.name)",
                                    message: error.localizedDescription
                                ))
                            }
                            // Do not try to remove any more duplicates
                            // from the playlist if we get an error because
                            // the indices of the items may be invalid.
                            break
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
            
            semaphore.wait()
            
        }
        print("finished removing duplicates from playlist")
        DispatchQueue.main.async {
            self.isDeduplicating = false
            // Update the number of items in the playlist by subtracting
//             the duplicates that were removed.
            self.totalItems = self.playlist.items.total - duplicates.count
            self.alertPublisher.send(.init(
                title: "Removed \(duplicates.count) duplicates from " +
                       "\(self.playlist.name)",
                message: ""
            ))
        }

    }

}
