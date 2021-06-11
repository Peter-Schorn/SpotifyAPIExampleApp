# SpotifyAPIExampleApp

An Example App that demonstrates the usage of [SpotifyAPI](https://github.com/Peter-Schorn/SpotifyAPI), a Swift library for the Spotify web API.

Requires Xcode 12 and iOS 14.

## Setup

To compile and run this application, go to https://developer.spotify.com/dashboard/login and create an app. Take note of the client id and client secret. Then click on "edit settings" and add the following redirect URI:
```
peter-schorn-spotify-sdk-app://app-remote-callback
```

Then, add the bundle id of this app to the "Bundle IDs" section at the bottom of the settings (your bundle id may be different):

![screenshot](https://user-images.githubusercontent.com/58197311/121619018-74fcdd80-ca2d-11eb-84bf-d9de290caaec.jpg)

This app requires a custom backend server that retrieves the authorization information on behalf of your app. It must have an endpoint that swaps the authorization code for the access and refresh tokens (`TOKENS_URL`) and an endpoint that uses the refresh token to get a new access token (`TOKENS_REFRESH_URL`), as described in [Token Swap and Refresh][token swap]. You can use the `/authorization-code-flow/retrieve-tokens` and ` /authorization-code-flow/refresh-tokens` endpoints of [SpotifyAPIServer][spotify api server], respectively, for this functionality. This server can be deployed to heroku in one click.

Next, set the `CLIENT_ID` , `TOKENS_URL`, and `TOKENS_REFRESH_URL` [environment variables][env] in the scheme:

![Screen Shot 2021-06-10 at 9 18 52 PM](https://user-images.githubusercontent.com/58197311/121621267-77f9cd00-ca31-11eb-9140-b911ab048da1.png)


To expirement with this app, add your own views to the `List` in [`ExamplesListView.swift`][examples list].  

[env]: https://help.apple.com/xcode/mac/11.4/index.html?localePath=en.lproj#/dev3ec8a1cb4
[examples list]:  https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Views/ExamplesListView.swift
[auth code flow]: https://github.com/Peter-Schorn/SpotifyAPI#authorizing-with-the-authorization-code-flow
[url scheme]: https://developer.apple.com/documentation/xcode/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app
[make auth URL]: https://peter-schorn.github.io/SpotifyAPI/Classes/AuthorizationCodeFlowBackendManager.html#/s:13SpotifyWebAPI35AuthorizationCodeFlowBackendManagerC04makeD3URL11redirectURI10showDialog5state6scopes10Foundation0J0VSgAK_SbSSSgShyAA5ScopeOGtF
[authorize]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L160-L185
[login button]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Views/LoginView.swift#L89
[login view]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Views/LoginView.swift
[on open URL]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Views/RootView.swift#L32
[root view]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Views/RootView.swift
[request tokens]: https://peter-schorn.github.io/SpotifyAPI/Classes/AuthorizationCodeFlowBackendManager.html#/s:13SpotifyWebAPI35AuthorizationCodeFlowBackendManagerC29requestAccessAndRefreshTokens20redirectURIWithQuery5state7Combine12AnyPublisherVyyts5Error_pG10Foundation3URLV_SSSgtF
[auth did change publisher]: https://peter-schorn.github.io/SpotifyAPI/Classes/SpotifyAPI.html#/s:13SpotifyWebAPI0aC0C29authorizationManagerDidChange7Combine18PassthroughSubjectCyyts5NeverOGvp
[spotify init subscribe]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L97-L104
[auth did change method]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L187-L235
[is authorized]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L67
[is authorized true]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L208
[persistent storage wiki]: https://github.com/Peter-Schorn/SpotifyAPI/wiki/Saving-authorization-information-to-persistent-storage.
[spotify file]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Model/Spotify.swift
[did deauth method]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L237-L271
[logout button]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Views/RootView.swift#L116-L131
[did deauth publisher]: https://peter-schorn.github.io/SpotifyAPI/Classes/SpotifyAPI.html#/s:13SpotifyWebAPI0aC0C34authorizationManagerDidDeauthorize7Combine18PassthroughSubjectCyyts5NeverOGvp
[auth base deauth]: https://peter-schorn.github.io/SpotifyAPI/Classes/AuthorizationCodeFlowManagerBase.html#/s:13SpotifyWebAPI32AuthorizationCodeFlowManagerBaseC11deauthorizeyyF

[login view file]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/main/SpotifyAPIExampleApp/Views/LoginView.swift
[spotify init keychain]: https://github.com/Peter-Schorn/SpotifyAPIExampleApp/blob/8d41edb66c43df27b0c675526f531116e3df8fcc/SpotifyAPIExampleApp/Model/Spotify.swift#L114
[token swap]: https://developer.spotify.com/documentation/ios/guides/token-swap-and-refresh/
[spotify api server]: https://github.com/Peter-Schorn/SpotifyAPIServer

