//
//  WalletRepository.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class WalletRepository {

    private let modelContext: ModelContext

    private(set) var wallets: [Wallet] = []
    private(set) var lastSaveErrorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let descriptor = FetchDescriptor<Wallet>(sortBy: [SortDescriptor(\Wallet.name)])
        wallets = (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Adds the wallet unless another one with the same id is already stored.
    /// - Returns: true if the wallet was added, false if it was skipped as a duplicate.
    @discardableResult
    func add(_ wallet: Wallet) -> Bool {
        guard insert(wallet) else { return false }
        save()
        return true
    }

    /// Adds all wallets that are not stored yet, duplicates within the batch are skipped as well.
    /// - Returns: the number of added wallets.
    @discardableResult
    func add(contentsOf newWallets: [Wallet]) -> Int {
        var addedCount = 0
        for wallet in newWallets {
            if insert(wallet) {
                addedCount += 1
            }
        }
        if addedCount > 0 {
            save()
        }
        return addedCount
    }

    /// Copies the values of the given wallet onto the stored wallet with the same id.
    /// - Returns: true if a wallet with that id was found and updated.
    @discardableResult
    func update(_ wallet: Wallet) -> Bool {
        guard let storedWallet = wallets.first(where: { $0.id == wallet.id }) else { return false }
        storedWallet.name = wallet.name
        storedWallet.imageName = wallet.imageName
        storedWallet.colorHex = wallet.colorHex
        storedWallet.isIncomming = wallet.isIncomming
        save()
        return true
    }

    func remove(_ wallet: Wallet) {
        remove(id: wallet.id)
    }

    func remove(id: Wallet.ID) {
        guard let wallet = wallets.first(where: { $0.id == id }) else { return }
        wallets.removeAll { $0.id == id }
        modelContext.delete(wallet)
        save()
    }

    func remove(at index: Int) {
        guard wallets.indices.contains(index) else { return }
        remove(id: wallets[index].id)
    }

    func remove(atOffsets offsets: IndexSet) {
        let removedWallets = offsets.compactMap { wallets.indices.contains($0) ? wallets[$0] : nil }
        for wallet in removedWallets {
            remove(wallet)
        }
    }

    func removeAll() {
        for wallet in wallets {
            modelContext.delete(wallet)
        }
        wallets.removeAll()
        save()
    }

    private func insert(_ wallet: Wallet) -> Bool {
        guard !wallets.contains(where: { $0.id == wallet.id }) else { return false }
        wallets.append(wallet)
        modelContext.insert(wallet)
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