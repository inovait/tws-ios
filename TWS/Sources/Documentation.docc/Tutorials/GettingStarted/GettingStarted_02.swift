//
//  GettingStarted.swift
//  
//
//  Created by Miha Hozjan on 22. 11. 24.
//

import SwiftUI
import TWS

@main
struct TWSDemoApp: App {

    var body: some Scene {
        WindowGroup {
            HomeView()
                .twsEnable(configuration: .init(
                    organizationID: "<ORGANIZATION_ID>",
                    projectID: "<PROJECT_ID>"
                ))
        }
    }
}
