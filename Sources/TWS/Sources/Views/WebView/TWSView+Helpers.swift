//
//  TWSView+Helpers.swift
//  TWS
//
//  Created by Sven Kotnik on 22. 4. 26.
//

import Foundation
import WebKit

extension WebView {
    func shouldChangeLastLoaded() -> Bool {
        return state.lastLoadedUrl == nil || state.lastLoadedUrl != initialUrl()
    }
    
    func initialUrl() -> URL? {
        return htmlContent?.cachedResponse?.responseUrl
    }
}
