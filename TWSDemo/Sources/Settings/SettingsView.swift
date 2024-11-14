//
//  SettingsView.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWS
import OSLog
import WebKit

@dynamicMemberLookup
struct Source: CustomDebugStringConvertible, Equatable {

    static let key = "com.twsdemo.source"
    static var server: Self { .init(type: .server) }
    static func local(_ urls: [URL]) -> Self { .init(type: .local(urls)) }
    let type: SourceType

    var debugDescription: String {
        switch type {
        case .server: return "Server"
        case let .local(urls): return "Local (\(urls.count))"
        }
    }

    subscript(dynamicMember keyPath: WritableKeyPath<Self, SourceType>) -> SourceType {
        get { self[keyPath: keyPath] }
        set { self[keyPath: keyPath] = newValue }
    }
}

enum SourceType: Codable, Equatable {
    case server, local([URL])
}

@MainActor
struct SettingsView: View {

    @State var viewModel = SettingsViewModel()
    @State private var cacheRemoved = false
    @AppStorage(Source.key) private var source: Source = .server
    @AppStorage("_localUrls") private var localURLs = ""
    @Environment(TWSViewModel.self) private var twsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Source Selection"),
                    footer: viewModel.invalidFootnote == nil ? nil : Text(viewModel.invalidFootnote!)
                ) {
                    VStack {
                        Picker("Source", selection: $viewModel.selection) {
                            ForEach(SettingsViewModel.Selection.allCases, id: \.self) { selection in
                                Text(selection.rawValue).tag(selection)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        if viewModel.selection == .localURLs {
                            TextField(
                                "Custom URLs",
                                text: $localURLs,
                                axis: .vertical
                            )
                            .padding()
                            .border(Color.gray, width: 1)
                            .toolbar {
                                ToolbarItemGroup(placement: .automatic) {
                                    HStack {
                                        Text("Current source: \(source.debugDescription)")

                                        Spacer()

                                        Button("Done") {
                                            switch viewModel.selection {
                                            case .apiResponse:
                                                source = .server

                                            case .localURLs:
                                                UIApplication.shared.endEditing()
                                                viewModel.validate(localURLs: localURLs)
                                                source = .local(viewModel.validUrls)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Logs")) {
                    Button(action: {
                        if viewModel.logsGenerationInProgress { return }
                        Task {
                            viewModel.logsGenerationInProgress = true
                            do {
                                let reportUrl = try await twsViewModel.manager.getLogsReport(
                                    reportFiltering: {
                                        "\($0.date.description) - \($0.category): \($0.composedMessage)"
                                    }
                                )
                                shareLogsReport(reportUrl)
                                viewModel.logsGenerationInProgress = false
                            } catch {
                                print("Unable to fetch logs: \(error)")
                                viewModel.logsGenerationInProgress = false
                            }
                        }
                    }, label: {
                        if viewModel.logsGenerationInProgress {
                            ProgressView()
                        } else {
                            Text("Get logs")
                        }
                    })
                }

                Section(header: Text("Development")) {
                    Button {
                        WKWebsiteDataStore.default().removeData(
                            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                            modifiedSince: .init(timeIntervalSince1970: 0),
                            completionHandler: {
                                Task { @MainActor in
                                    cacheRemoved.toggle()
                                }
                            }
                        )
                    } label: {
                        Text("Remove cache")
                    }
                    .alert(
                        "Cache has been removed.",
                        isPresented: $cacheRemoved,
                        actions: {
                            Button("OK") { }
                        }
                    )
                }

                Section(header: Text("About")) {
                    Text("v\(_appVersion())")
                }
            }
            .navigationTitle("Settings")
        }
        .onChange(of: viewModel.selection) { _, newValue in
            switch newValue {
            case .apiResponse:
                source = .server

            case .localURLs:
                viewModel.validate(localURLs: localURLs)
                source = .local(viewModel.validUrls)
            }
        }
        .onAppear {
            viewModel.validate(localURLs: localURLs)
        }
    }

    private func shareLogsReport(_ reportUrl: URL?) {
        if let reportUrl {
            let activityVC = UIActivityViewController(activityItems: [reportUrl], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { (_, _, _, _) in
                do {
                    try FileManager.default.removeItem(atPath: reportUrl.path())
                } catch {
                    print("Unable to delete the logs file after sharing")
                }
            }
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true, completion: nil)
            }
        }
    }
}

private func _appVersion() -> String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    return "\(version) (\(build))"
}

private extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
