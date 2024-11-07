//
//  IsoDateFormatter.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 6. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
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
