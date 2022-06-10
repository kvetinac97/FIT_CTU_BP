//
//  SongBookListViewModelTests.swift
//  AgapeSongsTests
//
//  Created by Ondřej Wrzecionko on 12.03.2022.
//

import Foundation
import XCTest

@testable import AgapeSongs

final class SongBookListViewModelTests: AgapeSongsTestCase {
    
    private struct DI: HasAppState & HasPlaylistService & HasSongBookService & HasSongService {
        let appState: AppState
        let playlistService: PlaylistServicing
        let songBookService: SongBookServicing
        let songService: SongServicing
    }
    
    private var viewModel: SongBookListViewModel!
    
    private let dummySong = SongDTO(
        id: 1,
        songBook: SongBookRawDTO(id: 1, name: "Jošafat", band: BandDTO(id: 1, name: "Jošafat", members: [])),
        name: "Kéž se všichni svatí",
        text: [SongLineDTO(id: "mockid", chords: nil, text: "Text 1")],
        key: SongKey.E,
        bpm: 120,
        capo: 0,
        lastEdit: "2022-01-01 01:00:00",
        displayId: 1,
        note: nil
    )
    private let dummySong2 = SongDTO(
        id: 2,
        songBook: SongBookRawDTO(id: 1, name: "Jošafat", band: BandDTO(id: 1, name: "Jošafat", members: [])),
        name: "Jahve Jireh",
        text: [SongLineDTO(id: "mockkid", chords: "C    F", text: "Text 2")],
        key: SongKey.C,
        bpm: 126,
        capo: 3,
        lastEdit: "2022-01-02 01:00:00",
        displayId: nil,
        note: SongNoteDTO(id: 1, notes: "Pomalu", capo: 3, lastEdit: "2022-01-02 02:00:00")
    )
    
    override func setUp() {
        super.setUp()
        setUpViewModel()
    }
    
    // MARK: - Tests
    
    func testLoadSongBooksSuccess() async {
        let mockSongBookService = [
            SongBookDTO(
                id: dummySong.songBook.id,
                band: BandDTO(
                    id: 1, name: "Jošafat", members: []
                ),
                name: dummySong.songBook.name, songs: [
                    dummySong, dummySong2,
                ]
            ),
            SongBookDTO(
                id: 2,
                band: BandDTO(id: 2, name: "Agapebend", members: []),
                name: "Agapebend",
                songs: []
            )
        ]
        songBookService.songBookListResponse = .success(mockSongBookService)
        
        await viewModel.loadSongBooks()
        
        XCTAssertTrue(songBookService.songBookListCalled)
        XCTAssertEqual(viewModel.songBooks, mockSongBookService.map { $0.domain })
        XCTAssertEqual(viewModel.state, .success)
    }
    
    func testLoadSongBooksEmpty() async {
        songBookService.songBookListResponse = .success([SongBookDTO]())
        
        await viewModel.loadSongBooks()
        
        XCTAssertTrue(songBookService.songBookListCalled)
        XCTAssertEqual(viewModel.songBooks, [SongBook]())
        XCTAssertEqual(viewModel.state, .success)
    }
    
    func testLoadSongBooksFailure() async {
        songBookService.songBookListResponse = .failure(.badtext(text: "Mock error"))
        
        await viewModel.loadSongBooks()
        
        XCTAssertTrue(songBookService.songBookListCalled)
        XCTAssertEqual(viewModel.songBooks, [SongBook]())
        XCTAssertEqual(viewModel.state, .failure("Mock error"))
    }
    
    func testLoadPlaylistSuccess() async {
        let song = dummySong.domain
        let song2 = dummySong2.domain
        let songInPlaylist = song.addToPlaylist()
        let song2InPlaylist = song2.addToPlaylist()
        
        appState.playlist.songs = [song2InPlaylist]
        
        playlistService.playlistResponse = .success(PlaylistDTO(songs: [1, 5, 9]))
        viewModel.songsById = ["2,playlist": song2InPlaylist, "1": song, "2": song2]
        
        await viewModel.loadPlaylist(bandId: 1)
        
        XCTAssertTrue(playlistService.getPlaylistCalled)
        XCTAssertEqual(appState.playlist.songs, [songInPlaylist])
        XCTAssertEqual(viewModel.songsById, ["1": song, "1,playlist": songInPlaylist, "2": song2])
        XCTAssertEqual(viewModel.playlistAlertText, NSLocalizedString("playlist_download_success", comment: ""))
    }
    
