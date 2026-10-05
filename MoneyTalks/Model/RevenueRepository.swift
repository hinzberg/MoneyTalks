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

    var searchText: String = ""

    var filteredRevenues: [Revenue] {
        let searchTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchTerm.isEmpty else { return revenues }
        return revenues.filter { revenue in
            [revenue.beneficiaryOrPayer, revenue.purpose, revenue.bookingText]
                .contains { $0.localizedCaseInsensitiveContains(searchTerm) }
        }
    }

    /// Adds the revenue unless another one with the same id is already stored.
    /// - Returns: true if the revenue was added, false if it was skipped as a duplicate.
    func add(_ revenue: Revenue) -> Bool {
        guard !revenues.contains(where: { $0.id == revenue.id }) else { return false }
        revenues.append(revenue)
        return true
    }

    /// Adds all revenues that are not stored yet, duplicates within the batch are skipped as well.
    /// - Returns: the number of added revenues.
    func add(contentsOf newRevenues: [Revenue]) -> Int {
        var addedCount = 0
        for revenue in newRevenues {
            if add(revenue) {
                addedCount += 1
            }
        }
        return addedCount
    }

    func remove(_ revenue: Revenue) {
        revenues.removeAll { $0 == revenue }
    }

    func remove(id: Revenue.ID) {
        revenues.removeAll { $0.id == id }
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
