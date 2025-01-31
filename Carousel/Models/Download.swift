//
//  Download.swift
//  Carousel
//
//  Created by Robert Ryan on 1/30/25.
//

import Foundation
import os.lock

// MARK: - Realtime download state enumeration

extension CarouselViewController {
    enum DownloadState: Hashable, Equatable, CustomStringConvertible {
        case notStarted
        case inProgress(Float)
        case finished
        case cancelled
        case failed

        var description: String {
            switch self {
            case .notStarted:               "Not Started"
            case .inProgress(let progress): "In Progress (\((progress * 100).formatted(.number.precision(.fractionLength(1))))%)"
            case .finished:                 "Finished"
            case .cancelled:                "Cancelled"
            case .failed:                   "Failed"
            }
        }
    }
}

// MARK: - Realtime download state

extension CarouselViewController {
    @MainActor
    class Download: ObservableObject {
        let item: Item

        @Published private(set) var state: DownloadState = .notStarted

        private var task: Task<Void, Never>?

        init(item: Item) {
            self.item = item
        }

        func start() {
            if case .inProgress = state {
                return
            }

            task?.cancel()
            task = Task {
                do {
                    for progress in 0..<100 {
                        state = .inProgress(Float(progress) / 100)
                        try await Task.sleep(for: .seconds(0.1))
                    }

                    state = .finished
                } catch {
                    state = .cancelled
                }
            }
        }

        func cancel() {
            guard case .inProgress = state else {
                return
            }

            task?.cancel()
            task = nil
        }
    }
}
