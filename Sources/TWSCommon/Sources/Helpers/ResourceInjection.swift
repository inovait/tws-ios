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

public func injectCSS(for html: inout String, css: String) {
    let linkTag = "<style>\(css)</style>"
    
    if html.contains("<head>") {
        html = html.replacingOccurrences(of: "</head>", with: "\(linkTag)</head>")
    } else {
        if let htmlTagRegex = try? NSRegularExpression(pattern: "<html\\b[^>]*>", options: [.caseInsensitive]) {
            let range = NSRange(html.startIndex..., in: html)
            
            if let match = htmlTagRegex.firstMatch(in: html, options: [], range: range),
                let matchRange = Range(match.range, in: html) {
                let insertionIndex = matchRange.upperBound
                html.insert(contentsOf: linkTag, at: insertionIndex)
            } else {
                html = "\(html)\(linkTag)"
            }
        }
        
    }
}

public func injectJavaScript(for html: inout String, javascript: String) {
    let TWSFlag = "<script>var tws_injected = true;</script>"
    let scriptTag = "\(TWSFlag)<script>\(javascript)</script>"
    
    if html.contains("<head>") {
        html = html.replacingOccurrences(of: "</head>", with: "\(scriptTag)</head>")
    } else {
        if let htmlTagRegex = try? NSRegularExpression(pattern: "<html\\b[^>]*>", options: [.caseInsensitive]) {
            let range = NSRange(html.startIndex..., in: html)
            
            if let match = htmlTagRegex.firstMatch(in: html, options: [], range: range),
               let matchRange = Range(match.range, in: html) {
                let insertionIndex = matchRange.upperBound
                html.insert(contentsOf: scriptTag, at: insertionIndex)
            } else {
                html = "\(scriptTag)\(html)"
            }
        }
    }
}
