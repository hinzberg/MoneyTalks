//
//  WalletView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 05.10.26.
//

import SwiftData
import SwiftUI

struct WalletsView: View {

    @Environment(WalletRepository.self) private var repository

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
                    ForEach(repository.wallets) { wallet in
                        WalletRowView(wallet: wallet)
                            .tag(wallet.id)
                            .simultaneousGesture(TapGesture(count: 2).onEnded {
                                beginEditing(wallet)
                            })
                            .contextMenu {
                                Button("Edit") {
                                    beginEditing(wallet)
                                }
                                Button("Delete", role: .destructive) {
                                    delete(wallet)
                                }
                            }
                    }
                    .onDelete(perform: repository.remove(atOffsets:))
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

    private var selectedWallet: Wallet? {
        guard let selectedWalletID else { return nil }
        return repository.wallets.first { $0.id == selectedWalletID }
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
        if selectedWalletID == wallet.id {
            selectedWalletID = nil
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

private struct WalletRowView: View {

    let wallet: Wallet

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: wallet.imageName)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(wallet.color, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(wallet.name)
                    .font(.title3)
                    .lineLimit(1)
                Text(wallet.isIncomming ? "Incoming" : "Outgoing")
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
        }
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
}