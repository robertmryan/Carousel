//
//  Download.swift
//  Carousel
//
//  Created by Robert Ryan on 1/30/25.
//

import Foundation

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
    class Download: ObservableObject, Identifiable {
        var id: Item.ID { item.id }
        let item: Item
        @Published var state: DownloadState = .notStarted

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
                        try await Task.sleep(for: .seconds(1))
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

// MARK: - CarouselViewController.Download: Equatable

extension CarouselViewController.Download: Equatable {
    static func == (lhs: CarouselViewController.Download, rhs: CarouselViewController.Download) -> Bool {
        lhs.item == rhs.item && lhs.state == rhs.state
    }
}

// MARK: - CarouselViewController.Download: Hashable

extension CarouselViewController.Download: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(item)
        hasher.combine(state)
    }
}
