//
//  Logger.swift
//  TWSKit
//
//  Created by Luka Kit on 3. 6. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//
import UIKit
@_implementationOnly import TWSLogger

let logger = TWSLog(category: "TWSKit")

public func shareLogReport() {

    let reportUrl = LogReporter.generateReport()

    if let reportUrl {
        let mailActivityItemSource = MailActivityItemSource(fileURL: reportUrl)

        let activityVC = UIActivityViewController(activityItems: [mailActivityItemSource], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
}
