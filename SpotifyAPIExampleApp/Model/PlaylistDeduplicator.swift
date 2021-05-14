import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

/// Encapsulates the logic for removing duplicates from a playlist.
class PlaylistDeduplicator: ObservableObject {
    
    @Published var isDeduplicating = false
    
    /// The total number of tracks/episodes in the playlist.
    @Published var totalItems: Int

    let spotify: Spotify

    let playlist: Playlist<PlaylistItemsReference>

    let alertPublisher = PassthroughSubject<AlertItem, Never>()

    private var seenPlaylists: Set<PlaylistItem> = []
    
    /// The uri of an item in the playlist, along with its position in
    /// the playlist.
    private var duplicates: [(uri: SpotifyURIConvertible, position: Int)] = []

    private var cancellables: Set<AnyCancellable> = []

    init(spotify: Spotify, playlist: Playlist<PlaylistItemsReference>) {
        self.spotify = spotify
        self.playlist = playlist
        self._totalItems = Published(initialValue: playlist.items.total)
    }

    /// Find the duplicates in the playlist.
    func findAndRemoveDuplicates() {
        
        self.isDeduplicating = true
        
        self.seenPlaylists = []
        self.duplicates = []
        
        self.spotify.api.playlistItems(playlist.uri)
            .extendPagesConcurrently(self.spotify.api)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    print("received completion:", completion)
                    switch completion {
                        case .finished:
                            // We've finished finding the duplicates;
                            // now we need to remove them if there are any.
                            if self.duplicates.isEmpty {
                                self.isDeduplicating = false
                                self.alertPublisher.send(.init(
                                    title: "\(self.playlist.name) does not " +
                                        "have any duplicates",
                                    message: ""
                                ))
                                return
                            }
                            self.removeDuplicates()
                        case .failure(let error):
                            print("couldn't check for duplicates:\n\(error)")
                            self.isDeduplicating = false
                            self.alertPublisher.send(.init(
                                title: "Couldn't check for duplicates for " +
                                    "\(self.playlist.name)",
                                message: error.localizedDescription
                            ))
                    }
                },
                receiveValue: { playlistItemsPage in
                    self.receivePlaylistItemsPage(
                        page: playlistItemsPage
                    )
                }
            )
            .store(in: &cancellables)
                
    }
    
    func receivePlaylistItemsPage(page: PlaylistItems) {
        
        print("received page at offset \(page.offset)")
        
        let playlistItems = page.items
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
            
            for seenPlaylist in self.seenPlaylists {
                guard let uri = playlistItem.uri else {
                    continue
                }
                
                if playlistItem.isProbablyTheSameAs(seenPlaylist) {
                    // To determine the actual index of the item in the
                    // playlist, we must take into account the offset of
                    // the current page
                    let playlistIndex = index + page.offset
                    self.duplicates.append(
                        (uri: uri, position: playlistIndex)
                    )
                }
            }
            self.seenPlaylists.insert(playlistItem)

        }

    }
    
    /// Remove the duplicates in the playlist.
    func removeDuplicates() {
        
        DispatchQueue.global().async {
            
            print(
                "will remove \(self.duplicates.count) duplicates " +
                    "for \(self.playlist.name)"
            )
            
            let urisWithPositionsContainers = URIsWithPositionsContainer.chunked(
                urisWithSinglePosition: self.duplicates
            )
            
            var receivedError = false
            
            let semaphore = DispatchSemaphore(value: 0)
            
            for (index, container) in urisWithPositionsContainers.enumerated() {
                
                self.spotify.api.removeSpecificOccurrencesFromPlaylist(
                    self.playlist.uri, of: container
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
                                    self.isDeduplicating = false
                                    self.alertPublisher.send(.init(
                                        title: "Couldn't Remove Duplicates from " +
                                            "\(self.playlist.name)",
                                        message: error.localizedDescription
                                    ))
                                }
                                receivedError = true
                                semaphore.signal()
                                // Do not try to remove any more duplicates
                                // from the playlist if we get an error because
                                // the indices of the items may be invalid.
                                break
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &self.cancellables)
                
                semaphore.wait()
                
            }
            
            if receivedError { return }
            
            print("finished removing duplicates from playlist")
            
            DispatchQueue.main.async {
                self.isDeduplicating = false
                // Update the number of items in the playlist by subtracting
                //             the duplicates that were removed.
                self.totalItems = self.playlist.items.total - self.duplicates.count
                self.alertPublisher.send(.init(
                    title: "Removed \(self.duplicates.count) duplicates from " +
                        "\(self.playlist.name)",
                    message: ""
                ))
            }
            
        }
        
    }

}
