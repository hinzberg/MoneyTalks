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

    let modelContext: ModelContext

    private(set) var revenues: [Revenue] = []
    private(set) var lastSaveErrorMessage: String?

    var searchText: String = ""

    /// Inclusive start of the booking date range. nil means unbounded.
    var filterStartDate: Date?

    /// Inclusive end of the booking date range. nil means unbounded.
    var filterEndDate: Date?

    /// Only revenues of this wallet are shown. nil means all wallets.
    var filterWalletID: Wallet.ID?

    /// Revenues that are not yet confirmed in the wallet, reduced by the
    /// active filters (wallet, booking date range and search term).
    var filteredInboxRevenues: [Revenue] {
        let searchTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return revenues.filter { revenue in
            guard !revenue.walletConfirmed else { return false }
            if let filterWalletID, revenue.wallet?.id != filterWalletID { return false }
            if !isWithinDateRange(revenue.bookingDate) { return false }
            guard !searchTerm.isEmpty else { return true }
            return [revenue.beneficiaryOrPayer, revenue.purpose, revenue.bookingText]
                .contains { $0.localizedCaseInsensitiveContains(searchTerm) }
        }
    }

    /// Start and end day are both inclusive.
    private func isWithinDateRange(_ date: Date) -> Bool {
        let calendar = Calendar.current
        if let filterStartDate, date < calendar.startOfDay(for: filterStartDate) {
            return false
        }
        if let filterEndDate,
           let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: filterEndDate)),
           date >= dayAfterEnd {
            return false
        }
        return true
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

    /// Assigns the given wallet, or clears the assignment when nil.
    /// Clearing the wallet also switches off the confirmation, because a
    /// revenue cannot be confirmed into a wallet that is not selected.
    func setWallet(_ wallet: Wallet?, for revenue: Revenue) {
        guard revenue.wallet?.id != wallet?.id else { return }
        revenue.wallet = wallet
        if wallet == nil && revenue.walletConfirmed {
            revenue.walletConfirmed = false
        }
        save()
    }

    func setWalletConfirmed(_ isConfirmed: Bool, for revenue: Revenue) {
        guard revenue.walletConfirmed != isConfirmed else { return }
        revenue.walletConfirmed = isConfirmed
        save()
    }

    func setNote(_ note: String, for revenue: Revenue) {
        guard revenue.note != note else { return }
        revenue.note = note
        save()
    }

    /// Revokes the confirmation of every revenue that has no wallet assigned.
    /// Call this after deleting wallets: the store unassigns them automatically,
    /// but a confirmed revenue would otherwise stay hidden from the inbox.
    func clearOrphanedConfirmations() {
        var changed = false
        for revenue in revenues where revenue.walletConfirmed && revenue.wallet == nil {
            revenue.walletConfirmed = false
            changed = true
        }
        if changed {
            save()
        }
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