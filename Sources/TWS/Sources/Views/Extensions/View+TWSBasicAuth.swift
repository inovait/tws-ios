//
//  View+TWSBasicAuth.swift
//  TWS
//
//  Created by Sven Kotnik on 4. 5. 26.
//

import Foundation
import TWSShared
import SwiftUI

extension View {
    
    /// SwiftUI helper method that lets you set a persistance strategy for Basic Authentication flow
    /// If your webview is using Basic Authentication this method lets you specify, whether credentials should be persisted in memory or in keychain.
    ///
    /// - Parameter value: Enum that determines whether keychain or session based persistance is used.
    ///
    /// - Note: This should only be set once, and before the Basic Authentication is triggered.
    /// In case of multiple usages the one where Basic Authentication was triggered will be used.
    /// If not explicitly set the persistance is set to session.
    public func twsSetBasicAuthPersistance(_ value: TWSConfig.BasicAuthPersistence) -> some View {
        self
            .task {
                TWSConfig.setBasicAuthPersistence(value)
            }
    }
}
