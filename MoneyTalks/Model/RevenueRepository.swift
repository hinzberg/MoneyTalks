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

    func add(_ revenue: Revenue) {
        revenues.append(revenue)
    }

    func add(contentsOf newRevenues: [Revenue]) {
        revenues.append(contentsOf: newRevenues)
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
