//
//  TWSStreamEvent.swift
//  TWSKit
//
//  Created by Luka Kit on 1. 7. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import TWSModels

public enum TWSStreamEvent {
    case snippetLoaded(TWSSnippet?)
    case snippetsLoaded([TWSSnippet])
}
