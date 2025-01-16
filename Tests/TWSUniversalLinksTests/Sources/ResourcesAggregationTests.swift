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

import XCTest
@testable import TWSUniversalLinks
@testable import TWSCommon
@testable @_spi(Internals) import TWSModels
@testable import ComposableArchitecture

final class ResourcesAggregationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAggregateResourcesUniversalLink() async throws {
        let url = URL(string: "https://thewebsnippet.dev/shared/abc123")!
        let attachments: [TWSSnippet.Attachment] = [
            .init(
                url: URL(string: "https://www.r1.com")!,
                contentType: .javascript
            ),
            .init(
                url: URL(string: "https://www.r2.com")!,
                contentType: .css
            ),
            .init(
                url: URL(string: "https://www.r3.com")!,
                contentType: .javascript
            ),
            .init(
                url: URL(string: "https://www.r4.com")!,
                contentType: .css
            )
        ]

        var preloadedAttachments = Dictionary(
            uniqueKeysWithValues:
                attachments.map {
                    ($0, $0.url.absoluteString)
                }
        )

        preloadedAttachments[.init(
            url: url,
            contentType: .html
        )] = url.absoluteString

        let listenOn = URL(string: "https://listen.here.com")!
        let project = TWSProject(
            listenOn: listenOn,
            snippets: [
                .init(
                    id: "00000000-0000-0000-0000-000000000002",
                    target: url,
                    dynamicResources: attachments
                )
            ]
        )

        let store = await TestStore(
            initialState: .init(),
            reducer: { TWSUniversalLinksFeature() }
            ,
            withDependencies: {
                $0.api.getSharedToken = { @Sendable _, _ in return "" }
                $0.api.getSnippetBySharedToken = { @Sendable (_: TWSConfiguration, _: String) in return project }
                $0.api.getResource = { attachment, _ in return attachment.url.absoluteString }
            }
        )

        await store.send(.business(.onUniversalLink(url))).finish()
        await store.receive(\.business.snippetLoaded.success, project)

        await store.receive(
            \.delegate.snippetLoaded,
             project
        )
    }
}
