//
//  TWSFactory.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public class TWSAPIFactory {

    public class func new(
        host: String
    ) -> TWSAPI {
        .live(host: host)
    }
}
