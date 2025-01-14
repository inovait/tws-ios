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

public let isoDateDecoder = JSONDecoder.DateDecodingStrategy.custom { decoder in
    let dateFormatterRegular = ISO8601DateFormatter()
    dateFormatterRegular.formatOptions = [.withInternetDateTime]
    let dateFormatterFractional = ISO8601DateFormatter()
    dateFormatterFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let container = try decoder.singleValueContainer()
    let dateString = try container.decode(String.self)

    if let date = dateFormatterRegular.date(from: dateString) {
        return date
    } else if let date = dateFormatterFractional.date(from: dateString) {
        return date
    } else {
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid date format: \(dateString)"
        )
    }
}
