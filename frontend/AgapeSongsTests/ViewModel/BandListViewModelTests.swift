//
//  BandListViewModelTests.swift
//  AgapeSongsTests
//
//  Created by Ondřej Wrzecionko on 09.03.2022.
//

import Foundation
import XCTest

@testable import AgapeSongs

final class BandListViewModelTests: AgapeSongsTestCase {
    
    private struct DI: HasAppState & HasBandService {
        let appState: AppState
        let bandService: BandServicing
    }
    
    private var viewModel: BandListViewModel!
    
    override func setUp() {
        super.setUp()
        setUpViewModel()
    }
    
    // MARK: - Tests
    
    func testLoadBandsSuccess() async {
        let mockBandResponse = [
            BandDTO(id: 1, name: "Jošafat", members: []),
            BandDTO(id: 2, name: "Agapebend", members: [])
        ]
        bandService.bandListResponse = .success(mockBandResponse)
        
        await viewModel.loadBands()
        
        XCTAssertTrue(bandService.bandListCalled)
        XCTAssertEqual(viewModel.bands, mockBandResponse.map { $0.domain })
        XCTAssertEqual(viewModel.state, .success)
    }
    
    func testLoadBandsEmpty() async {
        bandService.bandListResponse = .success([BandDTO]())
        
        await viewModel.loadBands()
        
        XCTAssertTrue(bandService.bandListCalled)
        XCTAssertEqual(viewModel.bands, [Band]())
        XCTAssertEqual(viewModel.state, .empty)
    }
    
    func testLoadBandsFailure() async {
        bandService.bandListResponse = .failure(.badtext(text: "Mock error"))
        
        await viewModel.loadBands()
        
        XCTAssertTrue(bandService.bandListCalled)
        XCTAssertEqual(viewModel.bands, [Band]())
        XCTAssertEqual(viewModel.state, .failure("Mock error"))
    }
    
    // MARK: - Private helpers
    
    private func setUpViewModel() {
        viewModel = BandListViewModel(
            context: DI(
                appState: appState,
                bandService: bandService
            )
        )
    }
}
