//
//  TWSListView.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 7. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//
import SwiftUI
import TWSKit

public struct TWSListView: View {

    @Environment(TWSManager.self) var twsManager
    @State private var destination: Destination?

    public init() {}

    public var body: some View {
        List {
            ForEach(twsManager.snippets) { snippet in
                Button {
                    destination = .snippet(snippet)
                } label: {
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            Text(snippet.id)
                                .foregroundColor(.primary)

                            Spacer()

                            HStack(alignment: .center) {
                                if let props = _prettyJSON(from: snippet.props) {
                                    Button {
                                        destination = .props(props)
                                    } label: {
                                        Image(systemName: "list.bullet")
                                    }
                                }

                                Button {
                                    destination = .details(snippet)
                                } label: {
                                    Image(systemName: "info.circle")
                                }
                            }
                        }

                        Text(snippet.target.absoluteString)
                            .font(.caption2)
                    }
                }
            }
        }
        .sheet(item: $destination) { destination in
            switch destination {
            case let .snippet(snippet):
                TWSView(
                    snippet: snippet,
                    displayID: "list-\(snippet.id)"
                )
                .twsEnable(configuration: .init(
                    organizationID: twsManager.configuration.organizationID,
                    projectID: twsManager.configuration.projectID
                ))

            case let .details(snippet):
                NavigationView {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Status:").bold()
                            Text(snippet.status.rawValue)
                        }

                        HStack {
                            Text("Visibility:").bold()
                            Text(_visibility(for: snippet.visibility) ?? "nil")
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .navigationTitle("Details")
                }

            case let .props(json):
                NavigationView {
                    ScrollView {
                        HStack {
                            Text(json)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .navigationTitle("Props")
                }
            }
        }
    }

    private func _getValue(from props: TWSSnippet.Props) -> Any {
        switch props {
        case let .bool(value):
            return value

        case let .double(value):
            return value

        case let .int(value):
            return value

        case let .string(value):
            return value

        case let .dictionary(dict):
            var result = [AnyHashable: Any]()
            for (key, value) in dict {
                result[key] = _getValue(from: value)
            }

            return result

        case let .array(array):
            var result = [Any]()
            for value in array {
                result.append(_getValue(from: value))
            }

            return result

        @unknown default:
            return [:]
        }
    }

    private func _prettyJSON(from props: TWSSnippet.Props?) -> String? {
        guard
            let props = props,
            let json = _getValue(from: props) as? [AnyHashable: Any],
            let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        else { return nil }

        return String(data: data, encoding: .utf8)
    }

    private func _visibility(for visibility: TWSSnippet.SnippetVisibility?) -> String? {
        guard
            let visibility,
            let from = visibility.fromUtc,
            let until = visibility.untilUtc
        else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
        dateFormatter.timeZone = .current

        return "\(dateFormatter.string(from: from)) - \(dateFormatter.string(from: until))"
    }
}

extension TWSListView {

    enum Destination: Hashable, Identifiable {

        case snippet(TWSSnippet)
        case details(TWSSnippet)
        case props(String)

        var id: Int { hashValue }
    }
}

#Preview {
    TWSListView()
}
