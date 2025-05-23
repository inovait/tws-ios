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

import Foundation

/// A struct representing data about a completed download.
///
/// This struct holds information about the file that was downloaded, including its filename and location.
///
/// > Important: If you download a file through the ``TWSView``, the file will be stored in the app's documents directory.
/// By default, that folder is private, but you have two options available to manage access to the downloaded file:
/// > 1. **Make your documents public:**
///    Update your app's `Info.plist` file to include the key `UIFileSharingEnabled` set to `true`.
///    If you have used the provided project generator, this setting is already enabled.
/// > 2. **Check the download completed callback:**
///    When a download completes successfully, you'll receive an instance of ``TWSDownloadInfo`` in the callback provided to ``SwiftUICore/View/twsOnDownloadCompleted(action:)``.
///    This instance includes the full path to the downloaded file, allowing you to move it to a location of your choice.
///
/// ## Example
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         TWSView()
///             .twsOnDownloadCompleted { downloadState in
///                 switch downloadState {
///                 case .completed(let info):
///                     print("File downloaded to: \(info.downloadedLocation)")
///                     // Move the file to another directory if needed
///                 case .failed(let error):
///                     print("Download failed: \(error)")
///                 }
///             }
///     }
/// }
/// ```
public struct TWSDownloadInfo {

    /// The name of the downloaded file.
    public internal(set) var downloadedFilename: String

    /// The location where the downloaded file was saved.
    public internal(set) var downloadedLocation: String

    /// Initializes a new instance of `TWSDownloadInfo` with default empty values.
    init() {
        self.downloadedFilename = ""
        self.downloadedLocation = ""
    }

    mutating func clearValues() {
        self.downloadedFilename = ""
        self.downloadedLocation = ""
    }
}
