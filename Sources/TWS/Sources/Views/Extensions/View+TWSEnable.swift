//
//  Copyright 2024 INOVA IT d.o.o.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI

extension View {
    ///
    /// Injects instance of ``TWSManager`` into the view hierarchy. Manager is accessable via @Environment(TWSManager.self).
    /// - Parameters:
    ///   - manager: ``TWSManager`` that will be accessable via  @Environment(TWSManager.self).
    ///
    public func twsSetManager(
        using manager: TWSManager
    ) -> some View {
        return self
            .environment(manager)
            .environment(\.presenter, LivePresenter(manager: manager))
    }
    
    ///
    /// Creates an instance of ``TWSManager`` for the provided configuration and injects it into the view hierarchy.
    /// Manager is accessable via @Environment(TWSManager.self).
    /// - Parameters:
    ///   - configuration: Configuration that will determine which snippets are accessable to the ``TWSManager``.
    ///
    public func twsSetManager(
        configuration: any TWSConfiguration
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: _TWSCreateManager(
                manager: TWSFactory.new(with: configuration)
            )
        )
    }
    
    ///
    /// Connects the manager with remote services, allowing for snippet fetching, socket connections, etc.
    /// - Parameters:
    ///   - manager: ``TWSManager`` that will connect with remote services.
    ///
    public func twsRegisterManager(manager: TWSManager) -> some View {
        manager.registerTWSManager()
        return self
    }
}

private struct _TWSCreateManager: ViewModifier {

    @State private var manager: TWSManager

    init(manager: TWSManager) {
        self._manager = .init(initialValue: manager)
    }

    func body(content: Content) -> some View {
        return content
            .twsSetManager(using: manager)
    }
}
