//
//  RevenueRepository.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class RevenueRepository {

    private let modelContext: ModelContext

    private(set) var revenues: [Revenue] = []
    private(set) var lastSaveErrorMessage: String?

    var searchText: String = ""

    /// Revenues that are not yet confirmed in the wallet, reduced by the current search term.
    var filteredInboxRevenues: [Revenue] {
        let searchTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return revenues.filter { revenue in
            guard !revenue.walletConfirmed else { return false }
            guard !searchTerm.isEmpty else { return true }
            return [revenue.beneficiaryOrPayer, revenue.purpose, revenue.bookingText]
                .contains { $0.localizedCaseInsensitiveContains(searchTerm) }
        }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let descriptor = FetchDescriptor<Revenue>(sortBy: [SortDescriptor(\Revenue.bookingDate, order: .reverse)])
        revenues = (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Adds the revenue unless another one with the same id is already stored.
    /// - Returns: true if the revenue was added, false if it was skipped as a duplicate.
    @discardableResult
    func add(_ revenue: Revenue) -> Bool {
        guard insert(revenue) else { return false }
        save()
        return true
    }

    /// Adds all revenues that are not stored yet, duplicates within the batch are skipped as well.
    /// - Returns: the number of added revenues.
    @discardableResult
    func add(contentsOf newRevenues: [Revenue]) -> Int {
        var addedCount = 0
        for revenue in newRevenues {
            if insert(revenue) {
                addedCount += 1
            }
        }
        if addedCount > 0 {
            save()
        }
        return addedCount
    }

    func setWalletConfirmed(_ isConfirmed: Bool, for revenue: Revenue) {
        guard revenue.walletConfirmed != isConfirmed else { return }
        revenue.walletConfirmed = isConfirmed
        save()
    }

    func remove(_ revenue: Revenue) {
        remove(id: revenue.id)
    }

    func remove(id: Revenue.ID) {
        guard let revenue = revenues.first(where: { $0.id == id }) else { return }
        revenues.removeAll { $0.id == id }
        modelContext.delete(revenue)
        save()
    }

    func remove(at index: Int) {
        guard revenues.indices.contains(index) else { return }
        remove(id: revenues[index].id)
    }

    func remove(atOffsets offsets: IndexSet) {
        let removedRevenues = offsets.compactMap { revenues.indices.contains($0) ? revenues[$0] : nil }
        for revenue in removedRevenues {
            remove(revenue)
        }
    }

    func removeAll() {
        for revenue in revenues {
            modelContext.delete(revenue)
        }
        revenues.removeAll()
        save()
    }

    private func insert(_ revenue: Revenue) -> Bool {
        guard !revenues.contains(where: { $0.id == revenue.id }) else { return false }
        revenues.append(revenue)
        modelContext.insert(revenue)
        return true
    }

    private func save() {
        do {
            try modelContext.save()
            lastSaveErrorMessage = nil
        } catch {
            lastSaveErrorMessage = error.localizedDescription
        }
    }
}