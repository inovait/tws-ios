//
//  TWSPopupView.swift
//  TWSUI
//
//  Created by Luka Kit on 27. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSModels
import TWSKit

public struct TWSPopupView: View {
    @State private var viewModel: TWSPopupViewModel

    @MainActor
    public init(manager: TWSManager) {
        viewModel = TWSPopupViewModel(manager: manager)
    }

    public var body: some View {
        NavigationStack(path: $viewModel.navigation) {
            Color.clear
                .navigationDestination(for: TWSNavigationType.self) { navigation in
                    switch navigation {
                    case .snippetPopup(let snippet):
                        TWSPresentedPopupView(manager: viewModel.manager, snippet: snippet, onClose: { snippet in
                            viewModel.removeNavigationFromQueue(.snippetPopup(snippet))
                        })
                            .navigationBarHidden(true)
                            .navigationBarBackButtonHidden(true)
                    }
                }
        }
        .onAppear {
            viewModel.fillInitialNavigation()
        }
        .task {
            await viewModel.startListeningForEvents()
        }
    }
}
