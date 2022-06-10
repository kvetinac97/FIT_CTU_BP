//
//  SongBookListViewModel.swift
//  ViewModel
//
//  Created by Ondřej Wrzecionko on 10.03.2022.
//

import Foundation
import SwiftUI

final class SongBookListViewModel: ObservableObject {
    
    // MARK: - Public properties (Songs)
    
    @Published var state: SongBookListLoadState = .loading
    @Published var songBooks = [SongBook]()
    
    @Published var songsById = [String: Song]()
    @Published var selectedSongId: String? = nil {
        didSet {
            if let selectedSongIdSeparated = selectedSongId?.components(separatedBy: ","),
                let songId = selectedSongIdSeparated.first {
                let song = songsById[songId]
                appState.song = selectedSongIdSeparated.count > 1 ? song?.addToPlaylist() : song
                appState.selectedSongId = selectedSongId
            }
        }
    }
    
    @Published var isDeleteSongBookDone: Bool = false
    @Published var deleteSongBookError: String = ""
    
    @Published var isDeleteSongDone: Bool = false
    @Published var deleteSongError: String = ""
    
    // MARK: - Public properties (Playlist)
    
    @Published var playlistBands = [Band]()
    @Published var isPlaylistAlertDisplayed: Bool = false
    @Published var playlistAlertText: String = "" {
        didSet {
            isPlaylistAlertDisplayed = !playlistAlertText.isEmpty
        }
    }
    
    @Published var isSelectPlaylistEditDisplayed: Bool = false
    @Published var isPlaylistEditLoading: Bool = false
    
    @Published var isSelectPlaylistViewDisplayed: Bool = false
    @Published var isPlaylistViewLoading: Bool = false
    
    // MARK: - Private properties
    
    private let appState: AppState
    private let playlistService: PlaylistServicing
    private let songBookService: SongBookServicing
    private let songService: SongServicing
    
    // MARK: - Init
    
    init(context: HasAppState & HasPlaylistService & HasSongBookService & HasSongService) {
        appState = context.appState
        playlistService = context.playlistService
        songBookService = context.songBookService
        songService = context.songService
    }
    
    // MARK: - Public methods (Song)
    
    func delete(songBook: SongBook) {
        Task { await delete(songBook: songBook) }
    }
    
    func delete(songBook: SongBook) async {
        let result = await songBookService.delete(id: songBook.id)
        await delete(songBook: songBook, result: result)
    }
        
    func delete(song: Song) {
        Task { await delete(song: song) }
    }
    
    func delete(song: Song) async {
        let result = await songService.delete(id: song.songId)
        await delete(song: song, result: result)
    }
    
    func loadSongBooks() {
        state = .loading
        Task { await loadSongBooks() }
    }
    
    func loadSongBooks() async {
        let songBooks = await songBookService.songBookList()
        await loadSongBooks(result: songBooks)
    }
    
    // MARK: - Public methods (Playlist)
    
    func savePlaylist() {
        // Get correct bands
        let leaderBands = playlistBands.filter { $0.canEdit(user: appState.user) }
        
        // No bands
        if leaderBands.isEmpty {
            playlistAlertText = NSLocalizedString("playlist_upload_not_leader", comment: "")
        }
        // Only one band, select it
        else if leaderBands.count == 1, let first = leaderBands.first {
            savePlaylist(bandId: first.id)
        }
        // There is something to select
        else { isSelectPlaylistEditDisplayed = true }
    }
    
    func savePlaylist(bandId: Int) {
        isPlaylistEditLoading = true
        Task { await savePlaylist(bandId: bandId) }
    }
    
    func savePlaylist(bandId: Int) async {
        let dto = PlaylistDTO(songs: appState.playlist.songs.map { $0.songId })
        let playlist = await playlistService.save(bandId: bandId, playlist: dto)
        await loadPlaylist(result: playlist)
    }
    
    func loadPlaylist() {
        // No bands
        if playlistBands.isEmpty {
            playlistAlertText = NSLocalizedString("playlist_download_not_leader", comment: "")
        }
        // Only one band, select it
        else if playlistBands.count == 1, let first = playlistBands.first {
            loadPlaylist(bandId: first.id)
        }
        // There is something to select
        else { isSelectPlaylistViewDisplayed = true }
    }
    
