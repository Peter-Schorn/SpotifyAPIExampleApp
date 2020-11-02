import SwiftUI
import Combine
import SpotifyWebAPI

struct TrackView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var playRequestCancellable: AnyCancellable? = nil

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    let track: Track
    
    var body: some View {
        HStack {
            Text(trackDisplayName())
            Spacer()
        }
        .frame(maxWidth: .infinity)
        // Ensure the hitbox extends across the entire width
        // of the frame. See https://bit.ly/2HqNk4S
        .contentShape(Rectangle())
        .onTapGesture(perform: playTrack)
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
    }
    
    /// The display name for the track.
    /// E.g., "Eclipse - Pink Floyd".
    func trackDisplayName() -> String {
        var displayName = track.name
        if let artistName = track.artists?.first?.name {
            displayName += " - \(artistName)"
        }
        return displayName
    }
    
    func playTrack() {
        
        guard let trackURI = track.uri else {
            self.alertTitle = "Couldn't Play '\(track.name)'"
            self.alertMessage = "missing URI"
            self.alertIsPresented = true
            return
        }
        
        // A request to play a single track.
        let playbackRequest = PlaybackRequest(trackURI)
        
        // By using a single cancellable rather than a collection
        // of cancellables, the previous request always gets
        // cancelled when a new request to play a track is
        // made.
        // self.playRequestCancellable = self.spotify.api.play(playbackRequest)
        self.playRequestCancellable = self.spotify.api.availableDevices()
            .flatMap { devices -> AnyPublisher<Void, Error> in
                
                let deviceId: String
                
                // If there is an actice device, then it's usually a good idea
                // to use that one.
                if let activeDeviceId = devices.first(where: { device in
                    device.isActive && !device.isRestricted && device.id != nil
                })?.id {
                    deviceId = activeDeviceId
                }
                // Else, just use the first device with a non-`nil` `id` and that
                // is not restricted. A restricted device will not accept any web
                // API commands.
                else if let nonActiveDeviceId = devices.first(where: { device in
                    device.id != nil && !device.isRestricted
                })?.id {
                    deviceId = nonActiveDeviceId
                }
                else {
                    return SpotifyLocalError.other("no devices available")
                        .anyFailingPublisher()
                }
                
                return self.spotify.api.play(playbackRequest, deviceId: deviceId)
                
            }
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.alertTitle = "Couldn't Play '\(track.name)'"
                    self.alertMessage = error.localizedDescription
                    self.alertIsPresented = true
                }
            })
        
    }
}

struct TrackView_Previews: PreviewProvider {
    static var previews: some View {
        TrackView(track: .because)
            .environmentObject(Spotify())
            .padding()
    }
}
