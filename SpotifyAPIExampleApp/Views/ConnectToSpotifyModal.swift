import Foundation
import SwiftUI

struct ConnectToSpotifyModal: ViewModifier {
    
    /// Always show this view for debugging purposes.
    /// Most importantly, this is useful for the preview
    /// provider.
    fileprivate static var debugAlwaysShowing = false
    
    /// The animation that should be used for presenting and
    /// dismissing this view.
    static let animation = Animation.spring()

    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var spotify: Spotify

    @State private var isPresented = false

    let action: () -> Void

    let backgroundGradient = LinearGradient(
        gradient: Gradient(
            colors: [Color(#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)), Color(#colorLiteral(red: 0.1903857588, green: 0.8321116255, blue: 0.4365008013, alpha: 1))]
        ),
        startPoint: .leading, endPoint: .trailing
    )

    var spotifyImage: ImageName {
        colorScheme == .dark ? .spotifyLogoWhite :
                .spotifyLogoBlack
    }

    func body(content: Content) -> some View {
        
        ZStack {
            
            content
                .blur(radius: isPresented ? 3 : 0)
            
            if isPresented {
                Group {
                    Color.black.opacity(0.25)
                        .edgesIgnoringSafeArea(.all)
                    mainView
                }
                .transition(
                    AnyTransition.scale(scale: 1.2)
                        .combined(with: .opacity)
                )
                .animation(Self.animation)
            }

        }
        .onReceive(spotify.$appRemoteIsConnected) { isConnected in
            withAnimation {
                if Self.debugAlwaysShowing {
                    self.isPresented = true
                }
                else {
                    self.isPresented = !isConnected
                }
            }
        }

    }
    
    var mainView: some View {
        Button(action: action) {
            HStack {
                Image(spotifyImage)
                    .resizable()
                    .frame(width: 40, height: 40)
                Text("Connect To Spotify")
                    .font(.title)
            }
            .padding(10)
            .background(backgroundGradient)
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
        .padding(.vertical, 50)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(radius: 5)
    }
    
}

struct ConntectToSpotifyModal_Previews: PreviewProvider {
    
    static var previews: some View {
//        Color.white
        PlayerControlsView()
            .modifier(ConnectToSpotifyModal(action: { }))
            .environmentObject(Spotify())
    }
    
    static func onAppear() {
        ConnectToSpotifyModal.debugAlwaysShowing = false
    }

}
