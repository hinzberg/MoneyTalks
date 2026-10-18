//
//  SettingsView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 05.10.26.
//

import SwiftData
import SwiftUI

struct SettingsView: View {

    @Environment(RevenueRepository.self) private var revenueRepository
    @Environment(WalletRepository.self) private var walletRepository

    @State private var isConfirmingDeleteRevenues = false
    @State private var isConfirmingDeleteWallets = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Revenues") {
                    Button("Delete All Revenues", role: .destructive) {
                        isConfirmingDeleteRevenues = true
                    }
                    .disabled(revenueRepository.revenues.isEmpty)
                }
                LabeledContent("Wallets") {
                    Button("Delete All Wallets", role: .destructive) {
                        isConfirmingDeleteWallets = true
                    }
                    .disabled(walletRepository.wallets.isEmpty)
                }
            } header: {
                Text("Maintenance")
            } footer: {
                Text("Deleted items cannot be recovered.")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, minHeight: 240)
        .alert("Delete All Revenues?", isPresented: $isConfirmingDeleteRevenues) {
            Button("Delete", role: .destructive) {
                revenueRepository.removeAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all \(revenueRepository.revenues.count) revenues. Wallets are not affected.")
        }
        .alert("Delete All Wallets?", isPresented: $isConfirmingDeleteWallets) {
            Button("Delete", role: .destructive) {
                walletRepository.removeAll()
                revenueRepository.clearOrphanedConfirmations()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all \(walletRepository.wallets.count) wallets. Revenues assigned to them return to the Inbox.")
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Revenue.self, Wallet.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return SettingsView()
        .environment(RevenueRepository(modelContext: container.mainContext))
        .environment(WalletRepository(modelContext: container.mainContext))
}
