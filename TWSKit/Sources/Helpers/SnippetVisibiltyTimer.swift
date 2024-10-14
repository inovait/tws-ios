//
//  SnippetVisibiltyTimer.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 4. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

class SnippetVisibiltyTimer {
    private var timer: Timer?

    func startTimer(duration: TimeInterval, action: @escaping () -> Void) {
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { timer in
            action()
            timer.invalidate()
        }
    }

    func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
}
