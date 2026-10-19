//
//  WalletView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 05.10.26.
//

import AppKit
import SwiftData
import SwiftUI

struct WalletsView: View {

    @Environment(WalletRepository.self) private var repository
    @Environment(RevenueRepository.self) private var revenueRepository

    @State private var selectedWalletID: Wallet.ID?
    @State private var editorTarget: WalletEditorTarget?

    var body: some View {
        Group {
            if repository.wallets.isEmpty {
                ContentUnavailableView("No Wallets",
                                       systemImage: "wallet.bifold",
                                       description: Text("Use the add button to create your first wallet."))
            } else {
                List(selection: $selectedWalletID) {
                    if !incomingWallets.isEmpty {
                        Section("Incoming") {
                            walletRows(incomingWallets)
                        }
                    }
                    if !outgoingWallets.isEmpty {
                        Section("Outgoing") {
                            walletRows(outgoingWallets)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 640, minHeight: 400)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorTarget = WalletEditorTarget(id: UUID())
                } label: {
                    Label("Add Wallet", systemImage: "plus")
                }
                .help("Add a wallet")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editSelectedWallet()
                } label: {
                    Label("Edit Wallet", systemImage: "pencil")
                }
                .help("Edit the selected wallet")
                .disabled(selectedWallet == nil)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    deleteSelectedWallet()
                } label: {
                    Label("Delete Wallet", systemImage: "trash")
                }
                .help("Delete the selected wallet")
                .disabled(selectedWallet == nil)
            }
        }
        .sheet(item: $editorTarget) { target in
            if let wallet = target.wallet {
                WalletEditorView(editing: wallet) { editedWallet in
                    repository.update(editedWallet)
                    selectedWalletID = editedWallet.id
                }
            } else {
                WalletEditorView { newWallet in
                    repository.add(newWallet)
                    selectedWalletID = newWallet.id
                }
            }
        }
    }

    private var incomingWallets: [Wallet] {
        repository.wallets.filter(\.isIncomming)
    }

    private var outgoingWallets: [Wallet] {
        repository.wallets.filter { !$0.isIncomming }
    }

    private var selectedWallet: Wallet? {
        guard let selectedWalletID else { return nil }
        return repository.wallets.first { $0.id == selectedWalletID }
    }

    @ViewBuilder
    private func walletRows(_ wallets: [Wallet]) -> some View {
        ForEach(wallets) { wallet in
            WalletRowView(wallet: wallet)
                .tag(wallet.id)
                .overlay {
                    DoubleClickDetector {
                        beginEditing(wallet)
                    }
                }
                .contextMenu {
                    Button("Edit") {
                        beginEditing(wallet)
                    }
                    Button("Delete", role: .destructive) {
                        delete(wallet)
                    }
                }
        }
        .onDelete { offsets in
            deleteWallets(in: wallets, atOffsets: offsets)
        }
    }

    private func beginEditing(_ wallet: Wallet) {
        editorTarget = WalletEditorTarget(id: wallet.id, wallet: wallet)
    }

    private func editSelectedWallet() {
        guard let selectedWallet else { return }
        beginEditing(selectedWallet)
    }

    private func delete(_ wallet: Wallet) {
        repository.remove(wallet)
        revenueRepository.clearOrphanedConfirmations()
        if selectedWalletID == wallet.id {
            selectedWalletID = nil
        }
    }

    /// The offsets of an onDelete are relative to the section they belong to,
    /// so they are resolved against the given array before deleting.
    private func deleteWallets(in wallets: [Wallet], atOffsets offsets: IndexSet) {
        for offset in offsets.sorted(by: >)
        where wallets.indices.contains(offset) {
            delete(wallets[offset])
        }
    }

    private func deleteSelectedWallet() {
        guard let selectedWallet else { return }
        delete(selectedWallet)
    }
}

/// Identifies which wallet the editor sheet is working on. A nil wallet means a new wallet.
private struct WalletEditorTarget: Identifiable {

    let id: UUID
    let wallet: Wallet?

    init(id: UUID, wallet: Wallet? = nil) {
        self.id = id
        self.wallet = wallet
    }
}



#Preview {
    let container = try! ModelContainer(for: Revenue.self, Wallet.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let repository = WalletRepository(modelContext: container.mainContext)
    repository.add(Wallet(name: "Girokonto", imageName: "banknote.fill", isIncomming: true, color: .blue))
    repository.add(Wallet(name: "Kreditkarte", imageName: "creditcard.fill", isIncomming: false, color: .red))
    return WalletsView()
        .modelContainer(container)
        .environment(repository)
        .environment(RevenueRepository(modelContext: container.mainContext))
}
