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
    @State private var isAddingWallet = false

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
                            .contextMenu {
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
                    isAddingWallet = true
                } label: {
                    Label("Add Wallet", systemImage: "plus")
                }
                .help("Add a wallet")
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
        .sheet(isPresented: $isAddingWallet) {
            AddWalletView { wallet in
                repository.add(wallet)
                selectedWalletID = wallet.id
            }
        }
    }

    private var selectedWallet: Wallet? {
        guard let selectedWalletID else { return nil }
        return repository.wallets.first { $0.id == selectedWalletID }
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


