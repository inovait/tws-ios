//
//  PropsTests.swift
//  TWSDemoTests
//
//  Created by Miha Hozjan on 21. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import Testing
import TWSModels

@Suite("Props Decoding Tests")
struct PropsTests {

    @Test(
        "Tests to ensure correct decoding by verifying that encoding the decoded result produces the same output.",
        arguments: [
            #"""
            {
                "name": "Miha Hozjan",
                "age": 18,
                "isAdmin": true,
                "additionalInfo": {
                    "address": {
                        "street": "Otroska ulica",
                        "number": 1,
                        "postCode": 9232,
                        "countryCode": "SI"
                    },
                    "height": 171.5
                },
                "friends": ["Lojze", 47, false, {"key": "value"}, ["one", "two"]]
            }
            """#,
            #"""
            {"numbers": ["one", "two"]}
            """#
        ]
    )
    func decode(props: String) async throws {
        let data = props.data(using: .utf8) ?? Data()
        let objectBefore = try #require(
            try JSONSerialization.jsonObject(
                with: data,
                options: []
            ) as? [String: AnyHashable]
        )

        // Make a round trip: Decode -> Encode -> Decode
        let decoded = try JSONDecoder().decode(
            TWSSnippet.Props.self,
            from: data
        )
        let encoded = try JSONEncoder().encode(decoded)
        let objectAfter = try JSONSerialization.jsonObject(with: encoded) as? [String: AnyHashable]

        #expect(objectBefore == objectAfter)
    }
}
