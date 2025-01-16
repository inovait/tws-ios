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
internal import Mustache

class MustacheRenderer {

    func convertDictPropsToData(_ snippetProps: TWSSnippet.Props?) -> [String: Any] {
        var mustacheProps: [String: Any] = [:]
        if let snippetProps {
            if case .dictionary(let props) = snippetProps {
                props.forEach { prop in
                    if case .dictionary = prop.value {
                        mustacheProps[prop.key] = convertDictPropsToData(prop.value)
                    } else if case .string(let value) = prop.value {
                        mustacheProps[prop.key] = value
                    } else if case .int(let value) = prop.value {
                        mustacheProps[prop.key] = value
                    } else if case .double(let value) = prop.value {
                        mustacheProps[prop.key] = value
                    } else if case .bool(let value) = prop.value {
                        mustacheProps[prop.key] = value
                    } else if case .array(let value) = prop.value {
                        var arrayOfConverted: [Any] = []
                        value.forEach { arrayProp in
                            if case .dictionary = arrayProp {
                                arrayOfConverted.append(convertDictPropsToData(arrayProp))
                            } else if case .string(let value) = arrayProp {
                                arrayOfConverted.append(value)
                            } else if case .int(let value) = arrayProp {
                                arrayOfConverted.append(value)
                            } else if case .double(let value) = arrayProp {
                                arrayOfConverted.append(value)
                            } else if case .bool(let value) = arrayProp {
                                arrayOfConverted.append(value)
                            } else if case .array = arrayProp {
                                arrayOfConverted.append(convertDictPropsToData(arrayProp))
                            }
                        }
                        mustacheProps[prop.key] = arrayOfConverted
                    }
                }
            }
        }
        return mustacheProps
    }

    func renderMustache(_ html: String, _ data: [String: Any], addDefaultValues: Bool) -> String {
        do {
            var mustacheConfiguration = Configuration()
            mustacheConfiguration.contentType = .text
            let template = try Template(string: html, configuration: mustacheConfiguration)
            var mustacheValues: [String: Any] = [:]
            if addDefaultValues {
                let defaultMustacheValues = DefaultMustacheProps().props
                mustacheValues = data.merging(defaultMustacheValues) { (_, new) in new }
            } else {
                mustacheValues = data
            }
            return try template.render(mustacheValues)
        } catch {
            logger.err("Mustache render failed: \(error)")
            return html
        }
    }
}
