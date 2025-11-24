////
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
import WebKit

class TWSNavigationHandler {
    var navigationEvent: TWSNavigationEvent?
    
    func finishNavigationEvent() -> WKNavigation? {
        let navigation = navigationEvent?.getNavigation()
        navigationEvent = nil
        return navigation
    }
}

class TWSNavigationEvent: AutoPrintable {
    private var url: URL = URL(string: "about:blank")!
    private var type: TWSNavigationEventType = .idle
    
    private var navigation: WKNavigation?
    
    init() {}
    
    init(url: URL, type: TWSNavigationEventType) {
        self.url = url
        self.type = type
    }
    
    func getNavigation() -> WKNavigation? {
        return navigation
    }
    
    func setNavigation(_ navigation: WKNavigation?) {
        self.navigation = navigation
    }
    
    func isReload(navigation: WKNavigation) -> Bool {
        self.navigation === navigation && type == .pullToRefresh || type == .reload
    }
    
    func isSPA(navigation: WKNavigation) -> Bool {
        return self.navigation === navigation && type == .spa
    }
}

enum TWSNavigationEventType {
    case idle
    case pullToRefresh
    case reload
    case load
    case spa
}

protocol AutoPrintable: CustomStringConvertible {}

extension AutoPrintable {
    var description: String {
        let mirror = Mirror(reflecting: self)

        let props = mirror.children.compactMap { child -> String? in
            guard let label = child.label else { return nil }
            return "\(label): \(child.value)"
        }
        .joined(separator: ", ")

        return "\(type(of: self))(\(props))"
    }
}
