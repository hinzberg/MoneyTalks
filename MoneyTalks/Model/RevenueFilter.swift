//
//  RevenueFilter.swift
//  MoneyTalks
//

import Foundation

/// Filter criteria for a revenue list. The inbox and the list of confirmed
/// revenues each keep their own instance, so filtering one list does not
/// change the other.
struct RevenueFilter: Equatable {

    /// Free text matched against beneficiary, purpose and booking text.
    var searchText: String = ""

    /// Inclusive start of the booking date range. nil means unbounded.
    var startDate: Date?

    /// Inclusive end of the booking date range. nil means unbounded.
    var endDate: Date?

    /// Only revenues of this wallet are shown. nil means all wallets.
    var walletID: Wallet.ID?

    /// True if the revenue matches all active criteria.
    func matches(_ revenue: Revenue) -> Bool {
        if let walletID, revenue.wallet?.id != walletID { return false }
        if !isWithinDateRange(revenue.bookingDate) { return false }

        let searchTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchTerm.isEmpty else { return true }
        return [revenue.beneficiaryOrPayer, revenue.purpose, revenue.bookingText]
            .contains { $0.localizedCaseInsensitiveContains(searchTerm) }
    }

    /// Start and end day are both inclusive.
    private func isWithinDateRange(_ date: Date) -> Bool {
        let calendar = Calendar.current
        if let startDate, date < calendar.startOfDay(for: startDate) {
            return false
        }
        if let endDate,
           let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)),
           date >= dayAfterEnd {
            return false
        }
        return true
    }
}
