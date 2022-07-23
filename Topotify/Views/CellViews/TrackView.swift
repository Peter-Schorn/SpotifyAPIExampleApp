import SwiftUI
import Combine
import SpotifyWebAPI

struct TrackView: View {
    
    @EnvironmentObject var spotify: Spotify
    
//    @State private var playRequestCancellable: AnyCancellable? = nil

    @State private var alert: AlertItem? = nil
    
    @State private var image = Image(.spotifyAlbumPlaceholder)

    @State private var didRequestImage = false
    
    
    // MARK: Cancellables
    @State private var loadImageCancellable: AnyCancellable? = nil
    
    let track: Track
    
    var offset: Int?
    
    var body: some View {
        HStack {
            if let offset = offset {
                Text("\(offset+1)")
                    .fontWeight(.bold)
            }
            
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .shadow(color: .secondary, radius: 2, x: 0, y: 0)
                .padding(5)
            
            VStack(alignment: .leading) {
                Text(track.name)
                    .font(.system(.headline))
                Text(track.artists?.first?.name ?? "")
                    .font(.system(.subheadline))
                    .opacity(0.7)
            }
            .lineLimit(1)

            Spacer()
        }
        .onAppear(perform: loadImage)
        .contentShape(Rectangle())
    }
    
    func loadImage() {
        if self.didRequestImage {
            // print("already requested image for '\(playlist.name)'")
            return
        }
        self.didRequestImage = true
        
        guard let spotifyImage = track.album?.images?.largest else {
            // print("no image found for '\(playlist.name)'")
            return
        }
        self.loadImageCancellable = spotifyImage.load()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { image in
                    // print("received image for '\(playlist.name)'")
                    self.image = image
                }
            )
    }
}

struct TrackView_Previews: PreviewProvider {
    
    static let tracks: [Track] = [
        .because, .comeTogether, .faces,
        .illWind, .odeToViceroy, .reckoner,
        .theEnd, .time
    ]

    static var previews: some View {
        List(tracks, id: \.id) { track in
            TrackView(track: track)
        }
        .environmentObject(Spotify())
    }
}