    func loadPlaylist(bandId: Int) {
        isPlaylistViewLoading = true
        Task { await loadPlaylist(bandId: bandId) }
    }
    
    func loadPlaylist(bandId: Int) async {
        let playlist = await playlistService.getPlaylist(bandId: bandId)
        await loadPlaylist(result: playlist)
    }
    
    // MARK: - Private methods (Songs)
    
    @MainActor
    private func loadSongBooks(result: Result<[SongBookDTO], HttpStatusError>) async {
        switch result {
        case .success(let songBooks):
            self.songBooks = songBooks.map { $0.domain }
            songsById = [:]
            songsById = self.songBooks.flatMap { $0.songs }.reduce(into: songsById) {
                $0[$1.idString] = $1
            }
            playlistBands = Array(Set(self.songBooks.map { $0.band })).sorted {
                $0.name.localizedCompare($1.name) == .orderedAscending
            }
            
            appState.songBook = self.songBooks.first(where: { $0.id == appState.songBook?.id })
            state = .success
        case .failure(let error):
            print(error)
            
            // Unauthorized, log out
            if case .badcode(let code) = error, code == 401 {
                appState.logout()
                return
            }
            
            state = .failure(error.errorDescription)
        }
    }
    
    @MainActor
    private func delete(songBook: SongBook, result: Result<Void, HttpStatusError>) async {
        switch result {
        case .success(_):
            // Remove SongBook from list
            songBooks.removeAll(where: { $0.id == songBook.id })
            // Remove all songs from songsById, playlist and unselect if they were playlist
            songBook.songs.forEach { removeFromData(song: $0) }
            // If deleted SongBook was selected, unselect it
            if songBook.id == appState.songBook?.id {
                appState.songBook = nil
            }
            deleteSongBookError = ""
        case .failure(let error):
            print(error)
            deleteSongBookError = String(error.errorDescription)
        }
        isDeleteSongBookDone = true
    }
    
    @MainActor
    private func delete(song: Song, result: Result<Void, HttpStatusError>) async {
        switch result {
        case .success(_):
            // Delete song from its SongBook
            if let index = songBooks.firstIndex(where: { $0.id == song.songBook.id }) {
                songBooks[index].songs.removeAll(where: { $0.id == song.id })
                if songBooks[index].id == appState.songBook?.id {
                    appState.songBook = songBooks[index]
                }
            }
            removeFromData(song: song)
            deleteSongError = ""
        case .failure(let error):
            print(error)
            deleteSongError = String(error.errorDescription)
        }
        isDeleteSongDone = true
    }
    
    /// Delete given `song` from playlist, songsById and unselect it
    private func removeFromData(song: Song) {
        // Delete song from Playlist
        appState.playlist.songs.removeAll(where: { $0.songId == song.songId })
        
        // Delete song from songsByID
        songsById.removeValue(forKey: song.idString)
        songsById.removeValue(forKey: song.addToPlaylist().idString)
        
        // Unselect song if it was selected
        if song.songId == appState.song?.songId {
            appState.song = nil
        }
    }
    
    // MARK: - Private methods (Playlist)
    
    @MainActor
    private func loadPlaylist(result: Result<PlaylistDTO, HttpStatusError>) async {
        switch result {
        case .success(let playlistDto):
            // Firstly, remove all old playlist songs from songsByID
            appState.playlist.songs.forEach { songsById.removeValue(forKey: $0.idString) }
            // Secondly, set new songs based from API playlist response
            appState.playlistUpload = false
            appState.playlist.songs = playlistDto.songs.compactMap { songId in
                songsById.first(where: { $0.value.songId == songId })?.value.addToPlaylist()
            }
            appState.playlistUpload = true
            // Lastly, insert all new playlist songs to songsByID
            appState.playlist.songs.forEach { songsById[$0.idString] = $0 }
            
            // Display success dialog
            playlistAlertText = NSLocalizedString(isPlaylistEditLoading ? "playlist_upload_success" : "playlist_download_success", comment: "")
        case .failure(let error):
            playlistAlertText = NSLocalizedString(isPlaylistEditLoading ? "playlist_upload_failure" : "playlist_download_failure", comment: "") + error.errorDescription
        }
    }
}
