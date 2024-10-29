//
//  Reducer+Preloading.swift
//  TWSModels
//
//  Created by Miha Hozjan on 27. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
@_spi(InternalLibraries) import TWSModels
import ComposableArchitecture

public extension Reducer {

    func preloadResources(
        for snippet: TWSSnippet,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        let attachments = snippet.dynamicResources ?? []
        guard !attachments.isEmpty else { return [:] }

        return await _preloadResources(
            homepages: [.init(
                url: snippet.target,
                contentType: .html
            )],
            resources: attachments,
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

        guard !attachments.isEmpty else { return [:] }

        return await _preloadResources(
            homepages: project.snippets.map {
                TWSSnippet.Attachment(
                    url: $0.target,
                    contentType: .html)
            },
            resources: attachments,
            using: api
        )
    }

    func preloadResources(
        for sharedSnippet: TWSSharedSnippet,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        let attachments = sharedSnippet.snippet.dynamicResources ?? []
        guard !attachments.isEmpty else { return [:] }
        return await _preloadResources(
            homepages: [.init(
                url: sharedSnippet.snippet.target,
                contentType: .html
            )],
            resources: attachments,
            using: api
        )
    }

    private func _preloadResources(
        homepages: [TWSSnippet.Attachment],
        resources: [TWSSnippet.Attachment],
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
                        let payload = try await api.getResource(resource)
                        return (resource, payload)
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
