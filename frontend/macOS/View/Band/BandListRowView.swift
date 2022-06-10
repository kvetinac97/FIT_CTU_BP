//
//  BandListRowView.swift
//  View (macOS)
//
//  Created by Ondřej Wrzecionko on 09.03.2022.
//

import SwiftUI

struct BandListRowView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var appState: AppState
    @State private var isActive: Bool = false
    
    @Binding var band: Band
    
    // MARK: - View
    
    var body: some View {
        NavigationLink(destination: SettingsView(band: $band), isActive: $isActive) {
            HStack {
                Text(band.name)
                    .font(.system(size: appState.defaultFontSize))
                Spacer()
            }
        }
    }
}
