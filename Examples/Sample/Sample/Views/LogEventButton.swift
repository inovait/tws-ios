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

import SwiftUI

struct LogEventButton: View {
    @State private var isOpened = false
    @State private var timer: Timer?
    var logEvent: () -> Void
    
    var body: some View {
        Button { logEvent() } label: {
            HStack {
                if isOpened {
                    Text("Try Logging Your First Event")
                        .font(.callout)
                    Spacer()
                }
                Image(systemName: "list.clipboard")
                    .rotationEffect(isOpened ? .degrees(360) : .degrees(0))
            }
            .padding()
        }
        .frame(maxWidth: isOpened ? .infinity : 40, maxHeight: isOpened ? 50 : 40)
        .background(.gray.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .foregroundStyle(.white)
        .padding(.vertical, 24)
        .padding(.horizontal, isOpened ? 64 : 8)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .animation(.easeInOut, value: isOpened)
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            self.isOpened.toggle()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    LogEventButton(logEvent: {})
}
