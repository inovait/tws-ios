//
//  TWSDownloadState.swift
//  TWS
//
//  Created by Luka Kit on 23. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// An enum to define the status of an attempted download
public enum TWSDownloadState {
    /// The download failed. The first argument is the error
    case failed(Error)
    /// The download finished successfully. The first argument is the fileName and the second one is the location of the file
    case completed(TWSDownloadInfo)
}
