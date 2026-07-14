//
//  TWSConfig.swift
//  TWS
//
//  Created by Sven Kotnik on 4. 5. 26.
//

import Foundation

@MainActor
public final class TWSConfig {
    static let shared = TWSConfig()
    
    private var basicAuthPersistence: BasicAuthPersistence = .session
    
    private init() {}
    
    
    public static func setBasicAuthPersistence(_ persistence: BasicAuthPersistence) {
        shared.basicAuthPersistence = persistence
    }
    
    public static func getBasicAuthPersistence() -> BasicAuthPersistence {
        shared.basicAuthPersistence
    }
    
    public enum BasicAuthPersistence {
        case session
        case keychain
    }
}
