//
//  BandListView.swift
//  View
//
//  Created by Ondřej Wrzecionko on 03.03.2022.
//

import SwiftUI

struct BandListView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var appState: AppState
    @StateObject var bandListViewModel = BandListViewModel(context: context)
    @State private var isBandCreateDisplayed: Bool = false
    
    // MARK: - View
    
    var body: some View {
        VStack {
            switch bandListViewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure(let error):
                ErrorView(error: error, action: bandListViewModel.loadBands, dismiss: nil)
            case .empty:
                Text("band_list_empty")
                    .font(.system(size: appState.defaultFontSize))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .success:
                BandListInnerView(bandListViewModel: bandListViewModel)
            }
        }
        .navigationTitle("band_list")
    }
}
