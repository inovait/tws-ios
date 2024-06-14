//
//  SettingsView.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit
import OSLog

struct SettingsView: View {

    @State var viewModel = SettingsViewModel()
    @Environment(TWSViewModel.self) private var twsViewModel

    private func logsFormatter(entry: OSLogEntryLog) -> String {
        return "\(entry.date.description) - \(entry.category): \(entry.composedMessage)"
    }

    var body: some View {
        NavigationView {
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
                                text: $viewModel.localURLs,
                                axis: .vertical
                            )
                            .padding(.horizontal)
                            .border(Color.gray, width: 1)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    HStack {
                                        Spacer()

                                        Button("Done") {
                                            UIApplication.shared.endEditing()
                                            viewModel.validate()
                                            viewModel.setSource(manager: twsViewModel.manager, source: .localURLs)
                                        }
                                    }
                                }
                            }

                        }
                    }
                }

                Section(header: Text("About")) {
                    Text("v\(_appVersion())")
                }

                Section(header: Text("Logs")) {
                    Button(action: {
                        if viewModel.logsGenerationInProgress { return }
                        Task {
                            viewModel.logsGenerationInProgress = true
                            do {
                                let reportUrl = try await twsViewModel.manager.getLogsReport(
                                    reportFiltering: logsFormatter)
                                shareLogsReport(reportUrl)
                                viewModel.logsGenerationInProgress = false
                            } catch {
                                print("Unable to fetch logs: \(error)")
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
            }
            .navigationTitle("Settings")
        }
        .onChange(of: viewModel.selection) { _, newValue in
            viewModel.setSource(manager: twsViewModel.manager, source: newValue)
        }
    }
}

private func shareLogsReport(_ reportUrl: URL?) {
    if let reportUrl {
        let activityVC = UIActivityViewController(activityItems: [reportUrl], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
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
