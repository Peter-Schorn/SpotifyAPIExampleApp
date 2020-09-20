import SwiftUI
import Combine
import SpotifyWebAPI

struct SavedAlbumsGridView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var savedAlbums: [Album] = []
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    @State private var didRequestAlbums = false
    @State private var isLoadingAlbums = false
    @State private var couldntLoadAlbums = false
    
    @State private var loadAlbumsCancellable: AnyCancellable? = nil
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        Group {
            if savedAlbums.isEmpty {
                if isLoadingAlbums {
                    HStack {
                        ActivityIndicator(
                            isAnimating: .constant(true),
                            style: .medium
                        )
                        Text("Loading Albums")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                else if couldntLoadAlbums {
                    Text("Couldn't Load Albums")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(savedAlbums, id: \.self) { album in
                            SavedAlbumView(album: album)
                        }
                    }
                    .padding()
                }
            }
            
        }
        .navigationTitle("Saved Albums")
        .navigationBarItems(trailing: refreshButton)
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
        .onAppear {
            if !self.didRequestAlbums {
                self.retrieveSavedAlbums()
            }
        }
    }
    
    var refreshButton: some View {
        Button(action: retrieveSavedAlbums) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoadingAlbums)
        
    }
    
    func retrieveSavedAlbums() {
        
        self.didRequestAlbums = true
        self.isLoadingAlbums = true
        self.savedAlbums = []
        
        print("retrieveSavedAlbums")
        
        self.loadAlbumsCancellable = spotify.api
            .currentUserSavedAlbums()
            .extendPages(spotify.api)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingAlbums = false
                    switch completion {
                        case .finished:
                            self.couldntLoadAlbums = false
                        case .failure(let error):
                            self.couldntLoadAlbums = true
                            self.alertTitle = "Couldn't Retrieve Albums"
                            self.alertMessage = error.localizedDescription
                            self.alertIsPresented = true
                    }
                },
                receiveValue: { savedAlbums in
                    let albums = savedAlbums.items.map(\.item)
                    self.savedAlbums.append(contentsOf: albums)
                }
            )
    }

}

struct SavedAlbumsView_Previews: PreviewProvider {
    static var previews: some View {
        SavedAlbumsGridView()
    }
}
