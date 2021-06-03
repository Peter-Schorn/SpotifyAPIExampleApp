import SwiftUI
import Combine

/**
 A view that presents a button to login with Spotify.
 
 It is presented when `isAuthorized` is `false`.
 
 When the user taps the button, the authorization URL is opened in the browser,
 which prompts them to login with their Spotify account and authorize this
 application.
 
 After Spotify redirects back to this app and the access and refresh
 tokens have been retrieved, dismiss this view by setting `isAuthorized`
 to `true`.
 */
struct LoginView: ViewModifier {

    /// Always show this view for debugging purposes.
    /// Most importantly, this is useful for the preview provider.
    fileprivate static var debugAlwaysShowing = false
    
    /// The animation that should be used for presenting and
    /// dismissing this view.
    static let animation = Animation.spring()
    
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var spotify: Spotify

    /// After the app first launches, add a short delay before showing this
    /// view so that the animation can be seen.
    @State private var finishedViewLoadDelay = false
    
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
            .blur(
                radius: spotify.isAuthorized && !Self.debugAlwaysShowing ? 0 : 3
            )
            .overlay(
                ZStack {
                    if !spotify.isAuthorized || Self.debugAlwaysShowing {
                        Color.black.opacity(0.25)
                            .edgesIgnoringSafeArea(.all)
                        if self.finishedViewLoadDelay || Self.debugAlwaysShowing {
                            loginView
                        }
                    }
                }
            )
            .onAppear {
                // After the app first launches, add a short delay before
                // showing this view so that the animation can be seen.
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
            .overlay(retrievingTokensView)
            .shadow(radius: 5)
            .transition(
                AnyTransition.scale(scale: 1.2)
                    .combined(with: .opacity)
            )
    }
    
    var spotifyButton: some View {

        Button(action: spotify.authorize) {
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
        }
        .accessibility(identifier: "Log in with Spotify Identifier")
        .buttonStyle(PlainButtonStyle())
        // Prevent the user from trying to login again
        // if a request to retrieve the access and refresh
        // tokens is currently in progress.
        .allowsHitTesting(!spotify.isRetrievingTokens)
        .padding(.bottom, 5)
        
    }
    
    var retrievingTokensView: some View {
        VStack {
            Spacer()
            if spotify.isRetrievingTokens {
                HStack {
                    ProgressView()
                        .padding()
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
        spotify.isRetrievingTokens = true
        LoginView.debugAlwaysShowing = true
    }

}
