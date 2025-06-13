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

import TWSModels

/// Events that are sent to ``TWSManager`` regarding updates
public enum TWSStreamEvent: Sendable {

    /// This event is sent when a project from the universal link is processed
    /// - Parameter TWSSharedConfiguration: A configuration with the corresponding shared id, for the recieved url
    case universalLinkConfigurationLoaded(TWSSharedConfiguration)

    /// This event is sent when there are new snippets available
    case snippetsUpdated

    /// This event is triggered when there is a change in the snippet loading state.
    case stateChanged
    
    /// This event is triggered when campaign was triggered
    case shouldOpenCampaign
}
