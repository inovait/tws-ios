////
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

struct TWSOverlayView: View {
    var snippet: TWSSnippet
    var twsManager: TWSManager
    var dismiss: (TWSSnippet) -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            TWSView(snippet: snippet)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .twsBind(loadingView: { AnyView(TWSNotificationLoadingView()) } )
                .twsBind(preloadingView: { AnyView(TWSNotificationLoadingView()) })
            Button(action: { dismiss(snippet) }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .twsEnable(using: twsManager)
    }
}

private struct TWSNotificationLoadingView: View {
    var body: some View {
        ZStack {
            Color.white
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
