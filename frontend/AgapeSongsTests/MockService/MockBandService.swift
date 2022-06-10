//
//  MockBandService.swift
//  AgapeSongsTests
//
//  Created by Ondřej Wrzecionko on 09.03.2022.
//

import Foundation

@testable import AgapeSongs

class MockBandService: BandServicing {
    init() {}
    
    var selectedBand: BandSaveDTO? = nil
    
    var bandListResponse: Result<[BandDTO], HttpStatusError>?
    private(set) var bandListCalled = false
    
    func bandList() async -> Result<[BandDTO], HttpStatusError> {
        bandListCalled = true
        return bandListResponse ?? .failure(.badtext(text: "Did not provide implementation"))
    }
    
    func select(band: BandSaveDTO) {
        selectedBand = band
    }
    
    func clearBand() {
        selectedBand = nil
    }
}
