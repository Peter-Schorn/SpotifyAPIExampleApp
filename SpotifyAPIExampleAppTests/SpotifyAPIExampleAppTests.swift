//
//  SpotifyAPIExampleAppTests.swift
//  SpotifyAPIExampleAppTests
//
//  Created by Peter Schorn on 5/18/21.
//

import XCTest
import SpotifyWebAPI
import SpotifyAPITestUtilities
import SpotifyAPIExampleApp

class SpotifyAPIExampleAppTests: XCTestCase {

    static let spotifyAPI = SpotifyAPI<AuthorizationCodeFlowManager>.sharedTest

    static var currentUser: SpotifyUser? = nil

    var app: XCUIApplication!

    var isIgnoringFailures = false

    override class func setUp() {
        
        setenv("CLIENT_ID", spotifyCredentials.clientId, 1)
        setenv("CLIENT_SECRET", spotifyCredentials.clientSecret, 1)
        setenv("SPOTIFY_DC", spotifyDCCookieValue, 1)
        
        
        setenv(
            "SPOTIFY_AUTHORIZATION_CODE_FLOW_TOKENS_URL",
            authorizationCodeFlowTokensURL.absoluteString, 1
        )
        setenv(
            "SPOTIFY_AUTHORIZATION_CODE_FLOW_REFRESH_TOKENS_URL",
            authorizationCodeFlowRefreshTokensURL.absoluteString, 1
        )

        Self.spotifyAPI.authorizationManager.authorizeAndWaitForTokens()
        print("\n--- DID AUTHORIZE SPOTIFY API ---\n")
        do {
            guard let currentUser = try Self.spotifyAPI.currentUserProfile()
                    .waitForSingleValue() else {
                fatalError("could not retrieve current user")
            }
            Self.currentUser = currentUser
        } catch {
            fatalError("could not retrieve current user: \(error)")
        }
        
    }

    override func tearDown() {
        
    }

    override func setUpWithError() throws {
        self.continueAfterFailure = false
        self.app = XCUIApplication()
        self.app.launchEnvironment = ProcessInfo.processInfo.environment
        self.app.launchArguments = ["Xcode-UI-testing"]
        
    }

    func ignoringFailures<T>(_ block: () throws -> T) rethrows -> T {
        self.isIgnoringFailures = true
        defer { self.isIgnoringFailures = false }
        return try block()
    }
    
    override func record(_ issue: XCTIssue) {
        if !self.isIgnoringFailures {
            super.record(issue)
        }
    }

