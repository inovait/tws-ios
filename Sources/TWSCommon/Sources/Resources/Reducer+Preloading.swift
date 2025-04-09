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
@_spi(Internals) import TWSModels
import ComposableArchitecture

public extension Reducer {

    // MARK: - Loading resources

    func preloadResources(
        for snippet: TWSSnippet,
        using api: APIDependency,
        withHeaders localHeaders: [String: String] = [:]
    ) async -> [TWSSnippet.Attachment: String] {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        let resources = snippet.allResources(headers: &headers, localHeaders: localHeaders)
        return await _preloadResources(
            resources: resources,
            headers: headers,
            using: api
        )
    }

    func preloadResources(
        for project: TWSProject,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        let resources = project.allResources(headers: &headers)

        return await _preloadResources(
            resources: resources,
            headers: headers,
            using: api
        )
    }

    func preloadResources(
        for sharedSnippet: TWSSharedSnippet,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        let resources = sharedSnippet.allResources(headers: &headers)

        return await _preloadResources(
            resources: resources,
            headers: headers,
            using: api
        )
    }

    // MARK: - Helpers

    private func _preloadResources(
        resources: [TWSSnippet.Attachment],
        headers: [TWSSnippet.Attachment: [String: String]],
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        return await withTaskGroup(
            of: (TWSSnippet.Attachment, String)?.self,
            returning: [TWSSnippet.Attachment: String].self
        ) { [api] group in
            // Use a set to download each resource only once, even if it is used in multiple snippets
            for resource in Set(resources) {
                group.addTask { [resource] in
                    do {
                        let payload = try await api.getResource(resource, headers[resource] ?? [:])
                        if !payload.isEmpty { return (resource, payload) }
                        return nil
                    } catch {
                        return nil
                    }
                }
            }

            var results: [TWSSnippet.Attachment: String] = [:]
            for await result in group {
                guard let result else { continue }
                results[result.0] = result.1
            }

            return results
        }
    }
}
