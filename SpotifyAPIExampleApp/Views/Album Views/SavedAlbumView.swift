import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent

struct SavedAlbumView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    /// The cover image for the album.
    @State private var image = Image(.spotifyAlbumPlaceholder)
    
    @State private var loadImageCancellable: AnyCancellable? = nil
    @State private var didRequestImage = false
    
    var album: Album
    
    var body: some View {
        NavigationLink(
            destination: AlbumTracksView(album: album, image: image)
        ) {
            VStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(5)
                Text(album.name)
                    .font(.callout)
                    .lineLimit(3)
                    // This is necessary to ensure that the text wraps
                    // to the next line if it is too long.
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .onAppear(perform: loadImage)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func loadImage() {
    
        // Return early if the image has already been requested.
        // We can't just check if `self.image == nil` because the image
        // might have already been requested, but not loaded yet.
        if self.didRequestImage { return }
        self.didRequestImage = true
    
        guard let spotifyImage = album.images?.largest else {
            return
        }
    
        print("loading image for '\(album.name)'")
    
        // Note that a `Set<AnyCancellable>` is NOT being used
        // so that each time a request to load the image is made,
        // the previous cancellable assigned to `loadImageCancellable`
        // is deallocated, which cancels the publisher.
        self.loadImageCancellable = spotifyImage.load()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { image in
                    self.image = image
                }
            )
    }


}

struct SavedAlbumView_Previews: PreviewProvider {

    static let spotify = Spotify()

    static var previews: some View {
        SavedAlbumView(album: .jinx)
            .environmentObject(spotify)
    }
}
