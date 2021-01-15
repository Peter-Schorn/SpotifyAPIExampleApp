import Foundation

func == (lhs: SPTAppRemotePlayerState, rhs: SPTAppRemotePlayerState) -> Bool {
 
    return lhs.track == rhs.track &&
        lhs.playbackPosition == rhs.playbackPosition &&
        lhs.playbackSpeed == rhs.playbackSpeed &&
        lhs.isPaused == rhs.isPaused &&
        lhs.playbackRestrictions == rhs.playbackRestrictions &&
        lhs.playbackOptions == rhs.playbackOptions &&
        lhs.contextURI == rhs.contextURI &&
        lhs.contextTitle == rhs.contextTitle

}

func == (lhs: SPTAppRemoteTrack, rhs: SPTAppRemoteTrack) -> Bool {
    
    return lhs.name == rhs.name &&
        lhs.uri == rhs.uri &&
        lhs.duration == rhs.duration &&
        lhs.isSaved == rhs.isSaved
    
}


func == (
    lhs: SPTAppRemotePlaybackRestrictions,
    rhs: SPTAppRemotePlaybackRestrictions
) -> Bool {
    
    return lhs.canSkipNext == rhs.canSkipNext &&
        lhs.canSkipPrevious == rhs.canSkipPrevious &&
        lhs.canRepeatTrack == rhs.canRepeatTrack &&
        lhs.canToggleShuffle == rhs.canToggleShuffle &&
        lhs.canSeek == rhs.canSeek

}

func == (
    lhs: SPTAppRemotePlaybackOptions,
    rhs: SPTAppRemotePlaybackOptions
) -> Bool {

    return lhs.isShuffling == rhs.isShuffling &&
        lhs.repeatMode == rhs.repeatMode

}
