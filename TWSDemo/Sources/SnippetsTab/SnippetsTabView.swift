//
//  SnippetsTabView.swift
//  TWSKit
//
//  Created by Miha Hozjan on 5. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSKit

struct SnippetsTabView: View {

    @Environment(TWSViewModel.self) private var twsViewModel
    @State private var selectedId: UUID?

    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    ForEach(
                        Array(zip(twsViewModel.snippets.indices, twsViewModel.snippets)),
                        id: \.1.id
                    ) { idx, snippet in
                        ScrollView {
                            TWSView(
                                snippet: snippet,
                                using: twsViewModel.manager,
                                displayID: "tab-\(snippet.id.uuidString)"
                            )
                            .border(Color.black)
                        }
                        .zIndex(Double(selectedId == snippet.id ? twsViewModel.snippets.count : idx))
                        .opacity(selectedId != snippet.id ? 0 : 1)
                    }
                }

                ViewThatFits {
                    _selectionView()

                    ScrollView(.horizontal, showsIndicators: false) {
                        _selectionView()
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .onAppear {
                // Safe to force cast, because of the first segment
                guard selectedId == nil || !twsViewModel.snippets.map(\.id).contains(selectedId!) else { return }
                selectedId = twsViewModel.snippets.first?.id
            }
        }
    }

    @ViewBuilder
    private func _selectionView() -> some View {
        if twsViewModel.snippets.count > 1 {
            HStack(spacing: 1) {
                ForEach(Array(zip(twsViewModel.snippets.indices, twsViewModel.snippets)), id: \.1.id) { idx, item in
                    Button {
                        selectedId = item.id
                    } label: {
                        VStack {
                            Text("\(idx + 1)")
                                .font(.title)
                                .foregroundColor(selectedId == item.id ? Color.accentColor : Color.gray)

                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(height: selectedId == item.id ? 1 : 0)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 1)
                        }
                        .frame(minWidth: 75, maxWidth: .infinity)
                    }
                }
            }
        }
    }
}
