//
//  NavigationError.swift
//  TWSCommon
//
//  Created by Miha Hozjan on 1. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

enum NavigationError: Error {

    case parentNotFound
    case viewControllerNotFound
    case presentedViewControllerNotFound
    case alreadyPresenting
}
