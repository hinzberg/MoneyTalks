//
//  RevenueFilterView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 20.10.26.
//

import SwiftData
import SwiftUI

/// Horizontal filter bar for the inbox: booking date range, wallet and text.
/// The state lives on RevenueRepository, so the list, the status bar and the
/// selection all react to changes automatically.
struct RevenueFilterView: View {

    @Environment(RevenueRepository.self) private var repository
    @Environment(WalletRepository.self) private var walletRepository

    /// Shown in the pickers while no explicit start or end date is set.
    private static let unboundedStartDate = Date(timeIntervalSince1970: 0)
    private static let unboundedEndDate = Date(timeIntervalSince1970: 4_102_444_800) // 2100-01-01

    var body: some View {
        @Bindable var repository = repository

        HStack(spacing: 12) {
            DatePicker("From", selection: startDateBinding, displayedComponents: .date)
            clearButton("Remove start date") {
                repository.filterStartDate = nil
            }

            DatePicker("To", selection: endDateBinding, displayedComponents: .date)
            clearButton("Remove end date") {
                repository.filterEndDate = nil
            }

            Picker("Wallet", selection: $repository.filterWalletID) {
                Text("All Wallets").tag(Wallet.ID?.none)
                ForEach(walletRepository.wallets) { wallet in
                    Text(wallet.name).tag(Wallet.ID?.some(wallet.id))
                }
            }
            .pickerStyle(.menu)

            TextField("Search", text: $repository.searchText)
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
        repository.filterStartDate != nil
            || repository.filterEndDate != nil
            || repository.filterWalletID != nil
            || !repository.searchText.isEmpty
    }

    private func clearFilters() {
        repository.filterStartDate = nil
        repository.filterEndDate = nil
        repository.filterWalletID = nil
        repository.searchText = ""
    }

    /// DatePicker needs a non-optional binding; the wide default values stand
    /// for "no filter" until the user picks a date.
    private var startDateBinding: Binding<Date> {
        Binding(
            get: { repository.filterStartDate ?? Self.unboundedStartDate },
            set: { repository.filterStartDate = $0 })
    }

    private var endDateBinding: Binding<Date> {
        Binding(
            get: { repository.filterEndDate ?? Self.unboundedEndDate },
            set: { repository.filterEndDate = $0 })
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
    return RevenueFilterView()
        .environment(RevenueRepository(modelContext: container.mainContext))
        .environment(WalletRepository(modelContext: container.mainContext))
}
