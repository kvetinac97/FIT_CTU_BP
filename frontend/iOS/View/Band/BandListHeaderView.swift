//
//  BandListHeaderView.swift
//  View (iOS)
//
//  Created by Ondřej Wrzecionko on 14.03.2022.
//

import SwiftUI

struct BandListHeaderView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var appState: AppState
    @Binding var isSettingsPopoverDisplayed: Bool
    let bands: [Band]
    
    // MARK: - View
    
    var body: some View {
        VStack { }
            .toolbar {
                ToolbarItemGroup(placement: _toolbarPlacementTrailing) {
                    Button(action: { isSettingsPopoverDisplayed = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                    .alwaysPopover(isPresented: $isSettingsPopoverDisplayed) {
                        SettingsPopoverView(isSettingsPopoverDisplayed: $isSettingsPopoverDisplayed, bands: bands)
                            .environmentObject(appState)
                            .frame(width: 270, height: 420)
                    }
                }
            }
    }
}

