//
//  DefaultMustacheProps.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 29. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//
import Foundation
import UIKit

@MainActor
struct DefaultMustacheProps {
    lazy var props: [String: Any] = {[
        "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown",
        "os": [
            "version": UIDevice.current.systemVersion
        ],
        "device": [
            "vendor": getDeviceModel()
        ]
    ]}()
    
    private func getDeviceModel() -> String {
        var utsnameInstance = utsname()
            uname(&utsnameInstance)
            let optionalString: String? = withUnsafePointer(to: &utsnameInstance.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String.init(validatingCString: ptr)
                }
            }
            return optionalString ?? "N/A"
    }
}
