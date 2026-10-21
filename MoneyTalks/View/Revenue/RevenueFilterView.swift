//
//  RevenueFilterView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 20.10.26.
//

import SwiftData
import SwiftUI

/// Horizontal filter bar: booking date range, wallet and text. The bound
/// filter belongs to the list that shows this view, so the inbox and the
/// confirmed revenue list are filtered independently.
struct RevenueFilterView: View {

    @Binding var filter: RevenueFilter

    @Environment(WalletRepository.self) private var walletRepository

    /// Shown in the pickers while no explicit start or end date is set.
    private static let unboundedStartDate = Date(timeIntervalSince1970: 0)
    private static let unboundedEndDate = Date(timeIntervalSince1970: 4_102_444_800) // 2100-01-01

    var body: some View {
        HStack(spacing: 12) {
            DatePicker("From", selection: startDateBinding, displayedComponents: .date)
            clearButton("Remove start date") {
                filter.startDate = nil
            }

            DatePicker("To", selection: endDateBinding, displayedComponents: .date)
            clearButton("Remove end date") {
                filter.endDate = nil
            }

            Picker("Wallet", selection: $filter.walletID) {
                Text("All Wallets").tag(Wallet.ID?.none)
                ForEach(walletRepository.wallets) { wallet in
                    Text(wallet.name).tag(Wallet.ID?.some(wallet.id))
                }
            }
            .pickerStyle(.menu)

            TextField("Search", text: $filter.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 260)

            Button("Clear Filters") {
                clearFilters()
            }
            .help("Reset all filters")
            .disabled(!hasActiveFilters)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var hasActiveFilters: Bool {
        filter.startDate != nil
            || filter.endDate != nil
            || filter.walletID != nil
            || !filter.searchText.isEmpty
    }

    private func clearFilters() {
        filter = RevenueFilter()
    }

    /// DatePicker needs a non-optional binding; the wide default values stand
    /// for "no filter" until the user picks a date.
    private var startDateBinding: Binding<Date> {
        Binding(
            get: { filter.startDate ?? Self.unboundedStartDate },
            set: { filter.startDate = $0 })
    }

    private var endDateBinding: Binding<Date> {
        Binding(
            get: { filter.endDate ?? Self.unboundedEndDate },
            set: { filter.endDate = $0 })
    }

    private func clearButton(_ help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .help(help)
    }
}

#Preview {
    let container = try! ModelContainer(for: Revenue.self, Wallet.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return RevenueFilterView(filter: .constant(RevenueFilter()))
        .environment(WalletRepository(modelContext: container.mainContext))
}
