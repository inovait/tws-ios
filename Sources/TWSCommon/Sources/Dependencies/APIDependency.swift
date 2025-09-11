//
//  Copyright 2024 INOVA IT d.o.o.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import TWSModels
import TWSAPI
import ComposableArchitecture

@DependencyClient
public struct APIDependency: Sendable {

    public var getProject: @Sendable (
        TWSBasicConfiguration
    ) async throws(APIError) -> (TWSProject, Date?) = { _ throws(APIError) in
        reportIssue("\(Self.self).getProject")
        throw APIError.local(NSError(domain: "", code: -1))
    }

    public var getResource: @Sendable (
        TWSSnippet.Attachment, [String: String]
    ) async throws(APIError) -> ResourceResponse = { _, _ throws(APIError) in
        reportIssue("\(Self.self).loadResource")
        throw APIError.local(NSError(domain: "", code: -1))
    }
    
    public var getCampaigns: @Sendable (
        TWSBasicConfiguration,
        String
    ) async throws(APIError) -> TWSCampaign = { _, _ throws(APIError) in
        reportIssue("\(Self.self).getCampaigns")
        throw APIError.local(NSError(domain: "", code: -1))
    }
}

public enum APIDependencyKey: DependencyKey {

    public static var liveValue: APIDependency {
        let api = TWSAPIFactory.new()
        
        return .init(
            getProject: api.getProject,
            getResource: api.getResource,
            getCampaigns: api.getCampaign
        )
    }
    

    public static var testValue: APIDependency {
        .init { _ in
            return (.init(listenOn: URL(string: "http://unimplemented.com")!, snippets: []), nil)
        } getResource: { _, _ in
            return .init(responseUrl: nil, data: "")
        } getCampaigns: { _, _ in
            return .init(snippets: [])
        }
    }
}

public extension DependencyValues {

    var api: APIDependency {
        get { self[APIDependencyKey.self] }
        set { self[APIDependencyKey.self] = newValue }
    }
}
