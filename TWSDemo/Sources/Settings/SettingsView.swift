//
//  SettingsView.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit

struct SettingsView: View {

    @State private var selection: Selection = .apiResponse
    @State private var localURLs: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Source Selection")) {
                    VStack {
                        Picker("Source", selection: $selection) {
                            ForEach(Selection.allCases, id: \.self) { selection in
                                Text(selection.rawValue).tag(selection)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if selection == .localURLs {
                            TextField("Custom URLs", text: $localURLs, axis: .vertical)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        HStack {
                                            Spacer()
                                            
                                            Button("Done") {
                                                UIApplication.shared.endEditing()
                                            }
                                        }
                                    }
                                }
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                .padding(.vertical, 2)
                        }
                    }
                }

                Section(header: Text("About")) {
                    Text("v\(_appVersion())")
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .navigationTitle("Settings")
    }
}

enum Selection: String, CaseIterable {
    case apiResponse = "API Response"
    case localURLs = "Local URLs"
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
