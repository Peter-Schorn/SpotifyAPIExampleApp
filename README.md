# SpotifyAPIExampleApp
An Example App that demonstrates the usage of [SpotifyAPI](https://github.com/Peter-Schorn/SpotifyAPI), a Swift library for the Spotify web API.

Requires Xcode 12 and iOS 14.

## Setup

To compile this application, go to https://developer.spotify.com/dashboard/login and create an app. Take note of the client id and client secret. Then click on "edit settings" and add the following redirect URI:
```
spotify-api-example-app://login-callback
```

Next, add `client_id` and `client_secret` to the [environment variables][1] for your scheme:
<a href="https://ibb.co/NxKXZfR"><img src="https://i.ibb.co/v1kbZf9/Screen-Shot-2020-09-20-at-12-43-11-AM.png" alt="Screen-Shot-2020-09-20-at-12-43-11-AM" border="0"></a>

## How the Authorization Process Works

**This app uses the [Authorization Code Flow][2] to authorize with the Spotify web API.**

The first step in setting up the authorization process for an app like this is to [register a URL scheme for your app][3]. To do this, navigate to the Info tab of the target inside your project and add a URL scheme to the URL Types section. For this app, the scheme `spotify-api-example-app` is used.

<img src="https://i.ibb.co/qdBR6C8/Screen-Shot-2020-10-20-at-3-38-06-AM.png" alt="Screen-Shot-2020-10-20-at-3-38-06-AM" border="0">

When another app, such as the web broswer, opens a URL containing this scheme (e.g., `spotify-api-example-app://login-callback`), the URL is delivered to this app to handle it. This is how your app receives redirects from Spotify.

The next step is to create the authorization URL using `AuthorizationCodeFlowManager.makeAuthorizationURL(redirectURI:showDialog:state:scopes:)` and then open it in a browser or web view so that the user can login and grant your app access to their Spotify account. In this app, this step is performed by [`Spotify.authorize()`][4], which is called when the user [taps the login button][5] in `LoginView.swift`:

<a href="https://ibb.co/Bc7ZYzV"><img src="https://i.ibb.co/17pq4vf/IMG-67-DE87-F2410-C-1.jpg" alt="IMG-67-DE87-F2410-C-1" border="0"></a>

When the user presses "agree" or "cancel", the system redirects back to this app and calls the [`onOpenURL(perform:)`][6] view modifier in `Rootview.swift`, which calls through to the `handleURL(_:)` method directly below. After validating the URL scheme, this method requests the access and refresh tokens using `AuthorizationCodeFlowManager.requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`, the final step in the authorization process.

When the access and refresh tokens are successfully retrieved, the `SpotifyAPI.authorizationManagerDidChange` `PassthroughSubject` emits a signal. This subject is subscribed to in the [init method of `Spotify`][7]. The subscription calls [`Spotify.handleChangesToAuthorizationManager()`][8] everytime this subject emits. This method saves the authorization information to persistent storage in the keychain and updates the `@Published var isAuthorized` property of `Spotify`. Assuming the access and refresh tokens have been successfully retrieved, `Spotify.isAuthorized` is set to `true`, which dismisses `LoginView` and allows the user to interact with the rest of the app.

Every time the authorization information changes (e.g., when the access token, which expires after an hour, gets refreshed), `Spotify.handleChangesToAuthorizationManager()` is called so that the authorization information in the keychain can be updated. See the wiki page [Saving authorization information to persistent storage][9].

The next time the app is quit and relaunched, the authorization information will be retrieved from the keychain in the init method of `Spotify`, which prevents the user from having to login each time the app is quit and relaunched.

[1]: https://help.apple.com/xcode/mac/11.4/index.html?localePath=en.lproj#/dev3ec8a1cb4
[2]: https://github.com/Peter-Schorn/SpotifyAPI#authorizing-with-the-authorization-code-flow
[3]: https://developer.apple.com/documentation/xcode/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app
[4]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/d6996e798fb2ef96d732298572c3ad6c81569172/SpotifyAPIExampleApp/Model/Spotify.swift#L127-L150
[5]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/d6996e798fb2ef96d732298572c3ad6c81569172/SpotifyAPIExampleApp/Views/LoginView.swift#L87
[6]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/d6996e798fb2ef96d732298572c3ad6c81569172/SpotifyAPIExampleApp/Views/RootView.swift#L39
[7]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/d6996e798fb2ef96d732298572c3ad6c81569172/SpotifyAPIExampleApp/Model/Spotify.swift#L68-L75
[8]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/d6996e798fb2ef96d732298572c3ad6c81569172/SpotifyAPIExampleApp/Model/Spotify.swift#L164
[9]: https://github.com/Peter-Schorn/SpotifyAPI/wiki/Saving-authorization-information-to-persistent-storage.
