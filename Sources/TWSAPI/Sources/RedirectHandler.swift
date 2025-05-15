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

import Foundation

actor RequestUrlHandler {
    private(set) var requests: [URL:Set<URL>] = .init()
    
    private(set) var pendingTasks: [URL] = []
    
    func addRequestUrl(_ requestUrl: URL, for url: URL) {
        requests.updateValue(requests[url]?.union(Set([requestUrl])) ?? Set([requestUrl]), forKey: url)
        pendingTasks.append(url)
    }
    
    func taskFinished(for url: URL) {
        pendingTasks.removeAll(where: { $0 == url })
    }
    
    func collectAndDump(for initialUrl: URL) -> Set<URL> {
        while !pendingTasks.isEmpty {
            sleep(10_000_000)
        }
        
        let temp = requests[initialUrl]
        requests.removeValue(forKey: initialUrl)
        return temp ?? Set()
    }
}

final class RedirectHandler: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    private let taskUrls = RequestUrlHandler()
    
    func collectAndDump(for url: URL) async -> Set<URL> {
        return await taskUrls.collectAndDump(for: url)
    }
    
    func urlSession(_ session: URLSession,
                        task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest,
                        completionHandler: @escaping (URLRequest?) -> Void) {
        #if DEBUG
        logger.info("Redirecting request from \(response.url?.absoluteString ?? "unknown") to \(request.url?.absoluteString ?? "unknown")")
        #endif
        var redirectedRequest = request
        Task {
            if let originalUrl = task.originalRequest?.url {
                if let url = response.url {
                    await taskUrls.addRequestUrl(url, for: originalUrl)
                }
                if let url = request.url {
                    await taskUrls.addRequestUrl(url, for: originalUrl)
                }
                await taskUrls.taskFinished(for: originalUrl)
            } else {
                logger.warn("Unknown original request url")
            }
        }
        // remove tws access token from any redirected request
        redirectedRequest.setValue(nil, forHTTPHeaderField: "x-tws-access-token")
        completionHandler(redirectedRequest)
    }
}
