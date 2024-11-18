//
//  TWSDownloadInfo.swift
//  TWS
//
//  Created by Luka Kit on 27. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// A struct representing data about the download that was completed
public struct TWSDownloadInfo {

    public internal(set) var downloadedFilename: String
    public internal(set) var downloadedLocation: String

    init() {
        self.downloadedFilename = ""
        self.downloadedLocation = ""
    }

    mutating func clearValues() {
        self.downloadedFilename = ""
        self.downloadedLocation = ""
    }
}
