//
//  SongEditViewModelTests.swift
//  AgapeSongsTests
//
//  Created by Ondřej Wrzecionko on 06.04.2022.
//

import Foundation
import XCTest

@testable import AgapeSongs

final class SongEditViewModelTests: AgapeSongsTestCase {
    
    private struct DI: HasAppState & HasPlaylistService & HasSongBookService & HasSongService {
        let appState: AppState
        let playlistService: PlaylistServicing
        let songBookService: SongBookServicing
        let songService: SongServicing
    }
    
    private var songBookListViewModel: SongBookListViewModel!
    private var viewModel: SongEditViewModel!
    
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
    
    override func setUp() {
        super.setUp()
        setUpViewModel()
    }
    
    // MARK: - Tests
    
    func testCreateSongSuccess() async {
        songService.createSongResponse = .success(dummySong)
        var songBook = SongBook(id: dummySong.songBook.id, band: dummySong.songBook.band.domain, name: "", songs: [])
        songBookListViewModel.songBooks = [songBook]
        
        await viewModel.createOrEditSong()
        
        songBook.songs = [dummySong.domain]
        
        XCTAssertEqual(viewModel.state, .success)
        XCTAssertEqual(songBookListViewModel.songBooks, [songBook])
        XCTAssertEqual(songBookListViewModel.songsById, ["1": dummySong.domain])
    }
    
    func testCreateSongFailure() async {
        songService.createSongResponse = .failure(.badtext(text: "Mock error"))
        let songBook = SongBook(id: dummySong.songBook.id, band: dummySong.songBook.band.domain, name: "", songs: [])
        songBookListViewModel.songBooks = [songBook]
        
        await viewModel.createOrEditSong()
        
        XCTAssertEqual(viewModel.state, .failure("Mock error"))
        XCTAssertEqual(songBookListViewModel.songBooks, [songBook])
    }
    
    func testEditSongSuccess() async {
        let dummySong2 = SongDTO(id: dummySong.id, songBook: SongBookRawDTO(id: 2, name: "", band: dummySong.songBook.band), name: "Another", text: dummySong.text, key: dummySong.key, bpm: dummySong.bpm, capo: 0, lastEdit: dummySong.lastEdit, displayId: dummySong.displayId, note: dummySong.note)
        let song = dummySong.domain, songInPlaylist = song.addToPlaylist(),
            song2 = dummySong2.domain, song2InPlaylist = song2.addToPlaylist()
        songService.editSongResponse = .success(dummySong2)
        
        var songBook = SongBook(id: dummySong.songBook.id, band: dummySong.songBook.band.domain, name: "", songs: [song])
        var songBook2 = SongBook(id: dummySong2.songBook.id, band: dummySong2.songBook.band.domain, name: "", songs: [])
        songBookListViewModel.songBooks = [songBook, songBook2]
        songBookListViewModel.songsById = ["1": song, "1,playlist": songInPlaylist]
        appState.playlist.songs = [songInPlaylist]
        appState.song = song
        
        viewModel.editSong = dummySong.domain
        
        await viewModel.createOrEditSong()
        
        songBook.songs = []
        songBook2.songs = [song2]
        
        XCTAssertEqual(viewModel.state, .success)
        XCTAssertEqual(songBookListViewModel.songBooks, [songBook, songBook2])
        XCTAssertEqual(songBookListViewModel.songsById, ["1": song2, "1,playlist": song2InPlaylist])
        XCTAssertEqual(appState.playlist.songs, [song2InPlaylist])
        XCTAssertEqual(appState.song, song2)
    }
    
    func testEditSongFailure() async {
        songService.editSongResponse = .failure(.badtext(text: "Mock error"))
        let songBook = SongBook(id: dummySong.songBook.id, band: dummySong.songBook.band.domain, name: "", songs: [dummySong.domain])
        
        viewModel.editSong = dummySong.domain
        songBookListViewModel.songBooks = [songBook]
        
        await viewModel.createOrEditSong()
        
        XCTAssertEqual(viewModel.state, .failure("Mock error"))
        XCTAssertEqual(songBookListViewModel.songBooks, [songBook])
    }
    
    // MARK: - Private helpers
    
    private func setUpViewModel() {
        let context = DI(
            appState: appState,
            playlistService: playlistService,
            songBookService: songBookService,
            songService: songService
        )
        songBookListViewModel = SongBookListViewModel(context: context)
        viewModel = SongEditViewModel(
            context: context,
            songBookListViewModel: songBookListViewModel
        )
    }
}
