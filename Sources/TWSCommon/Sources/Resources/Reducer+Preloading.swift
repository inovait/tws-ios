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
import TWSCookieManager

public extension Reducer {

    // MARK: - Loading resources

    func preloadAndInjectResources(
        for snippet: TWSSnippet,
        using api: APIDependency,
        localResources: [TWSRawDynamicResource] = []
    ) async -> [TWSSnippet.Attachment: ResourceResponse] {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        
        let resources = snippet.allResources(headers: &headers)

        return await _preloadAndInjectResources(
            resources: resources,
            localResources: localResources,
            headers: headers,
            using: api
        )
    }

    func preloadAndInjectResources(
        for project: TWSProject,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: ResourceResponse] {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        let resources = project.allResources(headers: &headers)

        return await _preloadAndInjectResources(
            resources: resources,
            headers: headers,
            using: api
        )
    }

    func preloadAndInjectResources(
        for sharedSnippet: TWSSharedSnippet,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: ResourceResponse] {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        let resources = sharedSnippet.allResources(headers: &headers)

        return await _preloadAndInjectResources(
            resources: resources,
            headers: headers,
            using: api
        )
    }

    // MARK: - Helpers

    private func _preloadAndInjectResources(
        resources: [TWSSnippet.Attachment],
        localResources: [TWSRawDynamicResource] = [],
        headers: [TWSSnippet.Attachment: [String: String]],
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: ResourceResponse] {
        let allResources = Set(resources)
        // Create two taskGroups to ensure html is fetched first, and sets the cookies, before other resources are fetched
        var htmlResources = await withTaskGroup(
            of: (TWSSnippet.Attachment, ResourceResponse)?.self,
            returning: [TWSSnippet.Attachment: ResourceResponse].self
        ) { group in
            let htmlResources = allResources.filter { res in res.contentType == .html }
            await CookieManager().syncWebViewCookiesToDevice()
            return await fetchResourcesFor(htmlResources, with: headers, group: &group, using: api)
        }
        
        let otherResources = await withTaskGroup(
            of: (TWSSnippet.Attachment, ResourceResponse)?.self,
            returning: [TWSSnippet.Attachment: ResourceResponse].self
        ) { group in
            let otherResources = allResources.filter { res in res.contentType != .html }
            return await fetchResourcesFor(otherResources, with: headers, group: &group, using: api)
        }
        
        htmlResources = htmlResources.mapValues { value in
            var modifiedData = value.data
            injectResources(into: &modifiedData, resources: otherResources)
            injectLocalResource(into: &modifiedData, resources: localResources)
            return ResourceResponse(responseUrl: value.responseUrl, data: modifiedData)
        }
        
        return htmlResources
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
        group: inout TaskGroup<(TWSSnippet.Attachment, ResourceResponse)?>,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: ResourceResponse] {
        for resource in resources {
            group.addTask { [resource] in
                do {
                    let payload = try await api.getResource(resource, headers[resource] ?? [:])
                    if !payload.data.isEmpty { return (resource, payload) }
                    return nil
                } catch {
                    return nil
                }
            }
        }

        var results: [TWSSnippet.Attachment: ResourceResponse] = [:]
        for await result in group {
            guard let result else { continue }
            results[result.0] = result.1
        }
        return results
    }
}

