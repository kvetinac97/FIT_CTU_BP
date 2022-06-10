//
//  AgapeSongsTestCase.swift
//  AgapeSongsTests
//
//  Created by Ondřej Wrzecionko on 18.03.2022.
//

import Foundation
import XCTest

@testable import AgapeSongs

open class AgapeSongsTestCase: XCTestCase {
    
    // MARK: - Private helpers
    
    private struct AppStateDI: HasAuthService & HasBandService & HasPlaylistService &
        HasSongService & HasSongBookService {
        let authService: AuthServicing
        let bandService: BandServicing
        let songService: SongServicing
        let playlistService: PlaylistServicing
        let songBookService: SongBookServicing
    }
    
    // MARK: - Properties
    
    var authService: MockAuthService!
    var bandService: MockBandService!
    var songService: MockSongService!
    var playlistService: MockPlaylistService!
    var songBookService: MockSongBookService!
    
    var appState: AppState!
    
    // MARK: - Overriden XCTestCase functions

    open override func setUp() {
        super.setUp()
        
        authService = .init()
        bandService = .init()
        songService = .init()
        playlistService = .init()
        songBookService = .init()
        
        setUpAppState()
    }
    
    open override func tearDown() {
        authService = nil
        bandService = nil
        songService = nil
        playlistService = nil
        songBookService = nil
    
        super.tearDown()
    }
    
    // MARK: - Private helpers
    
    private func setUpAppState() {
        appState = AppState(
            context: AppStateDI(
                authService: authService,
                bandService: bandService,
                songService: songService,
                playlistService: playlistService,
                songBookService: songBookService
            )
        )
    }
    
}
