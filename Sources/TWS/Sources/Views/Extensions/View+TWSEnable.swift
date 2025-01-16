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

    public func twsEnable(
        using manager: TWSManager
    ) -> some View {
        self
            .environment(manager)
            .environment(\.presenter, LivePresenter(manager: manager))
    }

    public func twsEnable(
        configuration: TWSConfiguration
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: _TWSPlaceholder(
                manager: TWSFactory.new(with: configuration)
            )
        )
    }
}

private struct _TWSPlaceholder: ViewModifier {

    @State private var manager: TWSManager

    init(manager: TWSManager) {
        self._manager = .init(initialValue: manager)
    }

    func body(content: Content) -> some View {
        content
            .twsEnable(using: manager)
    }
}
