//  RevenueView.swift
//  MoneyTalks
//  Created by Holger Hinzberg on 21.10.26.

import SwiftData
import SwiftUI

struct RevenueView: View {

    @Environment(RevenueRepository.self) private var repository
    @Environment(WalletRepository.self) private var walletRepository

    @State private var selectedRevenueID: Revenue.ID?
    @State private var isInspectorPresented = true

    var body: some View {
        @Bindable var repository = repository

        VStack(spacing: 0) {
            RevenueFilterView(filter: $repository.confirmedFilter)
            Divider()
            Group {
                if repository.revenues.isEmpty {
                    ContentUnavailableView("No Revenues",
                                           systemImage: "list.bullet.rectangle",
                                           description: Text("Use File ▸ Import CSV… to load transactions."))
                } else if repository.filteredConfirmedRevenues.isEmpty {
                    ContentUnavailableView("No Revenues",
                                           systemImage: "tray",
                                           description: Text("No confirmed revenues match the current filters."))
                } else {
                    List(selection: $selectedRevenueID) {
                        ForEach(repository.filteredConfirmedRevenues) { revenue in
                            RevenueRowView(revenue: revenue)
                                .tag(revenue.id)
                        }
                        .onDelete(perform: removeRevenues)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 640, minHeight: 400)
        .safeAreaInset(edge: .bottom) {
            statusBar
        }
        .onChange(of: repository.filteredConfirmedRevenues) {
            clearSelectionIfFilteredOut()
        }
        .onChange(of: walletRepository.wallets) {
            clearFilterIfWalletWasDeleted()
        }
        .inspector(isPresented: Binding(get: { isInspectorPresented }, set: { isInspectorPresented = $0 })) {
            inspector
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isInspectorPresented.toggle()
                } label: {
                    Label("Inspector", systemImage: "sidebar.trailing")
                }
                .help("Show or hide the inspector")
                .keyboardShortcut("i", modifiers: .command)
            }
        }
    }

    @ViewBuilder
    private var inspector: some View {
        if let revenue = selectedRevenue {
            RevenueDetailView(revenue: revenue)
                .inspectorColumnWidth(min: 280, ideal: 340, max: 440)
        } else {
            ContentUnavailableView("No Selection",
                                   systemImage: "sidebar.trailing",
                                   description: Text("Select a revenue to see its details."))
        }
    }

    private var selectedRevenue: Revenue? {
        guard let selectedRevenueID else { return nil }
        return repository.filteredConfirmedRevenues.first { $0.id == selectedRevenueID }
    }

    private func clearSelectionIfFilteredOut() {
        guard selectedRevenueID != nil, selectedRevenue == nil else { return }
        selectedRevenueID = nil
    }

    /// Resets the wallet filter when the filtered wallet no longer exists,
    /// otherwise the list would stay empty without a visible cause.
    private func clearFilterIfWalletWasDeleted() {
        guard let filterWalletID = repository.confirmedFilter.walletID else { return }
        if !walletRepository.wallets.contains(where: { $0.id == filterWalletID }) {
            repository.confirmedFilter.walletID = nil
        }
    }

    private func removeRevenues(atOffsets offsets: IndexSet) {
        let confirmedRevenues = repository.filteredConfirmedRevenues
        for offset in offsets where confirmedRevenues.indices.contains(offset) {
            repository.remove(id: confirmedRevenues[offset].id)
        }
    }

    /// Counted from filteredConfirmedRevenues, so the bar refreshes when
    /// revenues are added, removed or filtered out.
    private var statusText: String {
        let filtered = repository.filteredConfirmedRevenues
        let itemLabel = filtered.count == 1 ? "item" : "items"
        let total = filtered.reduce(Decimal.zero) { $0 + $1.amount }
        return "\(filtered.count) \(itemLabel) · \(total.formatted(.currency(code: currencyCode)))"
    }

    /// All revenues are expected to share the same currency; the first one
    /// of the list defines it.
    private var currencyCode: String {
        repository.filteredConfirmedRevenues.first?.currency ?? "EUR"
    }

    @ViewBuilder
    private var statusBar: some View {
        Text(statusText)
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(.bar)
            .overlay(alignment: .top) {
                Divider()
            }
    }
}

#Preview {
    let container = try! ModelContainer(for: Revenue.self, Wallet.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return RevenueView()
        .environment(RevenueRepository(modelContext: container.mainContext))
        .environment(WalletRepository(modelContext: container.mainContext))
}
