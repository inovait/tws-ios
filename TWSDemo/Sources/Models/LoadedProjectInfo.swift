//
//  LoadedProjectInfo.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 26. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWS

struct LoadedProjectInfo: Identifiable {

    let viewID: UUID
    let configuration: TWSConfiguration
    let viewModel: ProjectViewModel
    let selectedID: TWSSnippet.ID

    var id: String {
        "\(viewID)~\(configuration.organizationID)~\(configuration.projectID)"
    }
}
