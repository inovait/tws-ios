//
//  SettingsViewModel.swift
//  TWSKit
//
//  Created by Miha Hozjan on 6. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSKit
import TWSModels

@Observable
class SettingsViewModel {

    var selection: Selection {
        didSet {
            UserDefaults.standard.set(
                selection.rawValue,
                forKey: "_settingsSourceSelection"
            )
        }
    }

    var localURLs: String {
        didSet {
            UserDefaults.standard.setValue(
                localURLs,
                forKey: "_settingsCustomURLs"
            )
        }
    }
    var logsGenerationInProgress: Bool = false

    var validUrls: [URL] = []
    var invalidFootnote: String?

    init() {
        if
            let value = UserDefaults.standard.string(forKey: "_settingsSourceSelection"),
            let type = Selection(rawValue: value) {
            self.selection = type
        } else {
            self.selection = .apiResponse
        }

        self.localURLs = UserDefaults.standard.string(forKey: "_settingsCustomURLs") ?? ""

        validate()
    }

    func validate() {
        var invalidUrls = [String]()
        var validUrls = [URL]()

        for line in localURLs.split(separator: "\n") {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if let url = URL(string: trimmedLine), url.scheme != nil {
                validUrls.append(url)
            } else if !trimmedLine.isEmpty {
                invalidUrls.append(trimmedLine)
            }
        }

        self.validUrls = validUrls

        if !invalidUrls.isEmpty {
            let listFormatter = ListFormatter()
            var invalidFootnote = "The following URLs will be ignored because they are not valid:"
            invalidFootnote += listFormatter.string(from: invalidUrls) ?? ""

            self.invalidFootnote = invalidFootnote
        } else {
            invalidFootnote = nil
        }
    }

    func setSource(
        manager: TWSManager,
        source: Selection
    ) {
        let twsSource: TWSSource
        switch source {
        case .apiResponse:
            twsSource = .api

        case .localURLs:
            twsSource = .customURLs(validUrls)
        }

        manager.set(source: twsSource)
    }
}

extension SettingsViewModel {

    enum Selection: String, CaseIterable {
        case apiResponse = "API Response"
        case localURLs = "Local URLs"
    }
}
