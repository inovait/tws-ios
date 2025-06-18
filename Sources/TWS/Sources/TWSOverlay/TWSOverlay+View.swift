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

struct TWSOverlayView: View, Identifiable {
    var id: String
    var overlayData: TWSOverlayData
    var dismiss: (_ id: String) -> Void
    
    var presenter: TWSPresenter {
        switch overlayData.type {
        case .notificaion:
            return LivePresenter(manager: overlayData.manager)
        case .campaign:
            return CampaignPresenter(manager: overlayData.manager)
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            TWSView(snippet: overlayData.snippet)
                .twsBind(loadingView: { AnyView(TWSNotificationLoadingView()) } )
                .twsBind(preloadingView: { AnyView(TWSNotificationLoadingView()) })
                .environment(\.presenter, presenter)
            
            Button(action: { dismiss(id) }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.gray.opacity(0.7))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .twsRegister(using: overlayData.manager)
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
