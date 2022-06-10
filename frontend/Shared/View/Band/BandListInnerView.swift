//
//  BandListInnerView.swift
//  View
//
//  Created by Ondřej Wrzecionko on 14.03.2022.
//

import SwiftUI

struct BandListInnerView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var appState: AppState
    @ObservedObject var bandListViewModel: BandListViewModel
    @State private var isSettingsPopoverDisplayed: Bool = false
    
    // MARK: - View
    
    var body: some View {
        VStack {
            BandListHeaderView(
                isSettingsPopoverDisplayed: $isSettingsPopoverDisplayed,
                bands: bandListViewModel.bands.filter { $0.canEdit(user: appState.user) }
            )
            List($bandListViewModel.bands) { band in
                BandListRowView(band: band)
            }
        }
    }
}
