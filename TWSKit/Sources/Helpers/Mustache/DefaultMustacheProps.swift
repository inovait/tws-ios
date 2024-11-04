//
//  DefaultMustacheProps.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 29. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//
import Foundation
import UIKit

class DefaultMustacheProps {

    let props: [String: Any] = {
        return [
            "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown",
            "os": [
                "version": MainActor.assumeIsolated {
                    UIDevice.current.systemVersion
                }
            ],
            "device": [
                "name": MainActor.assumeIsolated {
                    UIDevice.current.name
                },
                "vendor": "Apple"
            ]
        ]
    }()
}