    func testLoadPlaylistFailure() async {
        playlistService.playlistResponse = .failure(.badtext(text: "Mock error"))
        
        await viewModel.loadPlaylist(bandId: 1)
        
        XCTAssertTrue(playlistService.getPlaylistCalled)
        XCTAssertEqual(appState.playlist.songs, [])
        XCTAssertEqual(viewModel.playlistAlertText, NSLocalizedString("playlist_download_failure", comment: "") + "Mock error")
    }
    
    func testDeleteSongSuccess() async {
        songService.deleteSongResponse = .success(())
        let song = dummySong.domain, song2 = dummySong2.domain
        let songPlaylist = song.addToPlaylist(), song2Playlist = song2.addToPlaylist()
        let band = Band(id: 1, name: "", members: [])
        var songBook = SongBook(id: 1, band: band, name: "", songs: [song, song2])
        viewModel.songBooks = [songBook]
        viewModel.songsById = ["1": song, "1,playlist": songPlaylist, "2": song2, "2,playlist": song2Playlist]
        appState.playlist.songs = [song2, song]
        appState.song = song
        
        await viewModel.delete(song: dummySong.domain)
        
        songBook.songs = [song2]
        
        XCTAssertTrue(viewModel.isDeleteSongDone)
        XCTAssertEqual(viewModel.songBooks, [songBook])
        XCTAssertEqual(viewModel.songsById, ["2": song2, "2,playlist": song2Playlist])
        XCTAssertEqual(appState.playlist.songs, [song2])
        XCTAssertEqual(appState.song, nil)
    }
    
    func testDeleteSongFailure() async {
        songService.deleteSongResponse = .failure(.badtext(text: "Mock error"))
        
        await viewModel.delete(song: dummySong.domain)
        
        XCTAssertTrue(viewModel.isDeleteSongDone)
        XCTAssertEqual(viewModel.deleteSongError, "Mock error")
    }
    
    func testDeleteSongBookSuccess() async {
        songBookService.deleteSongBookResponse = .success(())
        let dummySong = dummySong.domain
        let dummySongBook = SongBook(id: 1, band: Band(id: 1, name: "", members: []), name: "", songs: [dummySong])
        appState.songBook = dummySongBook
        appState.song = dummySong
        viewModel.songBooks = [dummySongBook]
        
        await viewModel.delete(songBook: dummySongBook)
        
        XCTAssertTrue(viewModel.isDeleteSongBookDone)
        XCTAssertEqual(viewModel.songBooks, [])
        XCTAssertEqual(appState.songBook, nil)
        XCTAssertEqual(appState.song, nil) // song was really deleted
    }
    
    func testDeleteSongBookFailure() async {
        songBookService.deleteSongBookResponse = .failure(.badtext(text: "Mock error"))
        let dummySongBook = SongBook(id: 1, band: Band(id: 1, name: "", members: []), name: "", songs: [])
        viewModel.songBooks = [dummySongBook]
        appState.songBook = dummySongBook
        
        await viewModel.delete(songBook: dummySongBook)
        
        XCTAssertTrue(viewModel.isDeleteSongBookDone)
        XCTAssertEqual(viewModel.deleteSongBookError, "Mock error")
        XCTAssertEqual(viewModel.songBooks, [dummySongBook])
        XCTAssertEqual(appState.songBook, dummySongBook)
    }
    
    // MARK: - Private helpers
    
    private func setUpViewModel() {
        viewModel = SongBookListViewModel(
            context: DI(
                appState: appState,
                playlistService: playlistService,
                songBookService: songBookService,
                songService: songService
            )
        )
    }
}
