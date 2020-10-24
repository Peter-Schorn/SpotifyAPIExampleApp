# SpotifyAPIExampleApp

An Example App that demonstrates the usage of [SpotifyAPI](https://github.com/Peter-Schorn/SpotifyAPI), a Swift library for the Spotify web API.

Requires Xcode 12 and iOS 14.

## Setup

To compile and run this application, go to https://developer.spotify.com/dashboard/login and create an app. Take note of the client id and client secret. Then click on "edit settings" and add the following redirect URI:
```
spotify-api-example-app://login-callback
```

Next, add `client_id` and `client_secret` to the [environment variables][1] for your scheme:

<a href="https://ibb.co/sy3ZtCq"><img src="https://i.ibb.co/dGKR7tD/Screen-Shot-2020-10-22-at-7-31-41-PM.png" alt="Screen-Shot-2020-10-22-at-7-31-41-PM" border="0"></a>



To expirement with this app, add your own views to the `List` in [`ExamplesListView.swift`][2].  



## How the Authorization Process Works

**This app uses the [Authorization Code Flow][3] to authorize with the Spotify web API.**

The first step in setting up the authorization process for an app like this is to [register a URL scheme for your app][4]. To do this, navigate to the Info tab of the target inside your project and add a URL scheme to the URL Types section. For this app, the scheme `spotify-api-example-app` is used.

<img src="https://i.ibb.co/qdBR6C8/Screen-Shot-2020-10-20-at-3-38-06-AM.png" alt="Screen-Shot-2020-10-20-at-3-38-06-AM" border="0">

When another app, such as the web broswer, opens a URL containing this scheme (e.g., `spotify-api-example-app://login-callback`), the URL is delivered to this app to handle it. This is how your app receives redirects from Spotify.

The next step is to create the authorization URL using [`AuthorizationCodeFlowManager.makeAuthorizationURL(redirectURI:showDialog:state:scopes:)`][5] and then open it in a browser or web view so that the user can login and grant your app access to their Spotify account. In this app, this step is performed by [`Spotify.authorize()`][6], which is called when the user [taps the login button][7] in [`LoginView.swift`][8]:

<a href="https://ibb.co/Bc7ZYzV"><img src="https://i.ibb.co/17pq4vf/IMG-67-DE87-F2410-C-1.jpg" alt="IMG-67-DE87-F2410-C-1" border="0"></a>

When the user presses "agree" or "cancel", the system redirects back to this app and calls the [`onOpenURL(perform:)`][9] view modifier in [`Rootview.swift`][10], which calls through to the `handleURL(_:)` method directly below. After validating the URL scheme, this method requests the access and refresh tokens using [`AuthorizationCodeFlowManager.requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`][11], the final step in the authorization process.

When the access and refresh tokens are successfully retrieved, the [`SpotifyAPI.authorizationManagerDidChange`][12] PassthroughSubject emits a signal. This subject is subscribed to in the [init method of `Spotify`][13]. The subscription calls [`Spotify.handleChangesToAuthorizationManager()`][14] everytime this subject emits. This method saves the authorization information to persistent storage in the keychain and updates the [`@Published var isAuthorized`][15] property of `Spotify`. Assuming the access and refresh tokens have been successfully retrieved, [`Spotify.isAuthorized` is set to `true`][16], which dismisses `LoginView` and allows the user to interact with the rest of the app.

Every time the authorization information changes (e.g., when the access token, which expires after an hour, gets refreshed), [`Spotify.handleChangesToAuthorizationManager()`][14] is called so that the authorization information in the keychain can be updated. See the wiki page [Saving authorization information to persistent storage][17].

The next time the app is quit and relaunched, the authorization information will be retrieved from the keychain in the [init method of `Spotify`][18], which prevents the user from having to login again.

[1]: https://help.apple.com/xcode/mac/11.4/index.html?localePath=en.lproj#/dev3ec8a1cb4
[2]:  https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Views/ExamplesListView.swift
[3]: https://github.com/Peter-Schorn/SpotifyAPI#authorizing-with-the-authorization-code-flow
[4]: https://developer.apple.com/documentation/xcode/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app
[5]: https://peter-schorn.github.io/SpotifyAPI/Classes/AuthorizationCodeFlowManager.html#/s:13SpotifyWebAPI28AuthorizationCodeFlowManagerC04makeD3URL11redirectURI10showDialog5state6scopes10Foundation0I0VSgAK_SbSSSgShyAA5ScopeOGtF
[6]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/776073178343533b88a5718786bc35851701b4ff/SpotifyAPIExampleApp/Model/Spotify.swift#L140-L163
[7]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/776073178343533b88a5718786bc35851701b4ff/SpotifyAPIExampleApp/Views/LoginView.swift#L108
[8]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Views/LoginView.swift
[9]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/776073178343533b88a5718786bc35851701b4ff/SpotifyAPIExampleApp/Views/RootView.swift#L47
[10]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Views/RootView.swift
[11]: https://peter-schorn.github.io/SpotifyAPI/Classes/AuthorizationCodeFlowManager.html#/s:13SpotifyWebAPI28AuthorizationCodeFlowManagerC29requestAccessAndRefreshTokens20redirectURIWithQuery5state7Combine12AnyPublisherVyyts5Error_pG10Foundation3URLV_SSSgtF
[12]: https://peter-schorn.github.io/SpotifyAPI/Classes/SpotifyAPI.html#/s:13SpotifyWebAPI0aC0C29authorizationManagerDidChange7Combine18PassthroughSubjectCyyts5NeverOGvp
[13]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/776073178343533b88a5718786bc35851701b4ff/SpotifyAPIExampleApp/Model/Spotify.swift#L85-L90
[14]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/776073178343533b88a5718786bc35851701b4ff/SpotifyAPIExampleApp/Model/Spotify.swift#L179-L207
[15]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/776073178343533b88a5718786bc35851701b4ff/SpotifyAPIExampleApp/Model/Spotify.swift#L62
[16]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/776073178343533b88a5718786bc35851701b4ff/SpotifyAPIExampleApp/Model/Spotify.swift#L185
[17]: https://github.com/Peter-Schorn/SpotifyAPI/wiki/Saving-authorization-information-to-persistent-storage.
[18]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/776073178343533b88a5718786bc35851701b4ff/SpotifyAPIExampleApp/Model/Spotify.swift#L92-L126

