//
//  TWSPopupViewModel.swift
//  TWSUI
//
//  Created by Luka Kit on 24. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels
import TWSKit

@Observable
class TWSPresentedPopupViewModel {

    let manager: TWSManager

    init(manager: TWSManager) {
        self.manager = manager
    }

    @MainActor func onSnippetClosed(snippet: TWSSnippet) {
        manager.addClearedPopup(snippet)
    }
}
