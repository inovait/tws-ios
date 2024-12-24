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
