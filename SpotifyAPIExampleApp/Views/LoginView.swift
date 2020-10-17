import SwiftUI
import Combine

struct LoginView: ViewModifier {

    /// Always show this view for debugging purposes.
    fileprivate static var debugAlwaysShowing = false
    
    /// The animation that should be used for
    /// presenting and dismissing this view.
    static let animation = Animation.spring()
    
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var spotify: Spotify

    /// After the app first launches, add a short delay before showing this
    /// view so that the animation can be seen.
    @State private var finishedViewLoadDelay = false
    
    @Binding var isRetrievingTokens: Bool
    
    let backgroundGradient = LinearGradient(
        gradient: Gradient(
            colors: [Color(#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)), Color(#colorLiteral(red: 0.1903857588, green: 0.8321116255, blue: 0.4365008013, alpha: 1))]
        ),
        startPoint: .leading, endPoint: .trailing
    )
    
    var spotifyLogo: ImageName {
        colorScheme == .dark ? .spotifyLogoWhite
                : .spotifyLogoBlack
    }
    
    func body(content: Content) -> some View {
        content
            .blur(radius: spotify.isAuthorized ? 0 : 3)
            .overlay(
                ZStack {
                    if !spotify.isAuthorized || Self.debugAlwaysShowing {
                        Color.black.opacity(0.25)
                            .edgesIgnoringSafeArea(.all)
                        if finishedViewLoadDelay || Self.debugAlwaysShowing {
                            loginView
                        }
                    }
                }
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(LoginView.animation) {
                        self.finishedViewLoadDelay = true
                    }
                }
            }
    }
    
    var loginView: some View {
        spotifyButton
            .padding()
            .padding(.vertical, 50)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
            .overlay(authenticatingView)
            .shadow(radius: 5)
            .transition(
                AnyTransition.scale(scale: 1.2)
                    .combined(with: .opacity)
            )
    }
    
    var spotifyButton: some View {
        HStack {
            Image(spotifyLogo)
                .interpolation(.high)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 40)
            Text("Log in with Spotify")
                .font(.title)
        }
        .padding()
        .background(backgroundGradient)
        .clipShape(Capsule())
        .shadow(radius: 5)
        // MARK: Authorize The Application
        .onTapGesture(perform: self.spotify.authorize)
    }
    
    var authenticatingView: some View {
        VStack {
            Spacer()
            if self.isRetrievingTokens {
                HStack {
                    ActivityIndicator(
                        isAnimating: .constant(true),
                        style: .medium
                    )
                    Text("Authenticating")
                }
                .padding(.bottom, 20)
            }
        }
    }
    
}

struct LoginView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    
    static var previews: some View {
        RootView()
            .environmentObject(spotify)
            .onAppear(perform: onAppear)
    }
    
    static func onAppear() {
        spotify.isAuthorized = false
        LoginView.debugAlwaysShowing = true
    }

}
