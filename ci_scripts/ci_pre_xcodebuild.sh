cd $SRCROOT
cd SoftPlayer/Model

source ~/.local/soft_player_credentials.sh

sed -r -i '' "s~(let __clientId__ = )\".*\"~\1\"$SPOTIFY_SWIFT_TESTING_CLIENT_ID\"~" 'Spotify.swift'

sed -r -i '' "s~(let __tokensURL__ = )\".*\"~\1\"$SPOTIFY_AUTHORIZATION_CODE_FLOW_TOKENS_URL\"~" 'Spotify.swift'
sed -r -i '' "s~(let __tokensRefreshURL__ = )\".*\"~\1\"$SPOTIFY_AUTHORIZATION_CODE_FLOW_REFRESH_TOKENS_URL\"~" 'Spotify.swift'
