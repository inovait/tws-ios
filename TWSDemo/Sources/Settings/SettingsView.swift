//
//  SettingsView.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit
import TWSLogger

struct SettingsView: View {

    private func shareReport(_ url: URL) {

        let mailActivityItemSource = MailActivityItemSource(fileURL: url)

        let activityVC = UIActivityViewController(activityItems: [mailActivityItemSource], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text("v\(_appVersion())")
                Button("Get logs") {
                    Task {
                        let reportUrl = LogReporter.generateReport()
                        if let reportUrl {
                            shareReport(reportUrl)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Settings")
        }
    }
}

private func _appVersion() -> String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    return "\(version) (\(build))"
}
