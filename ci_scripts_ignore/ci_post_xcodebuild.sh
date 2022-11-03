cd $PROJECT_DIR
cd SoftPlayer/Model

sed -r -i '' 's~(let __clientId__ = )".*"~\1""~' 'Spotify.swift'

sed -r -i '' 's~(let __tokensURL__ = )".*"~\1""~' 'Spotify.swift'
sed -r -i '' 's~(let __tokensRefreshURL__ = )".*"~\1""~' 'Spotify.swift'
