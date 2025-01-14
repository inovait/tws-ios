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
import TWS

struct CustomPermissionExample: View {

    @Environment(TWSManager.self) var tws
    @State private var alertMsg = ""
    @State private var showAlert = false

    var body: some View {
        if let snippet = tws.snippets().first(where: { $0.id == "permissions" }) {
            TWSView(snippet: snippet)
                .twsOnDownloadCompleted { state in
                    switch state {
                    case let .completed(info):
                        var log = "Download completed successfully. File name:"
                        log += " \(info.downloadedFilename)"
                        log += ", location: \(info.downloadedLocation)"
                        alertMsg = log
                        showAlert = true

                    case let .failed(error):
                        alertMsg = error.localizedDescription
                        showAlert = true

                    @unknown default:
                        break
                    }
                }
                .alert(alertMsg, isPresented: $showAlert, actions: {})
        }
    }
}
