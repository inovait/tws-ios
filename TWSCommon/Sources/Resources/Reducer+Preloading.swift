//
//  Reducer+Preloading.swift
//  TWSModels
//
//  Created by Miha Hozjan on 27. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
@_spi(Internals) import TWSModels
import ComposableArchitecture

public extension Reducer {

    func preloadResources(
        for snippet: TWSSnippet,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        let attachments = snippet.dynamicResources ?? []
        let homepage = TWSSnippet.Attachment.init(
            url: snippet.target,
            contentType: .html
        )

        return await _preloadResources(
            homepages: [homepage],
            resources: attachments,
            headers: [homepage: snippet.headers ?? [:]],
            using: api
        )
    }

    func preloadResources(
        for project: TWSProject,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        let attachments = project.snippets
            .compactMap(\.dynamicResources)
            .flatMap { $0 }
        var homepages = [TWSSnippet.Attachment]()
        var headers = [TWSSnippet.Attachment:[String:String]]()
        project.snippets.forEach { snippet in
            let homepage = TWSSnippet.Attachment(
                url: snippet.target,
                contentType: .html)
            homepages.append(homepage)
            headers[homepage] = snippet.headers
        }

        return await _preloadResources(
            homepages: homepages,
            resources: attachments,
            headers: headers,
            using: api
        )
    }

    func preloadResources(
        for sharedSnippet: TWSSharedSnippet,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        let homepage = TWSSnippet.Attachment(
            url: sharedSnippet.snippet.target,
            contentType: .html
        )
        let attachments = sharedSnippet.snippet.dynamicResources ?? []
        let headers = [homepage: sharedSnippet.snippet.headers ?? [:]]
        return await _preloadResources(
            homepages: [homepage],
            resources: attachments,
            headers: headers,
            using: api
        )
    }

    private func _preloadResources(
        homepages: [TWSSnippet.Attachment],
        resources: [TWSSnippet.Attachment],
        headers: [TWSSnippet.Attachment: [String:String]],
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        return await withTaskGroup(
            of: (TWSSnippet.Attachment, String)?.self,
            returning: [TWSSnippet.Attachment: String].self
        ) { [api] group in
            // Use a set to download each resource only once, even if it is used in multiple snippets
            for resource in Set(homepages + resources) {
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
