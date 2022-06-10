//
//  SongBookListView.swift
//  View
//
//  Created by Ondřej Wrzecionko on 10.03.2022.
//

import SwiftUI

struct SongBookListView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var appState: AppState
    @ObservedObject var songBookListViewModel: SongBookListViewModel
    @State private var isSongBookFilterDisplayed: Bool = false
    
    // MARK: - View
    
    var body: some View {
        VStack {
            switch songBookListViewModel.state {
            case .loading:
                ProgressView()
            case .failure(let error):
                ErrorView(error: error, action: songBookListViewModel.loadSongBooks, dismiss: nil)
            case .success:
                EditModeStackView {
                    SongBookListWrapperView(songBookListViewModel: songBookListViewModel)
                        .applyModifiers(
                            appState: _appState,
                            songBookListViewModel: _songBookListViewModel,
                            isSongBookFilterDisplayed: $isSongBookFilterDisplayed
                        )
                }
            }
        }
        .navigationTitle("songbook_list")
    }
}
