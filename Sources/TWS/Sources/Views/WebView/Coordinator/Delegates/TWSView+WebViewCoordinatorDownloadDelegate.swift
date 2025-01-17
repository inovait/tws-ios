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
@preconcurrency import WebKit

extension WebView.Coordinator: WKDownloadDelegate {

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping @MainActor @Sendable  (URL?) -> Void
    ) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.err("Can't find documents directory")
            completionHandler(nil)
            return
        }

        let downloadsFolderURL = documentsURL.appendingPathComponent("Downloads")

        if !FileManager.default.fileExists(atPath: downloadsFolderURL.path) {
            do {
                try FileManager.default.createDirectory(
                    at: downloadsFolderURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                logger.err("Failed to create downloads folder: \(error)")
                completionHandler(nil)
                return
            }
        }
        let fileName = downloadsFolderURL.appendingPathComponent(suggestedFilename)

        downloadInfo.downloadedFilename = suggestedFilename
        downloadInfo.downloadedLocation = downloadsFolderURL.absoluteString
        completionHandler(fileName)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        logger.warn("Download failed with error: \(error.localizedDescription)")
        downloadCompleted?(.failed(error))
        downloadInfo.clearValues()
    }

    func downloadDidFinish(_ download: WKDownload) {
        var log = "Download completed successfully. File name:"
        log += " \(downloadInfo.downloadedFilename)"
        log += ", location: \(downloadInfo.downloadedLocation)"
        logger.info(log)

        downloadCompleted?(.completed(downloadInfo))
        downloadInfo.clearValues()
    }
}
