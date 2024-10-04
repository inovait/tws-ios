//
//  SnippetVisibiltyTimer.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 4. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

actor SnippetVisibiltyTimer {
    private var timer: DispatchSourceTimer?

    func startTimer(queueLabel: String, duration: TimeInterval, action: @escaping () -> Void) async {
        cancelTimer()

        let queue = DispatchQueue(label: queueLabel, attributes: .concurrent)
        timer = DispatchSource.makeTimerSource(queue: queue)

        timer?.schedule(deadline: .now() + duration)
        timer?.setEventHandler { [weak self] in
            action()
            Task {
                await self?.cancelTimer()
            }
        }

        timer?.resume()
    }

    func cancelTimer() {
        timer?.cancel()
        timer = nil
    }

    func shutdown() async {
        cancelTimer()
    }
}