    // MARK: - Tests -

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            self.measure(metrics: [XCTApplicationLaunchMetric()]) {
                self.app.launch()
            }
        }
    }

    func authorize() throws {
        
        let loginButton = self.app.buttons["Log in with Spotify Identifier"]

        /// Not a defer statement because we don't want it to execute if an
        /// error is thrown.
        func waitForLoginButtonToDisappear() {
            // a network request must be made to retrieve the tokens after the
            // agree button is tapped
            loginButton.waitUntilDisappears(timeout: 60)
        }
        

        // there is a 0.5 second delay after the app launches before `LoginView`
        // is shown, which contains this button
        XCTAssert(
            loginButton.waitForExistence(timeout: 30),
            "could not find loginButton"
        )
        
        loginButton.coordinateTap()
        
        let signInAlertHandler = self.addUIInterruptionMonitor(
            withDescription: "Sign in Alert"
        ) { alert in
            print("Sign in Alert handler received alert: \(alert.label)")
            guard alert.label == "“SpotifyAPIExampleApp” Wants to Use “spotify.com” to Sign In" else {
                print("Sign in Alert handler did not handle alert")
                return false
            }
            alert.buttons["Continue"].tap()
            return true
        }
        
        sleep(5)  // wait for sign in alert to show up
        self.app.tap()  // trigger interruption monitor
        self.removeUIInterruptionMonitor(signInAlertHandler)

        let usernameField = self.app.webViews.webViews.webViews.textFields[
            "Email address or username"
        ]
        
        let agreeButton = self.app.webViews.webViews.webViews.buttons["AGREE"]

        // 6 * (5 + 5) = 60 seconds
        for i in 1...6 {
            print("\(i): wait for agree button or username field")
            if agreeButton.waitForExistence(timeout: 5) {
                agreeButton.tap()
                waitForLoginButtonToDisappear()
                return
            }
            if usernameField.waitForExistence(timeout: 5) {
                usernameField.tap()
                let userName = ProcessInfo.processInfo.environment["SPOTIFY_USERNAME"]!
                self.app.typeText(userName)
                self.app.dismissKeyboard()
                
                self.app.webViews.webViews.webViews.secureTextFields["Password"].tap()
                let password = ProcessInfo.processInfo.environment["SPOTIFY_PASSWORD"]!
                self.app.typeText(password)
                self.app.dismissKeyboard()
                
                // uncheck the "Remember me" checkbox (checked by default)
                self.app.webViews.webViews.webViews.switches["1"].tap()
                
                self.app.webViews.webViews.webViews.buttons["LOG IN"].tap()
                XCTAssert(
                    agreeButton.waitForExistence(timeout: 60),
                    "could not find agree button after logging in"
                )
                agreeButton.tap()
                waitForLoginButtonToDisappear()
                return
            }
        }

        XCTFail("could not find the agree button or username field")

    }
    
    /// Must be called when the app is displaying the root view.
    func renewSPTSession() {
        let examplesListView = self.app.tables.element
        examplesListView.buttons["Debug Menu"].tap()
        let renewSessionButton = self.app.buttons["Renew SPTSession"]
        XCTAssert(
            renewSessionButton.waitForExistence(timeout: 5),
            "could not find renew session button"
        )
        renewSessionButton.tap()
        let backButton = self.app.navigationBars.element.buttons.element
        backButton.tap()
    }

    func testAlbums() throws {
        
        self.app.launchArguments.append("reset-authorization")
        self.app.launch()
        
        try self.authorize()
        
        let examplesListView = self.app.tables.element
        let savedAlbumsButton = examplesListView.buttons["Saved Albums"]
        XCTAssert(
            savedAlbumsButton.waitForExistence(timeout: 60),
            "could not find Saved albums button"
        )
        
        savedAlbumsButton.tap()
        
        // MARK: Retrieve Saved Albums
        let savedAlbumsPage = try XCTUnwrap(
            Self.spotifyAPI.currentUserSavedAlbums(limit: 5)
                .waitForSingleValue(),
            "could not retrieve saved albums"
        )
        let savedAlbums = savedAlbumsPage.items.map(\.item)
        
        let savedAlbumsGrid = self.app.otherElements["Saved Albums Grid"]
        XCTAssert(savedAlbumsGrid.waitForExistence(timeout: 60))
        
        // MARK:
        for album in savedAlbums {
            let albumCell = savedAlbumsGrid.buttons[album.name]
            XCTAssert(albumCell.exists)
            XCTAssertEqual(albumCell.label, album.name)
        }
        
        // MARK: Check First Album
        let firstAlbum = try XCTUnwrap(
            savedAlbums.first, "no saved albums"
        )

        let albumCell = savedAlbumsGrid.buttons[firstAlbum.name]
        XCTAssert(albumCell.exists)
        XCTAssertEqual(albumCell.label, firstAlbum.name)
        albumCell.tap()

        // MARK: Check First Album Grid Item View
        let albumAndArtistName: String = {
            var title = firstAlbum.name
            if let artistName = firstAlbum.artists?.first?.name {
                title += " - \(artistName)"
            }
            return title
        }()
        let albumGridItemScrollView = self.app.scrollViews.firstMatch
        let albumAndArtistNameLabel =
                albumGridItemScrollView.staticTexts[albumAndArtistName]
        XCTAssert(
            albumAndArtistNameLabel.waitForExistence(timeout: 60),
            "could not find albumAndArtistName label"
        )
        XCTAssertEqual(
            albumAndArtistNameLabel.label, albumAndArtistName
        )

        let firstAlbumTracks = try XCTUnwrap(
            firstAlbum.tracks?.items,
            "could not get tracks for '\(firstAlbum.name)'"
        )
        for (i, track) in firstAlbumTracks.enumerated() {
            let trackLabel = "\(i + 1). \(track.name)"
            let trackButton = albumGridItemScrollView.buttons[trackLabel]
            XCTAssert(trackButton.waitForExistence(timeout: 60))
            XCTAssert(trackButton.isHittable)
            XCTAssertEqual(trackButton.label, trackLabel)
        }

    }

    func testPlaylists() throws {

        self.app.launch()
        self.renewSPTSession()

        let examplesListView = self.app.tables.element
        let examplesListViewCellNames = [
            "Playlists",
            "Saved Albums",
            "Search For Tracks",
            "Play a URI",
            "Player Controls",
            "Debug Menu"
        ]
        for cell in examplesListViewCellNames {
            XCTAssertTrue(examplesListView.cells.buttons[cell].exists)
        }
        
        examplesListView.buttons["Playlists"].tap()

        // only retrieve 5 playlists because some of the offscreen playlists do
        // not show up properly in the view hierarchy query
        let playlistsPage = try XCTUnwrap(
            Self.spotifyAPI.currentUserPlaylists(limit: 5).waitForSingleValue(),
            "couldn't get current user playlists"
        )
        let playlists = playlistsPage.items

//        let playlistsTable = self.app.tables.matching(
//            identifier: "Playlists List View"
//        )
//        .element
        
        let playlistsTable = self.app.tables["Playlists List View"]
        XCTAssert(playlistsTable.waitForExistence(timeout: 60))
        
        // MARK: Check PlaylistsListView Cells
        for (i, playlist) in playlists.enumerated() {
            let expectedPlaylistLabel =
                    "\(playlist.name) - \(playlist.items.total) items"
            let actualPlaylistLabel =
                    playlistsTable.cells.element(boundBy: i).label
            // po [expectedPlaylistLabel, actualPlaylistLabel]
            // po expectedPlaylistLabel == actualPlaylistLabel
            XCTAssertEqual(
                actualPlaylistLabel,
                expectedPlaylistLabel,
                "actual != expected"
            )
        }
        
        let currentUser = try XCTUnwrap(
            Self.currentUser, "current user was nil"
        )
        
        // MARK: Retrieve First User Playlist
        let userPlaylist = try XCTUnwrap(
            playlists.first(where: {
                $0.owner?.uri == currentUser.uri
            }),
            "could not find any playlists owned by current user"
        )
        print("first user playlist: '\(userPlaylist.name)'")

        let userPlaylistItems = try XCTUnwrap(
            Self.spotifyAPI.playlistItems(userPlaylist, limit: 10)
                .waitForSingleValue(),
            "couldn't get items for playlist '\(userPlaylist.name)'"
        )
        let userPlaylistItemsURIs = userPlaylistItems.items
            .compactMap(\.item?.uri)
        
        // MARK: Add duplicate items to playlist
        _ = try XCTUnwrap(
            try Self.spotifyAPI.addToPlaylist(
                userPlaylist, uris: userPlaylistItemsURIs
            )
            .waitForSingleValue(),
            "could not add items to playlist"
        )
        sleep(2)  // wait for the Spotify web API database to update
        
        // MARK: Reload Playlists
        self.app.navigationBars["Playlists"].buttons.element(boundBy: 1).tap()
        
        // MARK: Remove Duplicates From Playlist

        // including the duplicates that were added
        let expectedUserPlaylistItemsCount = userPlaylistItems.total +
            userPlaylistItemsURIs.count
        
        let userPlaylistLabel =
                "\(userPlaylist.name) - \(expectedUserPlaylistItemsCount) items"
        
        let userPlaylistCell = playlistsTable.cells[userPlaylistLabel]
        XCTAssert(userPlaylistCell.waitForExistence(timeout: 60))
        XCTAssertEqual(userPlaylistCell.label, userPlaylistLabel)
        userPlaylistCell.press(forDuration: 2)
        self.app.buttons["Remove Duplicates"].tap()
        
        // Duplicates have been removed from the playlist alert
        let duplicatesRemovedAlert = self.app.alerts.element
        XCTAssert(duplicatesRemovedAlert.waitForExistence(timeout: 60))
        duplicatesRemovedAlert.buttons.element.tap()
        
        // MARK: Ensure Label has been Updated to Reflect Removed Duplicates
        let updatedUserPlaylistLabel =
                "\(userPlaylist.name) - \(userPlaylist.items.total) items"
        let updatedUserPlaylistCell =
                playlistsTable.cells[updatedUserPlaylistLabel]
        XCTAssert(updatedUserPlaylistCell.waitForExistence(timeout: 10))
        
    }
 
}

