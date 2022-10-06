# SpotifyAPIExampleApp

An Example App that demonstrates the usage of [SpotifyAPI](https://github.com/Peter-Schorn/SpotifyAPI), a Swift library for the Spotify web API.

Requires Xcode 12 and iOS 14.

**The following was written for the main branch**; differences between it and the other branches may not be reflected here.

## Setup

To compile and run this application, go to https://developer.spotify.com/dashboard/login and create an app. Take note of the client id and client secret. Then click on "edit settings" and add the following redirect URI:
```
spotify-api-example-app://login-callback
```

Next, set the `CLIENT_ID` and `CLIENT_SECRET` [environment variables][env] in the scheme:

![Screen Shot 2021-06-10 at 8 36 45 PM](https://user-images.githubusercontent.com/58197311/121617977-9bba1480-ca2b-11eb-8e9e-f1bfdc2563af.png)


To expirement with this app, add your own views to the `List` in [`ExamplesListView.swift`][examples list].  

## How the Authorization Process Works

**This app uses the [Authorization Code Flow][auth code flow] to authorize with the Spotify web API.**

The first step in setting up the authorization process for an app like this is to [register a URL scheme for your app][url scheme]. To do this, navigate to the Info tab of the target inside your project and add a URL scheme to the URL Types section. For this app, the scheme `spotify-api-example-app` is used.

<img src="https://i.ibb.co/qdBR6C8/Screen-Shot-2020-10-20-at-3-38-06-AM.png" alt="Screen-Shot-2020-10-20-at-3-38-06-AM" border="0">

When another app, such as the web broswer, opens a URL containing this scheme (e.g., `spotify-api-example-app://login-callback`), the URL is delivered to this app to handle it. This is how your app receives redirects from Spotify.

The next step is to create the authorization URL using [`AuthorizationCodeFlowManager.makeAuthorizationURL(redirectURI:showDialog:state:scopes:)`][make auth URL] and then open it in a browser or web view so that the user can login and grant your app access to their Spotify account. In this app, this step is performed by [`Spotify.authorize()`][authorize], which is called when the user [taps the login button][login button] in [`LoginView.swift`][login view]:

<a href="https://ibb.co/Bc7ZYzV"><img src="https://i.ibb.co/17pq4vf/IMG-67-DE87-F2410-C-1.jpg" alt="IMG-67-DE87-F2410-C-1" border="0"></a>

When the user presses "agree" or "cancel", the system redirects back to this app and calls the [`onOpenURL(perform:)`][on open URL] view modifier in [`Rootview.swift`][root view], which calls through to the `handleURL(_:)` method directly below. After validating the URL scheme, this method requests the access and refresh tokens using [`AuthorizationCodeFlowManager.requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`][request tokens], the final step in the authorization process.

When the access and refresh tokens are successfully retrieved, the [`SpotifyAPI.authorizationManagerDidChange`][auth did change publisher] PassthroughSubject emits a signal. This subject is subscribed to in the [init method of `Spotify`][spotify init subscribe]. The subscription calls [`Spotify.authorizationManagerDidChange()`][auth did change method] everytime this subject emits. This method saves the authorization information to persistent storage in the keychain and sets the [`@Published var isAuthorized`][is authorized] property of [`Spotify`][spotify file] to `true`, which dismisses [`LoginView`][login view file] and allows the user to interact with the rest of the app.

A subscription is also made to [`SpotifyAPI.authorizationManagerDidDeauthorize`][did deauth publisher], which emits every time [`AuthorizationCodeFlowManagerBase.deauthorize()`][auth base deauth] is called.

Every time the authorization information changes (e.g., when the access token, which expires after an hour, gets refreshed), [`Spotify.authorizationManagerDidChange()`][auth did change method] is called so that the authorization information in the keychain can be updated.  When the user taps the [`logoutButton`][logout button] in [`Rootview.swift`][root view], [`AuthorizationCodeFlowManagerBase.deauthorize()`][auth base deauth] is called, which causes [`SpotifyAPI.authorizationManagerDidDeauthorize`][did deauth publisher] to emit a signal, which, in turn, causes [`Spotify.authorizationManagerDidDeauthorize()`][did deauth method] to be called.

See [Saving authorization information to persistent storage][persistent storage].

The next time the app is quit and relaunched, the authorization information will be retrieved from the keychain in the [init method of `Spotify`][spotify init keychain], which prevents the user from having to login again.

[env]: https://help.apple.com/xcode/mac/11.4/index.html?localePath=en.lproj#/dev3ec8a1cb4
[examples list]:  https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Views/ExamplesListView.swift
[auth code flow]: https://github.com/Peter-Schorn/SpotifyAPI#authorizing-with-the-authorization-code-flow
[url scheme]: https://developer.apple.com/documentation/xcode/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app
[make auth URL]: https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowbackendmanager/makeauthorizationurl(redirecturi:showdialog:state:scopes:)
[authorize]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L160-L185
[login button]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Views/LoginView.swift#L89
[login view]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Views/LoginView.swift
[on open URL]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Views/RootView.swift#L32
[root view]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Views/RootView.swift
[request tokens]: https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowbackendmanager/requestaccessandrefreshtokens(redirecturiwithquery:state:)

[auth did change publisher]: https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/spotifyapi/authorizationmanagerdidchange
[spotify init subscribe]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L97-L104
[auth did change method]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L187-L235
[is authorized]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L67
[is authorized true]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L208
[persistent storage]:https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/saving-the-authorization-information-to-persistent-storage.
[spotify file]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Model/Spotify.swift
[did deauth method]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L237-L271
[logout button]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Views/RootView.swift#L116-L131
[did deauth publisher]: https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/spotifyapi/authorizationmanagerdiddeauthorize

[auth base deauth]: https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowmanagerbase/deauthorize()
[login view file]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Views/LoginView.swift
[spotify init keychain]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L114

