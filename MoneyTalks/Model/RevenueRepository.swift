//
//  RevenueRepository.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import Foundation
import Observation

@Observable
@MainActor
final class RevenueRepository {

    private(set) var revenues: [Revenue] = []

    func add(_ revenue: Revenue) {
        revenues.append(revenue)
    }

    func add(contentsOf newRevenues: [Revenue]) {
        revenues.append(contentsOf: newRevenues)
    }

    func remove(_ revenue: Revenue) {
        revenues.removeAll { $0 == revenue }
    }

    func remove(at index: Int) {
        guard revenues.indices.contains(index) else { return }
        revenues.remove(at: index)
    }

    func remove(atOffsets offsets: IndexSet) {
        for index in offsets.reversed() {
            remove(at: index)
        }
    }

    func removeAll() {
        revenues.removeAll()
    }
}
