//
//  BandService.swift
//  Service
//
//  Created by Ondřej Wrzecionko on 09.03.2022.
//

import Foundation

/// Protocol for Band service
protocol BandServicing {
    /// Actual selected band (`nil` if nothing selected)
    var selectedBand: BandSaveDTO? { get }
    
    /// Gets list of all bands given user is member of
    func bandList() async -> Result<[BandDTO], HttpStatusError>
    
    /// Saves actual selected band
    func select(band: BandSaveDTO)
    
    /// Clear band selection
    func clearBand()
}

/// Helper DI protocol
protocol HasBandService {
    var bandService: BandServicing { get }
}

struct BandService: BandServicing {
    
    // MARK: - Properties
    
    var selectedBand: BandSaveDTO? {
        getBand()
    }
    
    // MARK: - Private properties
    
    private let networkService: NetworkServicing
    
    // MARK: - Init
    
    init(context: HasNetworkService) {
        networkService = context.networkService
    }
    
    // MARK: - Interface method implementation
    
    func bandList() async -> Result<[BandDTO], HttpStatusError> {
        let response = await networkService.get(url: Constants.bandListUrl)
        switch response {
        case .success(let data):
            guard let bands = try? JSONDecoder().decode([BandDTO].self, from: data) else {
                return .failure(.badtext(text: "band_list_response_parse_error"))
            }
            return .success(bands)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func select(band: BandSaveDTO) {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(band)
        UserDefaults.standard.setValue(data, forKey: Constants.bandSavePath)
    }
    
    func clearBand() {
        UserDefaults.standard.removeObject(forKey: Constants.bandSavePath)
    }
    
    // MARK: - Private helpers
    
    private func getBand() -> BandSaveDTO? {
        guard let data = UserDefaults.standard.data(forKey: Constants.bandSavePath) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(BandSaveDTO.self, from: data)
    }
    
    // MARK: - Constants
    
    private enum Constants {
        static let bandListUrl = "/band"
        static let bandSavePath = "selected_band"
    }
}

// Implementation for DI
private let _bandService = BandService(context: context)

extension DI: HasBandService {
    var bandService: BandServicing { _bandService }
}
