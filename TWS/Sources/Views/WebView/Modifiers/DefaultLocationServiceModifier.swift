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

private struct DefaultLocationServiceModifier: ViewModifier {

    let locationServicesBridge: LocationServicesBridge
    let snippet: TWSSnippet
    let displayID: String

    func body(content: Content) -> some View {
        content
            // Default Location Services implementation - start on appear
            .onAppear {
                guard let bridge = _unbox() else { return }
                bridge.didAppear(snippet: snippet, displayID: displayID)
            }
            // Default Location Services implementation - stop on dissappear
            .onDisappear {
                guard let bridge = _unbox() else { return }
                bridge.didDisappear(snippet: snippet, displayID: displayID)
            }
            // Stop on background transition
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.didEnterBackgroundNotification
                ),
                perform: { _ in
                    guard let bridge = _unbox() else { return }
                    bridge.onBackgroundTransition()
                }
            )
            // Resume on foreground transition
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification
                ),
                perform: { _ in
                    guard let bridge = _unbox() else { return }
                    bridge.onForegroundTransition()
                }
            )

    }

    private func _unbox() -> DefaultLocationServicesManager? {
        guard
            let locationServicesBridge = locationServicesBridge as? DefaultLocationServicesManager
        else {
            return nil
        }

        return locationServicesBridge
    }
}

extension View {

    func conditionallyActivateDefaultLocationBehavior(
        locationServicesBridge: LocationServicesBridge,
        snippet: TWSSnippet,
        displayID: String
    ) -> some View {
        self.modifier(DefaultLocationServiceModifier(
            locationServicesBridge: locationServicesBridge,
            snippet: snippet,
            displayID: displayID
        ))
    }
}
