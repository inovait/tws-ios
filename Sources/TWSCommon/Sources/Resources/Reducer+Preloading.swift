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
import TWSAPI

public extension Reducer {

    // MARK: - Loading resources

    func downloadAndInjectResources(
        for snippet: TWSSnippet,
        using api: APIDependency,
        localResources: [TWSRawDynamicResource] = []
    ) async -> Result<ResourceResponse, APIError> {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        let homepage = TWSSnippet.Attachment(
            url: snippet.target,
            contentType: .html
        )
        
        let resources = snippet.allResources(headers: &headers, homepage: homepage)
        do {
            return try await _downloadAndInjectResources(
                htmlResource: homepage,
                resources: resources,
                localResources: localResources,
                headers: headers,
                using: api
            )
        } catch let err as APIError {
            return .failure(err)
        } catch {
            logger.err("\(error)")
            return .failure(.local(error))
        }
    }

    func downloadAndInjectResources(
        for sharedSnippet: TWSSharedSnippet,
        using api: APIDependency
    ) async -> Result<ResourceResponse, APIError> {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        let homepage = TWSSnippet.Attachment.init(
            url: sharedSnippet.snippet.target,
            contentType: .html
        )
        
        let resources = sharedSnippet.allResources(headers: &headers, homepage: homepage)
        do {
            return try await _downloadAndInjectResources(
                htmlResource: homepage,
                resources: resources,
                headers: headers,
                using: api
            )
        } catch let err as APIError {
            return .failure(err)
        } catch {
            logger.err("\(error)")
            return .failure(.local(error))
        }
    }

    // MARK: - Helpers

    private func _downloadAndInjectResources(
        htmlResource: TWSSnippet.Attachment,
        resources: [TWSSnippet.Attachment],
        localResources: [TWSRawDynamicResource] = [],
        headers: [TWSSnippet.Attachment: [String: String]],
        using api: APIDependency
    ) async throws -> Result<ResourceResponse, APIError> {
        // Create two taskGroups to ensure html is fetched first, and sets the cookies, before other resources are fetched
    
        let htmlResource = try await Task {
            do {
                return try await api.getResource(htmlResource, headers[htmlResource] ?? [:])
            } catch {
                throw error
            }
        }.value
        
        let otherResources = try await withThrowingTaskGroup(
            of: (TWSSnippet.Attachment, ResourceResponse)?.self,
            returning: [TWSSnippet.Attachment: ResourceResponse].self
        ) { group in
            do {
                return try await fetchResourcesFor(Set(resources), with: headers, group: &group, using: api)
            } catch {
                throw error
            }
        }
        

        var htmlContent = htmlResource.data
        injectResources(into: &htmlContent, resources: otherResources)
        injectLocalResource(into: &htmlContent, resources: localResources)
        
        return .success(.init(responseUrl: htmlResource.responseUrl, data: htmlContent))
    }
    
    private func injectResources(into html: inout String, resources: [TWSSnippet.Attachment: ResourceResponse]) {
        resources.forEach { resource in
            switch resource.key.contentType {
            case .css:
                injectCSS(for: &html, css: resource.value.data)
            case .javascript:
                injectJavaScript(for: &html, javascript: resource.value.data)
            case .html:
                break
            }
        }
    }
    
    private func injectLocalResource(into html: inout String, resources: [TWSRawDynamicResource]) {
        resources.forEach { resource in
            switch resource {
            case .css(let css):
                injectCSS(for: &html, css: css.value)
            case .js(let js):
                injectJavaScript(for: &html, javascript: js.value)
            }
        }
    }
        
    private func fetchResourcesFor(
        _ resources: Set<TWSSnippet.Attachment>,
        with headers: [TWSSnippet.Attachment: [String: String]],
        group: inout ThrowingTaskGroup<(TWSSnippet.Attachment, ResourceResponse)?, any Error>,
        using api: APIDependency
    ) async throws -> [TWSSnippet.Attachment: ResourceResponse] {
        
        for resource in resources {
            group.addTask { [resource] in
                let payload = try await api.getResource(resource, headers[resource] ?? [:])
                if !payload.data.isEmpty { return (resource, payload) }
                return nil
            }
        }

        var results: [TWSSnippet.Attachment: ResourceResponse] = [:]
        for try await result in group {
            guard let result else { continue }
            results[result.0] = result.1
        }
        return results
    }
}

