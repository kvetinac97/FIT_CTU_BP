//
//  BandListViewModel.swift
//  ViewModel
//
//  Created by Ondřej Wrzecionko on 09.03.2022.
//

import Foundation

final class BandListViewModel: ObservableObject {
    
    // MARK: - Public properties
    
    @Published var state: BandListLoadState = .loading
    @Published var bands = [Band]()
    
    // MARK: - Private properties
    
    private let appState: AppState
    private let bandService: BandServicing
    
    // MARK: - Init
    
    init(context: HasAppState & HasBandService) {
        appState = context.appState
        bandService = context.bandService
        loadBands()
    }
    
    // MARK: - Public methods
    
    func loadBands() {
        Task { await loadBands() }
    }
    
    func loadBands() async {
        let bands = await bandService.bandList()
        await loadBands(result: bands)
    }
    
    // MARK: - Private methods
    
    @MainActor
    func loadBands(result: Result<[BandDTO], HttpStatusError>) async {
        switch result {
        case .success(let bands):
            self.bands = bands.map { $0.domain }
            
            // auto-select band if there is only one
            if self.bands.count == 1, let first = self.bands.first {
                appState.band = first
            }
            
            state = bands.isEmpty ? .empty : .success
        case .failure(let error):
            print(error)
            state = .failure(error.errorDescription)
        }
    }
    
}
