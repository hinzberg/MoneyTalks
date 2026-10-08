//
//  WalletRepositoryTests.swift
//  MoneyTalksTests
//
//  Created by Holger Hinzberg on 08.10.26.
//

import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import MoneyTalks

@MainActor
struct WalletRepositoryTests {

    private let container: ModelContainer
    private let repository: WalletRepository

    init() throws {
        container = try ModelContainer(
            for: Wallet.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        repository = WalletRepository(modelContext: container.mainContext)
    }

    // MARK: - Adding

    @Test func addStoresWalletAndSaves() throws {
        let wallet = makeWallet(name: "Girokonto")

        #expect(repository.add(wallet))
        #expect(repository.wallets.count == 1)
        #expect(repository.wallets.first?.id == wallet.id)
        #expect(repository.wallets.first?.name == "Girokonto")
        #expect(repository.lastSaveErrorMessage == nil)
        #expect(container.mainContext.hasChanges == false)
    }

    @Test func addSkipsWalletWithDuplicateID() throws {
        let id = UUID()

        #expect(repository.add(makeWallet(id: id, name: "Girokonto")))
        #expect(!repository.add(makeWallet(id: id, name: "Andere Bank")))

        #expect(repository.wallets.count == 1)
        #expect(repository.wallets.first?.name == "Girokonto")
    }

    @Test func addContentsOfSkipsDuplicatesWithinBatchAndExistingWallets() throws {
        let existing = makeWallet(name: "Girokonto")
        repository.add(existing)

        let duplicateID = UUID()
        let batch = [
            makeWallet(id: duplicateID, name: "Tagesgeld"),
            makeWallet(id: duplicateID, name: "Doppelt"),
            existing
        ]

        #expect(repository.add(contentsOf: batch) == 1)
        #expect(repository.wallets.count == 2)
        #expect(repository.wallets.contains { $0.name == "Tagesgeld" })
        #expect(!repository.wallets.contains { $0.name == "Doppelt" })
    }

    // MARK: - Updating

    @Test func updateCopiesAllValuesOntoStoredWallet() throws {
        let original = makeWallet(name: "Girokonto", imageName: "banknote.fill", isIncomming: true, color: .blue)
        repository.add(original)

        let draft = makeWallet(id: original.id, name: "Kreditkarte", imageName: "creditcard.fill", isIncomming: false, color: .red)

        #expect(repository.update(draft))

        let stored = repository.wallets.first { $0.id == original.id }
        #expect(stored?.name == "Kreditkarte")
        #expect(stored?.imageName == "creditcard.fill")
        #expect(stored?.isIncomming == false)
        #expect(stored?.colorHex == draft.colorHex)
    }

    @Test func updateReturnsFalseForUnknownID() throws {
        #expect(!repository.update(makeWallet(id: UUID(), name: "Unbekannt")))
        #expect(repository.wallets.isEmpty)
    }

    // MARK: - Removing

    @Test func removeDeletesWallet() throws {
        let wallet = makeWallet(name: "Girokonto")
        repository.add(wallet)

        repository.remove(wallet)

        #expect(repository.wallets.isEmpty)
        #expect(container.mainContext.hasChanges == false)
    }

    @Test func removeByIDDeletesOnlyMatchingWallet() throws {
        let first = makeWallet(name: "Girokonto")
        let second = makeWallet(name: "Kreditkarte")
        repository.add(contentsOf: [first, second])

        repository.remove(id: first.id)

        #expect(repository.wallets.map(\.name) == ["Kreditkarte"])
    }

    @Test func removeByUnknownIDIsIgnored() throws {
        repository.add(makeWallet(name: "Girokonto"))

        repository.remove(id: UUID())

        #expect(repository.wallets.count == 1)
    }

    @Test func removeAtIndexRemovesMatchingWallet() throws {
        repository.add(makeWallet(name: "Girokonto"))
        repository.add(makeWallet(name: "Kreditkarte"))

        repository.remove(at: 0)

        #expect(repository.wallets.map(\.name) == ["Kreditkarte"])
    }

    @Test func removeAtIndexIgnoresOutOfBoundsIndex() throws {
        repository.add(makeWallet(name: "Girokonto"))

        repository.remove(at: 5)

        #expect(repository.wallets.count == 1)
    }

    @Test func removeAtOffsetsRemovesOnlyGivenWallets() throws {
        repository.add(makeWallet(name: "Alpha"))
        repository.add(makeWallet(name: "Beta"))
        repository.add(makeWallet(name: "Gamma"))

        repository.remove(atOffsets: IndexSet([0, 2]))

        #expect(repository.wallets.map(\.name) == ["Beta"])
    }

    @Test func removeAtOffsetsIgnoresOutOfBoundsOffsets() throws {
        repository.add(makeWallet(name: "Alpha"))
        repository.add(makeWallet(name: "Beta"))

        repository.remove(atOffsets: IndexSet([0, 9]))

        #expect(repository.wallets.map(\.name) == ["Beta"])
    }

    @Test func removeAllEmptiesRepository() throws {
        repository.add(makeWallet(name: "Alpha"))
        repository.add(makeWallet(name: "Beta"))

        repository.removeAll()

        #expect(repository.wallets.isEmpty)
    }

    // MARK: - Fetching

    @Test func newRepositoryFetchesWalletsSortedByName() throws {
        container.mainContext.insert(makeWallet(name: "Zebra"))
        container.mainContext.insert(makeWallet(name: "Alpha"))
        try container.mainContext.save()

        let fresh = WalletRepository(modelContext: container.mainContext)

        #expect(fresh.wallets.map(\.name) == ["Alpha", "Zebra"])
    }

    @Test func addPersistsStoredWalletsToContext() throws {
        repository.add(makeWallet(name: "Alpha"))
        repository.add(makeWallet(name: "Beta"))

        let stored = try container.mainContext.fetch(FetchDescriptor<Wallet>())
        #expect(stored.map(\.name) == ["Alpha", "Beta"])
    }

    // MARK: - Helpers

    private func makeWallet(
        id: UUID = UUID(),
        name: String,
        imageName: String = "banknote.fill",
        isIncomming: Bool = true,
        color: Color = .blue
    ) -> Wallet {
        Wallet(id: id, name: name, imageName: imageName, isIncomming: isIncomming, color: color)
    }
}
